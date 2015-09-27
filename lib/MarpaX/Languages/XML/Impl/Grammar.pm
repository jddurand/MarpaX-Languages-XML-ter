use Moops;

# PODCLASSNAME

# ABSTRACT: Grammar implementation

class MarpaX::Languages::XML::Impl::Grammar {
  use Marpa::R2;
  use MarpaX::Languages::XML::Impl::Grammar::Data;
  use MarpaX::Languages::XML::Role::Grammar;
  use MarpaX::Languages::XML::Type::CompiledGrammar -all;
  use MarpaX::Languages::XML::Type::LexemesRegexp -all;
  use MarpaX::Languages::XML::Type::LexemesExclusionsRegexp -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MooX::HandlesVia;
  use MooX::Role::Logger;

  has compiledGrammar         => ( is => 'ro', isa => InstanceOf['Marpa::R2::Scanless::G'], lazy => 1, builder => 1 );
  has lexemesRegexp           => ( is => 'ro', isa => LexemesRegexp,                        lazy => 1, builder => 1,
                                   handles_via => 'Hash',
                                   handles => {
                                               exists_lexemesRegexp => 'exists',
                                               get_lexemesRegexp => 'get'
                                              }
                                 );
  has lexemesExclusionsRegexp => ( is => 'ro', isa => LexemesExclusionsRegexp,              lazy => 1, builder => 1,
                                   handles_via => 'Hash',
                                   handles => {
                                               exists_lexemesExclusionsRegexp => 'exists',
                                               get_lexemesExclusionsRegexp => 'get'
                                              }
                                 );
  has xmlVersion              => ( is => 'ro', isa => XmlVersion,                           required => 1 );
  has xmlns                   => ( is => 'ro', isa => Bool,                                 required => 1 );
  has startSymbol             => ( is => 'ro', isa => Str,                                  required => 1 );

  has _bnf                    => ( is => 'rw', isa => Str,                                  lazy => 1, builder => 1 );
  has lexemesRegexpBySymbolId => (
                                  is  => 'ro',
                                  isa => ArrayRef[RegexpRef|Undef],
                                  lazy  => 1,
                                  builder => 1,
                                  handles_via => 'Array',
                                  handles => {
                                              elements_lexemesRegexpBySymbolId  => 'elements'
                                             }
                                 );

has lexemesExclusionsRegexpBySymbolId => (
                                          is  => 'ro',
                                          isa => ArrayRef[RegexpRef|Undef],
                                          lazy  => 1,
                                          builder => 1,
                                          handles_via => 'Array',
                                          handles => {
                                                      elements_lexemesExclusionsRegexpBySymbolId  => 'elements'
                                                     }
                                         );

  our $PACKAGE_DATA = 'MarpaX::Languages::XML::Impl::Grammar::Data';

