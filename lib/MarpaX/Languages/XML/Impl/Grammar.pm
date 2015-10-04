use Moops;

# PODCLASSNAME

# ABSTRACT: Grammar implementation

class MarpaX::Languages::XML::Impl::Grammar {
  use Marpa::R2;
  use MarpaX::Languages::XML::Impl::Grammar::Data;
  use MarpaX::Languages::XML::Impl::Entity;
  use MarpaX::Languages::XML::Role::Grammar;
  use MarpaX::Languages::XML::Type::CompiledGrammar -all;
  use MarpaX::Languages::XML::Type::LexemesMinlength -all;
  use MarpaX::Languages::XML::Type::LexemesRegexp -all;
  use MarpaX::Languages::XML::Type::LexemesExclusionsRegexp -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MooX::HandlesVia;
  use MooX::Role::Logger;
  use Types::Common::Numeric -all;

  has compiledGrammar         => ( is => 'ro', isa => InstanceOf['Marpa::R2::Scanless::G'], lazy => 1, builder => 1 );
  has lexemesRegexp           => ( is => 'ro', isa => LexemesRegexp,                        lazy => 1, builder => 1,
                                   handles_via => 'Hash',
                                   handles => {
                                               exists_lexemesRegexp => 'exists',
                                               get_lexemesRegexp => 'get'
                                              }
                                 );
  has lexemesMinlength        => ( is => 'ro', isa => LexemesMinlength,                        lazy => 1, builder => 1,
                                   handles_via => 'Hash',
                                   handles => {
                                               exists_lexemesMinlength => 'exists',
                                               get_lexemesMinlength => 'get'
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
  has events                  => ( is => 'ro', isa => HashRef[HashRef[Str]],                required => 1,
                                   handles_via => 'Hash',
                                   handles => {
                                               keys_events => 'keys',
                                               get_events => 'get'
                                              }
                                 );

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
  has lexemesMinlengthBySymbolId => (
                                     is  => 'ro',
                                     isa => ArrayRef[PositiveInt|Undef],
                                     lazy  => 1,
                                     builder => 1,
                                     handles_via => 'Array',
                                     handles => {
                                                 elements_lexemesMinlengthBySymbolId  => 'elements'
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
     _S_START                       => qr{\G[\x{20}\x{9}\x{D}\x{A}\x{85}\x{2028}]++}p,                 # Because XML version is considered unknown at this stage
     _PUBIDCHARDQUOTEMANY           => qr{\G[a-zA-Z0-9\-'()+,./:=?;!*#@\$_%\x{20}\x{D}\x{A}]++}p,
     _PUBIDCHARSQUOTEMANY           => qr{\G[a-zA-Z0-9\-()+,./:=?;!*#@\$_%\x{20}\x{D}\x{A}]++}p,
     #
     # An NCNAME is a NAME minus the ':'
     #
     _NCNAME                        => qr{\G[A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}][A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{2FF}\x{370}-\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}\-.0-9\x{B7}\x{0300}-\x{036F}\x{203F}-\x{2040}]*+}p,
     #
     # These are the lexemes of predicted size
     #
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
     _ROOT_ELEMENT_START            => qr{\G<}p,
     _ELEMENT_START                 => qr{\G<}p,
     _ROOT_ELEMENT_END              => qr{\G>}p,
     _ELEMENT_END                   => qr{\G>}p,
     _ROOT_ETAG_START               => qr{\G</}p,
     _ROOT_ETAG_END                 => qr{\G>}p,
     _ETAG_START                    => qr{\G</}p,
     _ETAG_END                      => qr{\G>}p,
     _ROOT_EMPTYELEM_END            => qr{\G/>}p,
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

  our %LEXEMES_MINLENGTH_COMMON =
    (
     #
     # These are the lexemes of unknown size
     #
     _NAME                          => 1,
     _NMTOKENMANY                   => 1,
     _ENTITYVALUEINTERIORDQUOTEUNIT => 1,
     _ENTITYVALUEINTERIORSQUOTEUNIT => 1,
     _ATTVALUEINTERIORDQUOTEUNIT    => 1,
     _ATTVALUEINTERIORSQUOTEUNIT    => 1,
     _NOT_DQUOTEMANY                => 1,
     _NOT_SQUOTEMANY                => 1,
     _CHARDATAMANY                  => 1,
     _COMMENTCHARMANY               => 1,
     _PITARGET                      => 1,
     _CDATAMANY                     => 1,
     _PICHARDATAMANY                => 1,
     _IGNOREMANY                    => 1,
     _DIGITMANY                     => 1,
     _ALPHAMANY                     => 1,
     _ENCNAME                       => 1,
     _S                             => 1,
     _S_START                       => 1,
     _PUBIDCHARDQUOTEMANY           => 1,
     _PUBIDCHARSQUOTEMANY           => 1,
     #
     # An NCNAME is a NAME minus the ':'
     #
     _NCNAME                        => 1,
     #
     # These are the lexemes of predicted size
     #
     _SPACE                         => length("\x{20}"),
     _DQUOTE                        => length('"'),
     _SQUOTE                        => length("'"),
     _COMMENT_START                 => length("<!--"),
     _COMMENT_END                   => length("-->"),
     _PI_START                      => length("<?"),
     _PI_END                        => length("?>"),
     _CDATA_START                   => length("<![CDATA["),
     _CDATA_END                     => length("]]>"),
     _XMLDECL_START                 => length("<?xml"),
     _XMLDECL_END                   => length("?>"),
     _VERSION                       => length("version"),
     _EQUAL                         => length("="),
     _VERSIONNUM                    => 3, # "1.0" or "1.1"
     _DOCTYPE_START                 => length("<!DOCTYPE"),
     _DOCTYPE_END                   => length(">"),
     _LBRACKET                      => length("["),
     _RBRACKET                      => length("]"),
     _STANDALONE                    => length("standalone"),
     _YES                           => length("yes"),
     _NO                            => length("no"),
     _ROOT_ELEMENT_START            => length("<"),
     _ELEMENT_START                 => length("<"),
     _ROOT_ELEMENT_END              => length(">"),
     _ELEMENT_END                   => length(">"),
     _ROOT_ETAG_START               => length("</"),
     _ETAG_START                    => length("</"),
     _ROOT_ETAG_END                 => length(">"),
     _ETAG_END                      => length(">"),
     _ROOT_EMPTYELEM_END            => length("/>"),
     _EMPTYELEM_END                 => length("/>"),
     _ELEMENTDECL_START             => length("<!ELEMENT"),
     _ELEMENTDECL_END               => length(">"),
     _EMPTY                         => length("EMPTY"),
     _ANY                           => length("ANY"),
     _QUESTIONMARK                  => length("?"),
     _STAR                          => length("*"),
     _PLUS                          => length("+"),
     _OR                            => length("|"),
     _CHOICE_START                  => length("("),
     _CHOICE_END                    => length(")"),
     _SEQ_START                     => length("("),
     _SEQ_END                       => length(")"),
     _MIXED_START                   => length("("),
     _MIXED_END1                    => length(")*"),
     _MIXED_END2                    => length(")"),
     _COMMA                         => length(","),
     _PCDATA                        => length("#PCDATA"),
     _ATTLIST_START                 => length("<!ATTLIST"),
     _ATTLIST_END                   => length(">"),
     _CDATA                         => length("CDATA"),
     _ID                            => length("ID"),
     _IDREF                         => length("IDREF"),
     _IDREFS                        => length("IDREFS"),
     _ENTITY                        => length("ENTITY"),
     _ENTITIES                      => length("ENTITIES"),
     _NMTOKEN                       => length("NMTOKEN"),
     _NMTOKENS                      => length("NMTOKENS"),
     _NOTATION                      => length("NOTATION"),
     _NOTATION_START                => length("("),
     _NOTATION_END                  => length(")"),
     _ENUMERATION_START             => length("("),
     _ENUMERATION_END               => length(")"),
     _REQUIRED                      => length("#REQUIRED"),
     _IMPLIED                       => length("#IMPLIED"),
     _FIXED                         => length("#FIXED"),
     _INCLUDE                       => length("INCLUDE"),
     _IGNORE                        => length("IGNORE"),
     _INCLUDESECT_START             => length("<!["),
     _INCLUDESECT_END               => length("]]>"),
     _IGNORESECT_START              => length("<!["),
     _IGNORESECT_END                => length("]]>"),
     _IGNORESECTCONTENTSUNIT_START  => length("<!["),
     _IGNORESECTCONTENTSUNIT_END    => length("]]>"),
     _CHARREF_START1                => length("&#"),
     _CHARREF_END1                  => length(";"),
     _CHARREF_START2                => length("&#x"),
     _CHARREF_END2                  => length(";"),
     _ENTITYREF_START               => length("&"),
     _ENTITYREF_END                 => length(";"),
     _PEREFERENCE_START             => length("%"),
     _PEREFERENCE_END               => length(";"),
     _ENTITY_START                  => length("<!ENTITY"),
     _ENTITY_END                    => length(">"),
     _PERCENT                       => length("%"),
     _SYSTEM                        => length("SYSTEM"),
     _PUBLIC                        => length("PUBLIC"),
     _NDATA                         => length("NDATA"),
     _TEXTDECL_START                => length("<?xml"),
     _TEXTDECL_END                  => length("?>"),
     _ENCODING                      => length("encoding"),
     _NOTATIONDECL_START            => length("<!NOTATION"),
     _NOTATIONDECL_END              => length(">"),
     _COLON                         => length(":"),
     _XMLNSCOLON                    => length("xmlns:"),
     _XMLNS                         => length("xmlns"),
    );

  our %LEXEMESEXCLUSIONS_REGEXP_COMMON =
    (
     _PITARGET => qr{^xml$}i,
    );

  #
  # Per-xmlVersion overwrites
  #
  our %LEXEMES_REGEXP_SPECIFIC =
    (
     '1.0' => {
              },
     '1.1' => {
               _S                   => qr{\G[\x{20}\x{9}\x{D}\x{A}\x{85}\x{2028}]++}p,
              }
    );

  our %LEXEMES_MINLENGTH_SPECIFIC =
    (
     '1.0' => {
              },
     '1.1' => {
              }
    );

  our %LEXEMESEXCLUSIONS_REGEXP_SPECIFIC =
    (
     '1.0' => {
              },
     '1.1' => {
              }
    );

  method _build_compiledGrammar {
    my $bnf = $self->_bnf;
    $self->_logger->tracef('Compiling BNF for XML %s (namespace support: %s, start symbol: %s)', $self->xmlVersion, $self->xmlns ? 'yes' : 'no', $self->startSymbol);
    return Marpa::R2::Scanless::G->new({source => \$bnf});
  }

  method _build__bnf {
    $self->_logger->tracef('Producing BNF for XML %s (namespace support: %s, start symbol: %s)', $self->xmlVersion, $self->xmlns ? 'yes' : 'no', $self->startSymbol);
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
    #
    # Add events
    #
    foreach ($self->keys_events) {
      my $type = $_;
      my $hashRef = $self->get_events($_);
      foreach (keys %{$hashRef}) {
        my $eventName = $_;
        my $rule = $hashRef->{$eventName};
        my $string = "event '$eventName' = $type <$rule>";
        $self->_logger->tracef('Adding %s', $string);
        $dataSectionXml .= "$string\n";
      }
    }

    return $dataSectionXml;
  }

  method _build_lexemesRegexp {
    #
    # Return the common things (which are the XML1.0 regexps)
    # overloaded by the the XML1.1 changes
    #
    my %hash = (%LEXEMES_REGEXP_COMMON, %{$LEXEMES_REGEXP_SPECIFIC{$self->xmlVersion}});
    return \%hash;
  }

  method _build_lexemesMinlength {
    #
    # Return the common things (which are the XML1.0 regexps)
    # overloaded by the the XML1.1 changes
    #
    my %hash = (%LEXEMES_MINLENGTH_COMMON, %{$LEXEMES_MINLENGTH_SPECIFIC{$self->xmlVersion}});
    return \%hash;
  }

  method _build_lexemesExclusionsRegexp {
    #
    # Return the common things (which are the XML1.0 regexps)
    # overloaded by the the XML1.1 changes
    #
    my %hash = (%LEXEMESEXCLUSIONS_REGEXP_COMMON, %{$LEXEMESEXCLUSIONS_REGEXP_SPECIFIC{$self->xmlVersion}});
    return \%hash;
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

  method _build_lexemesMinlengthBySymbolId {
    my $symbol_by_name_hash = $self->compiledGrammar->symbol_by_name_hash;
    #
    # Build the regexp list as an array using symbol ids as indice
    #
    my @array = ();
    foreach (keys %{$symbol_by_name_hash}) {
      if ($self->exists_lexemesMinlength($_)) {
        $array[$symbol_by_name_hash->{$_}] = $self->get_lexemesMinlength($_);
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