  # Regexps:
  # -------
  # The *+ is important: it means match zero or more times and give nothing back
  # The ++ is important: it means match one  or more times and give nothing back
  #
  our %LEXEMES_REGEXP_COMMON =
    (
     #
     # These are the lexemes of unknown size
     #
     _NAME                          => qr{\G[:A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}][:A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}\-.0-9\x{B7}\x{0300}-\x{036F}\x{203F}-\x{2040}]*+}p,
     _NMTOKENMANY                   => qr{\G[:A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}\-.0-9\x{B7}\x{0300}-\x{036F}\x{203F}-\x{2040}]++}p,
     _ENTITYVALUEINTERIORDQUOTEUNIT => qr{\G[^%&"]++}p,
     _ENTITYVALUEINTERIORSQUOTEUNIT => qr{\G[^%&']++}p,
     _ATTVALUEINTERIORDQUOTEUNIT    => qr{\G[^<&"]++}p,
     _ATTVALUEINTERIORSQUOTEUNIT    => qr{\G[^<&']++}p,
     _NOT_DQUOTEMANY                => qr{\G[^"]++}p,
     _NOT_SQUOTEMANY                => qr{\G[^']++}p,
     _CHARDATAMANY                  => qr{\G(?:[^<&\]]|(?:\](?!\]>)))++}p, # [^<&]+ without ']]>'
     _COMMENTCHARMANY               => qr{\G(?:[\x{9}\x{A}\x{D}\x{20}-\x{2C}\x{2E}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]|(?:\-(?!\-)))++}p,  # Char* without '--'
     _PITARGET                      => qr{\G[:A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}][:A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}\-.0-9\x{B7}\x{0300}-\x{036F}\x{203F}-\x{2040}]*+}p,  # NAME but /xml/i - c.f. exclusion hash
     _CDATAMANY                     => qr{\G(?:[\x{9}\x{A}\x{D}\x{20}-\x{5C}\x{5E}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]|(?:\](?!\]>)))++}p,  # Char* minus ']]>'
     _PICHARDATAMANY                => qr{\G(?:[\x{9}\x{A}\x{D}\x{20}-\x{3E}\x{40}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]|(?:\?(?!>)))++}p,  # Char* minus '?>'
     _IGNOREMANY                    => qr{\G(?:[\x{9}\x{A}\x{D}\x{20}-\x{3B}\x{3D}-\x{5C}\x{5E}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]|(?:<(?!!\[))|(?:\](?!\]>)))++}p,  # Char minus* ('<![' or ']]>')
     _DIGITMANY                     => qr{\G[0-9]++}p,
     _ALPHAMANY                     => qr{\G[0-9a-fA-F]++}p,
     _ENCNAME                       => qr{\G[A-Za-z][A-Za-z0-9._\-]*+}p,
     _S                             => qr{\G[\x{20}\x{9}\x{D}\x{A}]++}p,
     #
     # An NCNAME is a NAME minus the ':'
     #
     _NCNAME                        => qr{\G[A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}][A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}\-.0-9\x{B7}\x{0300}-\x{036F}\x{203F}-\x{2040}]*+}p,
     #
     # These are the lexemes of predicted size
     #
     _PUBIDCHARDQUOTEMANY           => qr{\G[a-zA-Z0-9\-'()+,./:=?;!*#@\$_%\x{20}\x{D}\x{A}]++}p,
     _PUBIDCHARSQUOTEMANY           => qr{\G[a-zA-Z0-9\-()+,./:=?;!*#@\$_%\x{20}\x{D}\x{A}]++}p,
     _SPACE                         => qr{\G\x{20}}p,
     _DQUOTE                        => qr{\G"}p,
     _SQUOTE                        => qr{\G'}p,
     _COMMENT_START                 => qr{\G<!\-\-}p,
     _COMMENT_END                   => qr{\G\-\->}p,
     _PI_START                      => qr{\G<\?}p,
     _PI_END                        => qr{\G\?>}p,
     _CDATA_START                   => qr{\G<!\[CDATA\[}p,
     _CDATA_END                     => qr{\G\]\]>}p,
     _XMLDECL_START                 => qr{\G<\?xml}p,
     _XMLDECL_END                   => qr{\G\?>}p,
     _VERSION                       => qr{\Gversion}p,
     _EQUAL                         => qr{\G=}p,
     _VERSIONNUM                    => qr{\G1\.[01]}p,            # We want to catch all possible versions so that we can retry the parser
     _DOCTYPE_START                 => qr{\G<!DOCTYPE}p,
     _DOCTYPE_END                   => qr{\G>}p,
     _LBRACKET                      => qr{\G\[}p,
     _RBRACKET                      => qr{\G\]}p,
     _STANDALONE                    => qr{\Gstandalone}p,
     _YES                           => qr{\Gyes}p,
     _NO                            => qr{\Gno}p,
     _ELEMENT_START                 => qr{\G<}p,
     _ELEMENT_END                   => qr{\G>}p,
     _ETAG_START                    => qr{\G</}p,
     _ETAG_END                      => qr{\G>}p,
     _EMPTYELEM_END                 => qr{\G/>}p,
     _ELEMENTDECL_START             => qr{\G<!ELEMENT}p,
     _ELEMENTDECL_END               => qr{\G>}p,
     _EMPTY                         => qr{\GEMPTY}p,
     _ANY                           => qr{\GANY}p,
     _QUESTIONMARK                  => qr{\G\?}p,
     _STAR                          => qr{\G\*}p,
     _PLUS                          => qr{\G\+}p,
     _OR                            => qr{\G\|}p,
     _CHOICE_START                  => qr{\G\(}p,
     _CHOICE_END                    => qr{\G\)}p,
     _SEQ_START                     => qr{\G\(}p,
     _SEQ_END                       => qr{\G\)}p,
     _MIXED_START                   => qr{\G\(}p,
     _MIXED_END1                    => qr{\G\)\*}p,
     _MIXED_END2                    => qr{\G\)}p,
     _COMMA                         => qr{\G,}p,
     _PCDATA                        => qr{\G#PCDATA}p,
     _ATTLIST_START                 => qr{\G<!ATTLIST}p,
     _ATTLIST_END                   => qr{\G>}p,
     _CDATA                         => qr{\GCDATA}p,
     _ID                            => qr{\GID}p,
     _IDREF                         => qr{\GIDREF}p,
     _IDREFS                        => qr{\GIDREFS}p,
     _ENTITY                        => qr{\GENTITY}p,
     _ENTITIES                      => qr{\GENTITIES}p,
     _NMTOKEN                       => qr{\GNMTOKEN}p,
     _NMTOKENS                      => qr{\GNMTOKENS}p,
     _NOTATION                      => qr{\GNOTATION}p,
     _NOTATION_START                => qr{\G\(}p,
     _NOTATION_END                  => qr{\G\)}p,
     _ENUMERATION_START             => qr{\G\(}p,
     _ENUMERATION_END               => qr{\G\)}p,
     _REQUIRED                      => qr{\G#REQUIRED}p,
     _IMPLIED                       => qr{\G#IMPLIED}p,
     _FIXED                         => qr{\G#FIXED}p,
     _INCLUDE                       => qr{\GINCLUDE}p,
     _IGNORE                        => qr{\GIGNORE}p,
     _INCLUDESECT_START             => qr{\G<!\[}p,
     _INCLUDESECT_END               => qr{\G\]\]>}p,
     _IGNORESECT_START              => qr{\G<!\[}p,
     _IGNORESECT_END                => qr{\G\]\]>}p,
     _IGNORESECTCONTENTSUNIT_START  => qr{\G<!\[}p,
     _IGNORESECTCONTENTSUNIT_END    => qr{\G\]\]>}p,
     _CHARREF_START1                => qr{\G&#}p,
     _CHARREF_END1                  => qr{\G;}p,
     _CHARREF_START2                => qr{\G&#x}p,
     _CHARREF_END2                  => qr{\G;}p,
     _ENTITYREF_START               => qr{\G&}p,
     _ENTITYREF_END                 => qr{\G;}p,
     _PEREFERENCE_START             => qr{\G%}p,
     _PEREFERENCE_END               => qr{\G;}p,
     _ENTITY_START                  => qr{\G<!ENTITY}p,
     _ENTITY_END                    => qr{\G>}p,
     _PERCENT                       => qr{\G%}p,
     _SYSTEM                        => qr{\GSYSTEM}p,
     _PUBLIC                        => qr{\GPUBLIC}p,
     _NDATA                         => qr{\GNDATA}p,
     _TEXTDECL_START                => qr{\G<\?xml}p,
     _TEXTDECL_END                  => qr{\G\?>}p,
     _ENCODING                      => qr{\Gencoding}p,
     _NOTATIONDECL_START            => qr{\G<!NOTATION}p,
     _NOTATIONDECL_END              => qr{\G>}p,
     _COLON                         => qr{\G:}p,
     _XMLNSCOLON                    => qr{\Gxmlns:}p,
     _XMLNS                         => qr{\Gxmlns}p,
    );

  our %LEXEMESEXCLUSIONS_REGEXP_COMMON =
    (
     _PITARGET => qr{^xml$}i,
    );

  method _build_compiledGrammar {
    $self->_logger->tracef('Compiling BNF for XML %s (namespace support: %s, start symbol: %s)', $self->xmlVersion, $self->xmlns ? 'yes' : 'no', $self->startSymbol);
    return Marpa::R2::Scanless::G->new({source => \$self->_bnf});
  }

  method _build__bnf {
    my $dataSectionXmlName = $self->xmlVersion;
    $dataSectionXmlName =~ s/\.//;
    $dataSectionXmlName = 'xml' . $dataSectionXmlName;          # i.e. xml10 or xml11

    my $dataSectionXml = ${$PACKAGE_DATA->sectionData($dataSectionXmlName)};
    #
    # Apply start symbol
    #
    my $startSymbol = $self->startSymbol;
    $dataSectionXml =~ s/\$START/$startSymbol/sxmg;
    #
    # Apply namespace changes if any
    #
    if ($self->xmlns) {
      my $dataSectionXmlnsName = $self->xmlVersion;
      $dataSectionXmlnsName =~ s/\.//;
      $dataSectionXmlnsName = 'xmlns' . $dataSectionXmlnsName;          # i.e. xmlns10 or xmlns11

      my $dataSectionXmlnsAdd          = ${$PACKAGE_DATA->sectionData($dataSectionXmlnsName . ':add')};
      my $dataSectionXmlnsReplaceOrAdd = ${$PACKAGE_DATA->sectionData($dataSectionXmlnsName . ':replace_or_add')};
      #
      # Every rule in the replace_or_add is first removed from original bnf
      #
      my @rules_to_remove = ();
      while ($dataSectionXmlnsReplaceOrAdd =~ m/^\w+/mgp) {
        push(@rules_to_remove, ${^MATCH});
      }
      foreach (@rules_to_remove) {
        $dataSectionXml =~ s/^$_\s*::=.*$//mg;
      }
      #
      # Add everything
      #
      $dataSectionXml .= $dataSectionXmlnsAdd;
      $dataSectionXml .= $dataSectionXmlnsReplaceOrAdd;
    }

    return $dataSectionXml;
  }

  method _build_lexemesRegexp {
    #
    # Return the common things (which are the XML1.0 regexps)
    # overloaded by the the XML1.1 changes
    #
    return \%LEXEMES_REGEXP_COMMON;
  }

  method _build_lexemesExclusionsRegexp {
    #
    # Return the common things (which are the XML1.0 regexps)
    # overloaded by the the XML1.1 changes
    #
    return \%LEXEMESEXCLUSIONS_REGEXP_COMMON;
  }

  method _build_lexemesRegexpBySymbolId {
    my $symbol_by_name_hash = $self->compiledGrammar->symbol_by_name_hash;
    #
    # Build the regexp list as an array using symbol ids as indice
    #
    my @array = ();
    foreach (keys %{$symbol_by_name_hash}) {
      if ($self->exists_lexemesRegexp($_)) {
        $array[$symbol_by_name_hash->{$_}] = $self->get_lexemesRegexp($_);
      }
    }
    return \@array;
  }

  method _build_lexemesExclusionsRegexpBySymbolId {
    my $symbol_by_name_hash = $self->compiledGrammar->symbol_by_name_hash;
    #
    # Build the string list as an array using symbol ids as indice
    #
    my @array = ();
    foreach (keys %{$symbol_by_name_hash}) {
      if ($self->exists_lexemesExclusionsRegexp($_)) {
        $array[$symbol_by_name_hash->{$_}] = $self->get_lexemesExclusionsRegexp($_);
      }
    }
    return \@array;
  }

with 'MarpaX::Languages::XML::Role::Grammar';
  with 'MooX::Role::Logger';
}

1;
