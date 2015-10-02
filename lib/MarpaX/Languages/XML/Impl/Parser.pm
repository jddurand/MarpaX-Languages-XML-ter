use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
  use List::Util qw/max/;
  use Marpa::R2;
  use MarpaX::Languages::XML::Impl::Context;
  use MarpaX::Languages::XML::Impl::Dispatcher;
  use MarpaX::Languages::XML::Impl::Grammar;
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
  use MarpaX::Languages::XML::Impl::IO;
  use MarpaX::Languages::XML::Impl::PluginFactory;
  use MarpaX::Languages::XML::Role::Parser;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::NamespaceSupport -all;
  use MarpaX::Languages::XML::Type::IO -all;
  use MarpaX::Languages::XML::Type::LastLexemes -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MarpaX::Languages::XML::Type::SaxHandler -all;
  use MarpaX::Languages::XML::Type::StartSymbol -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MooX::ClassAttribute;
  use MooX::HandlesVia;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;
  use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;

  use Throwable::Factory
    ParseException    => undef
    ;
  use Types::Common::Numeric -all;

  # VERSION

  # AUTHORITY

  has xmlVersion      => ( is => 'rw',  isa => XmlVersion,        required => 1, trigger => 1 );
  has xmlns           => ( is => 'ro',  isa => Bool,              required => 1 );
  has vc              => ( is => 'ro',  isa => ArrayRef[Str],     required => 1, handles_via => 'Array', handles => { elements_vc => 'elements' } );
  has wfc             => ( is => 'ro',  isa => ArrayRef[Str],     required => 1, handles_via => 'Array', handles => { elements_wfc => 'elements' } );
  has blockSize       => ( is => 'ro',  isa => PositiveOrZeroInt, default => 1024 * 1024 );
  has rc              => ( is => 'rwp', isa => Int,               default => EXIT_SUCCESS );
  has unicode_newline => ( is => 'ro',  isa => Bool,              default => false, trigger => 1 );
  has startSymbol     => ( is => 'ro',  isa => StartSymbol,       default => 'document' );
  has lastLexemes      => ( is => 'rw',   isa => LastLexemes,       default => sub { return [] },
                            handles_via => 'Array',
                            handles => {
                                        get_lastLexeme => 'get',
                                        set_lastLexeme => 'set',
                                       }
                          );
  has inDecl          => ( is => 'rw',  isa => Bool,              default => true, trigger => 1 );
  has io              => ( is => 'rwp', isa => IO );
  has saxHandler      => ( is => 'ro',  isa => SaxHandler,        default => sub { {} },
                           handles_via => 'Hash',
                           handles => {
                                       get_saxHandle => 'get',
                                       exists_saxHandle => 'exists'
                                      }
                         );
  has line            => ( is => 'rwp',  isa => PositiveOrZeroInt, default => 1 );
  has column          => ( is => 'rwp',  isa => PositiveOrZeroInt, default => 1 );
  #
  # The very first read in _parse_generic() will use block_size.
  # Nevertheless is this is done with the wrong encoding, we do not want to be polluted
  # by perl saying he got an unmappable character.
  # We try to avoid that asa much possible with the following:
  # Any XML grammar is starting with, at most:
  # <?xml version="1.0" encoding="1234567890123456789012345678901234567890" standalone="yes" ?>
  # 12345678901234567890123456789012345678901234567890123456789012345678901234567890
  #          1         2         3         4         5         6         7
  #                                                                       ^
  #                                                                      HERE
  # We assume that the XML does use a IANA charset, as recommended by the spec. I.e. 40 characters max.
  # This mean that a well-writen XML will have encoding information, if any, at character No 71 max
  # (regardless of the encoding currently in use).
  #
  class_has _firstReadCharacterLength => ( is => 'ro', isa => PositiveInt, default => 71 );
  has _eof            => ( is => 'rw',  isa => Bool,              default => false, trigger => 1 );
  has _dispatcher     => ( is => 'rw',  isa => Dispatcher, lazy => 1, clearer => 1, builder => 1);
  has _contexts       => ( is => 'rw',  isa => ArrayRef[Context], default => sub { [] }, 
                           handles_via => 'Array', handles => {
                                                               count_contexts => 'count',
                                                               push_context   => 'push',
                                                               _pop_context   => 'pop',
                                                               _get_context   => 'get'
                                                              }
                         );

  has _unicode_newline_regexp => ( is => 'rw',  isa => RegexpRef,                          default => sub { return qr/\R/; }  );
  has _grammars               => ( is => 'rw',  isa => HashRef[Grammar],                   lazy => 1, builder => 1, clearer => 1, handles_via => 'Hash', handles => { get_grammar => 'get' } );
  has _grammars_events        => ( is => 'rw',  isa => HashRef[HashRef[HashRef[Str]]],     lazy => 1, builder => 1, clearer => 1, handles_via => 'Hash', handles => { _get_grammar_events => 'get' } );
  has _grammars_endEventName  => ( is => 'rw',  isa => HashRef[Str],                       lazy => 1, builder => 1, clearer => 1, handles_via => 'Hash', handles => { get_grammar_endEventName => 'get' } );
  has namespaceSupport        => ( is => 'rw',  isa => NamespaceSupport,                   lazy => 1, builder => 1, clearer => 1 );


  method _trigger_inDecl(Bool $inDecl) {
    $self->_logger->tracef('Setting inDecl boolean to %s', $inDecl ? 'true' : 'false');
  }

  method _trigger__eof(Bool $eof) {
    $self->_logger->tracef('Setting eof boolean to %s', $eof ? 'true' : 'false');
  }

  method _build__dispatcher( --> Dispatcher) {
    my $dispatcher    = MarpaX::Languages::XML::Impl::Dispatcher->new();
    #
    # Events are:
    # - WFC constraints (configurable)
    # - VC constraints (configurable)
    # - IO constraints (not configurable)
    # - other events (not configurable)
    #
    my $pluginFactory = MarpaX::Languages::XML::Impl::PluginFactory->new();
    $pluginFactory
      ->registerPlugins($self->xmlVersion, $self->xmlns, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::WFC',     $self->elements_wfc)
      ->registerPlugins($self->xmlVersion, $self->xmlns, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::VC',      $self->elements_vc)
      ->registerPlugins($self->xmlVersion, $self->xmlns, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::IO',      ':all')
      ->registerPlugins($self->xmlVersion, $self->xmlns, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::General', ':all')
      ;
    return $dispatcher;
  }

  method _trigger_xmlVersion(XmlVersion $xmlVersion --> Undef) {
    #
    # Make sure all the grammar stuff will be recreated
    # The sequence is:
    # my $context = MarpaX::Languages::XML::Impl::Context->new(
    #                                                          grammar          => $self->get_grammar($self->startSymbol),
    #                                                          endEventName     => $self->get_grammar_endEventName($self->startSymbol),
    #                                                         );
    # So we need to clear '_grammars', '_grammar_events', '_grammars_endEventName'
    #
    $self->_clear_grammars;
    $self->_clear_grammars_events;
    $self->_clear_grammars_endEventName;
    $self->_clear_dispatcher;
    $self->clear_namespaceSupport;
    $self->inDecl(true);
    return;
  }

  method _trigger_unicode_newline(Bool $unicode_newline --> Undef) {
    $self->_unicode_newline_regexp($unicode_newline ? qr/\R/ : qr/\n/);
  }

  method _build__grammars_events( --> HashRef[HashRef[HashRef[Str]]]) {
    return {
            document => {
                         completed => {
                                       ENCNAME_COMPLETED                           => 'ENCNAME',
                                       XMLDECL_END_COMPLETED                       => 'XMLDECL_END',
                                       VERSIONNUM_COMPLETED                        => 'VERSIONNUM',
                                       ELEMENT_START_COMPLETED                     => 'ELEMENT_START',  # Element push
                                       $self->get_grammar_endEventName('document') => 'document'
                                      }
                        },
            element => {
                        completed => {
                                      ELEMENT_START_COMPLETED                     => 'ELEMENT_START',  # Element push
                                      $self->get_grammar_endEventName('element')   => 'element' # Element pop
                                     }
                       }
           };
  }

  method _build__grammars_endEventName( --> HashRef[Str]) {
    return {
            document => 'document_COMPLETED',
            element  => 'element_COMPLETED'
           };
  }

  method _build__grammars( --> HashRef[Grammar]) {
    my %grammars = ();
    foreach (qw/document element/) {
      $grammars{$_} = MarpaX::Languages::XML::Impl::Grammar->new(
                                                                 xmlVersion  => $self->xmlVersion,
                                                                 xmlns       => $self->xmlns,
                                                                 startSymbol => $_,
                                                                 events      => $self->_get_grammar_events($_)
                                                                );
    }
    return \%grammars;
  }

  method _build__namespaceSupport( --> NamespaceSupport) {
    my %namespacesupport_options = (xmlns => $self->xmlns ? 1 : 0);
    $namespacesupport_options{xmlns_11} = ($self->xmlVersion eq '1.1' ? 1 : 0) if ($self->xmlns);

    return XML::NamespaceSupport->new(\%namespacesupport_options);
  }

  method _safeString(Str $string --> Str) {
    #
    # Replace any character that would not be a known ASCII printable one with its hexadecimal value a-la-XML
    #
    # http://stackoverflow.com/questions/9730054/how-can-i-dump-a-string-in-perl-to-see-if-there-are-any-character-differences
    #
    $string =~ s/([^\x20-\x7E])/sprintf("&#x%x;", ord($1))/ge;
    return $string;
  }

  method _doEstimatedBestFirstRead(Dispatcher $dispatcher, Context $context--> Parser) {
    my $needed = $self->_firstReadCharacterLength;
    my $io = $self->io;

    my $old_block_size_value = $io->block_size_value;
    if ($old_block_size_value != $needed) {
      $io->block_size($needed);
    }
    #
    # Per def $pos is 0 here
    #
    $self->read($dispatcher, $context);
    if ($old_block_size_value != $needed) {
      $io->block_size($old_block_size_value);
    }
  }

  method parse(Str $source --> Int) {
    #
    # Prepare I/O
    # We want to handle buffer direcly with no COW: the buffer scalar is localized.
    # And have the block size as per the argument
    #
    local $MarpaX::Languages::XML::Impl::Parser::buffer = '';
    $self->_set_io(MarpaX::Languages::XML::Impl::IO->new(source => $source));
    $self->io->buffer(\$MarpaX::Languages::XML::Impl::Parser::buffer);
    $self->io->block_size($self->blockSize);
    #
    # Push first context (I delibarately not use internal variables)
    #
    $self->push_context(MarpaX::Languages::XML::Impl::Context->new(
                                                                   grammar          => $self->get_grammar($self->startSymbol),
                                                                   endEventName     => $self->get_grammar_endEventName($self->startSymbol),
                                                                  )
                       );
    my $context = $self->_get_context(0);
    #
    # Do the first read to avoid as much as possible perl pollution about unmappable character
    #
    $self->_doEstimatedBestFirstRead($self->_dispatcher, $context);
    #
    # Note: having $context prevents the first first of them to be garbaged, re-used for end_document -;
    #
    # start_document and end_document are systematic, regardless of parsing failure or success
    #
    $self->_dispatcher->notify('start_document', $self, $context);
    try {
      #
      # Loop until there is no more context
      #
      do {
        #
        # It is important to to $self->_dispatcher here because a change of xmlVersion
        # may recreate it.
        #
        $self->_parse_generic($self->_dispatcher);
        #
        # The pop is done eventually inside _parse_generic()
        #
      } while ($self->count_contexts);
    } catch {
      $self->_logger->errorf($_);
      $self->rc(EXIT_FAILURE);
      return;
    };
    $self->_dispatcher->notify('end_document', $self, $context);
    #
    # Return code eventually under SAX handler control
    #
    return $self->rc;
  }

  method _reduce(Context $context --> Parser) {
    my $io     = $self->io;
    my $pos    = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $count = $self->count_contexts;
    my $new_length;

    if ($pos >= $length) {
      $MarpaX::Languages::XML::Impl::Parser::buffer = '';
      $new_length = 0;
      $self->_logger->tracef('[%d/%d]%s Buffer length reduced to %d', $count, $count, $context->grammar->startSymbol, $new_length);
    } elsif ($pos > 0) {
      substr($MarpaX::Languages::XML::Impl::Parser::buffer, 0, $pos, '');
      $new_length = $length - $pos;
      $self->_logger->tracef('[%d/%d]%s Buffer length reduced to %d', $count, $count, $context->grammar->startSymbol, $new_length);
    }

    return $self;
  }

  method read(Dispatcher $dispatcher, Context $context --> Parser) {

    $self->io->read;
    $dispatcher->process('EOL', $self, $context);

    return $self;
  }

  #
  # If _doEvents returns false, the caller will immediately return
  #
  method _doEvents(Dispatcher $dispatcher, Context $context, Str $startSymbol, Str $endEventName, Recognizer $recognizer, ScalarRef $canStopRef, ScalarRef $posRef, ScalarRef $lengthRef, ScalarRef $remainingRef --> Bool) {
    my $rc = true;
    my @event_names  = map { $_->[0] } @{$recognizer->events()};
    my $count = $self->count_contexts;
    $self->_logger->tracef('[%d/%d]%s Events  : %s', $count, $self->count_contexts, $startSymbol, $recognizer->events);
    foreach (@event_names) {
      #
      # Catch the end event name
      #
      ${$canStopRef} = true if ($_ eq $endEventName);
      #
      # Dispatch events
      #
      $dispatcher->notify($_, $self, $context);
      #
      # Immediate action ?
      #
      my $immediateAction = $context->immediateAction;
      if ($immediateAction) {
        if ($immediateAction & IMMEDIATEACTION_RETURN) {
          $self->_logger->tracef('[%d/%d]%s IMMEDIATEACTION_RETURN', $count, $self->count_contexts, $startSymbol);
          $rc = false;
          $context->immediateAction(IMMEDIATEACTION_NONE);
        }
        if ($immediateAction & IMMEDIATEACTION_POP_CONTEXT) {
          $self->_logger->tracef('[%d/%d]%s IMMEDIATEACTION_POP_CONTEXT', $count, $self->count_contexts, $startSymbol);
          $self->_pop_context;
          $context->immediateAction(IMMEDIATEACTION_NONE);
        }
        if ($immediateAction & IMMEDIATEACTION_REDUCE) {
          $self->_logger->tracef('[%d/%d]%s IMMEDIATEACTION_REDUCE', $count, $self->count_contexts, $startSymbol);
          $self->_reduce($context);
          $context->immediateAction(IMMEDIATEACTION_NONE);
          my $pos = ${$posRef} = pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;
          my $length = ${$lengthRef} = length($MarpaX::Languages::XML::Impl::Parser::buffer);
          ${$remainingRef} = $length - $pos;
        }
        #
        # It is very important to test this bit in the LAST place: it can overwrite the immediateAction to
        # something else but IMMEDIATEACTION_NONE
        #
        if ($immediateAction & IMMEDIATEACTION_MARK_EVENTS_DONE) {
          $self->_logger->tracef('[%d/%d]%s IMMEDIATEACTION_MARK_EVENTS_DONE', $count, $self->count_contexts, $startSymbol);
          $context->immediateAction(_IMMEDIATEACTION_EVENTS_DONE);
        }
      }
    }
    return $rc;
  }

  method _parse_generic(Dispatcher $dispatcher --> Parser) {
    my $context = $self->_get_context(-1);
    #
    # Constant variables
    #
    my $endEventName                   = $context->endEventName;
    my $grammar                        = $context->grammar;
    my $compiledGrammar                = $grammar->compiledGrammar;
    my $startSymbol                    = $grammar->startSymbol;
    my $recognizer                     = $context->recognizer;
    my $io                             = $self->io;
    my $line                           = $self->line;
    my $column                         = $self->column;
    my $unicode_newline_regexp         = $self->_unicode_newline_regexp;
    my @lexeme_match_by_symbol_ids     = $grammar->elements_lexemesRegexpBySymbolId;
    my @lexeme_exclusion_by_symbol_ids = $grammar->elements_lexemesExclusionsRegexpBySymbolId;
    my @lexeme_minlength_by_symbol_ids = $grammar->elements_lexemesMinlengthBySymbolId;
    my $_XMLNSCOLON_ID                 = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNSCOLON'};
    my $_XMLNS_ID                      = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNS'};
    my $count                          = $self->count_contexts;
    #
    # Non-constant variables
    #
    my $pos                            = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length                         = length($MarpaX::Languages::XML::Impl::Parser::buffer);   # Faster than $io->length
    my $remaining                      = $length - $pos;
    my $previousCanStop                = 0;
    my $canStop                        = false;
    #
    # Infinite loop until user says to last or error
    #
    if ($context->immediateAction != _IMMEDIATEACTION_EVENTS_DONE) {
      my $doEventsRc = $self->_doEvents($dispatcher, $context, $startSymbol, $endEventName, $recognizer, \$canStop, \$pos, \$length, \$remaining);
      $context->immediateAction(IMMEDIATEACTION_NONE);
      return $self if (! $doEventsRc);
    }

    while (1) {
      #
      # Expected lexemes
      #
      my @terminals_expected_to_symbol_ids = $recognizer->terminals_expected_to_symbol_ids();
      $self->_logger->tracef('[%d/%d]%s Expected: %s', $count, $self->count_contexts, $startSymbol, $recognizer->terminals_expected);
      $self->_logger->tracef('[%d/%d]%s      Ids: %s', $count, $self->count_contexts, $startSymbol, \@terminals_expected_to_symbol_ids);
      while (1) {
        my %length = ();
        my $max_length = 0;
        if (@terminals_expected_to_symbol_ids) {
          if ($length <= 0) {
            if ($self->_eof) {
              if ($canStop || $previousCanStop) {
                $self->_pop_context;
                return $self;
              } else {
                ParseException->throw("EOF but $startSymbol grammar is not over");
              }
            } else {
              $self->read($dispatcher, $context);
              $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
              if ($length <= 0) {
                $self->_eof(true);
                if ($canStop || $previousCanStop) {
                  $self->_pop_context;
                  return $self;
                } else {
                  ParseException->throw("EOF but $startSymbol grammar is not over");
                }
              }
              pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;
              $remaining = $length;
            }
          }
          my @undecidable = grep { $lexeme_minlength_by_symbol_ids[$_] > $remaining } @terminals_expected_to_symbol_ids;
          if (@undecidable && ! $self->_eof) {

            my $wanted = max(map { $lexeme_minlength_by_symbol_ids[$_] } @undecidable);
            my $needed = $wanted  - $remaining;
            $self->_logger->tracef('[%d/%d]%s Undecidable: need at least %d characters more', $count, $self->count_contexts, $startSymbol, $needed);
            if (! $self->inDecl) {
              $self->_reduce($context)->read($dispatcher, $context);
              $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;
            } else {
              $self->read($dispatcher, $context);
              pos($MarpaX::Languages::XML::Impl::Parser::buffer) = $pos;
            }
            $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
            my $new_remaining = $length - $pos;
            if ($new_remaining > $remaining) {
              #
              # Something was read
              #
              $remaining = $new_remaining;
              last;
            } else {
              $self->_eof(true);
            }

          }
        }
        my $terminals_expected_again = 0;
        foreach (@terminals_expected_to_symbol_ids) {
          #
          # It is a configuration error to have $lexeme_match_by_symbol_ids{$_} undef at this stage
          # Note: all our patterns are compiled with the /p modifier for perl < 5.20
          #
          # We use an optimized version to bypass the the Marpa::R2::Grammar::symbol_name call
          #
          if ($MarpaX::Languages::XML::Impl::Parser::buffer =~ $lexeme_match_by_symbol_ids[$_]) {
            my $matched_data = ${^MATCH};
            my $length_matched_data = length($matched_data);
            #
            # Match reaches end of buffer ?
            #
            if (($length_matched_data >= $remaining) && (! $self->_eof)) { # Match up to the end of buffer is avoided as much as possible
              if (! $self->inDecl) {
                $self->_reduce($context)->read($dispatcher, $context);
                $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;
              } else {
                $self->read($dispatcher, $context);
                pos($MarpaX::Languages::XML::Impl::Parser::buffer) = $pos;
              }
              $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
              my $new_remaining = $length - $pos;
              if ($new_remaining > $remaining) {
                #
                # Something was read
                #
                $remaining = $new_remaining;
                $terminals_expected_again = 1;
                last;
              } else {
                $self->_eof(true);
              }
            }
            #
            # Match excluded ?
            #
            my $lexeme_exclusion = $lexeme_exclusion_by_symbol_ids[$_];
            next if ($lexeme_exclusion && ($matched_data =~ $lexeme_exclusion));
            #
            # Lexeme ok
            #
            $length{$_} = $length_matched_data;
            $max_length = $length_matched_data if ($length_matched_data > $max_length);
          }
        }
        next if ($terminals_expected_again);
        #
        # Push terminals if any
        #
        if (@terminals_expected_to_symbol_ids) {
          if (! $max_length) {
            if ($canStop || $previousCanStop) {
              $self->_pop_context;
              return $self;
            } else {
              ParseException->throw('No predicted lexeme found');
            }
          }
          my $data = undef;
          #
          # Special case of _XMLNSCOLON and _XMLNS: we /know/ in advance they have
          # higher priority
          #
          if (exists($length{$_XMLNSCOLON_ID})) {
            $data = 'xmlns:';
            $max_length = length($data);
            %length = ($_XMLNSCOLON_ID => $max_length);
          } elsif (exists($length{$_XMLNS_ID})) {
            $data = 'xmlns';
            $max_length = length($data);
            %length = ($_XMLNS_ID => $max_length);
          } else {
            #
            # Everything else has the same (default) priority of 0: keep the longests only
            #
            %length = map {
              $_ => $length{$_}
            } grep {
              ($length{$_} == $max_length) ? do { do { $data //= substr($MarpaX::Languages::XML::Impl::Parser::buffer, $pos, $max_length)}, 1 } : 0
            } keys %length;
          }
          #
          # Prepare trackers change
          #
          my $next_pos  = $pos + $max_length;
          my $linebreaks;
          my $next_column;
          my $next_line;
          if ($linebreaks = () = $data =~ /$unicode_newline_regexp/g) {
            $next_line   = $line + $linebreaks;
            $next_column = 1 + ($max_length - $+[0]);
          } else {
            $next_line   = $line;
            $next_column = $column + $max_length;
          }
          $self->_logger->debugf('[%d/%d]%s Match: %s: %s', $count, $self->count_contexts, $startSymbol, {map { $compiledGrammar->symbol_name($_) => $length{$_} } keys %length}, $self->_safeString($data));
          foreach (keys %length) {
            #
            # Remember last data for this lexeme
            #
            $self->set_lastLexeme($_, $data);
            #
            # Do the alternative
            #
            $recognizer->lexeme_alternative_by_symbol_id($_);
          }
          #
          # Make it complete from grammar point of view. Never fails because
          # I rely entirely on predicted lexemes.
          #
          $recognizer->lexeme_complete(0, 1);
          #
          # Move trackers
          #
          $line = $self->_set_line($next_line);
          $column = $self->_set_column($next_column);
          $remaining -= $max_length;
          #
          # Reposition internal buffer
          #
          $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer) = $next_pos;
        } else {
          #
          # No prediction: this is ok only if grammar end_of_grammar flag is set
          #
          if ($canStop || $previousCanStop) {
            $self->_pop_context;
            return $self;
          } else {
            ParseException->throw('No predicted lexeme found and end of grammar not reached');
          }
        }
        last;
      }
      #
      # Go to next events
      #
      $previousCanStop = $canStop;
      return $self if (! $self->_doEvents($dispatcher, $context, $startSymbol, $endEventName, $recognizer, \$canStop, \$pos, \$length, \$remaining));
    }
    #
    # Never reached
    #
    ParseException->throw('Internal error, this code should never be reached');
  }

  with 'MarpaX::Languages::XML::Role::Parser';
  with 'MooX::Role::Logger';
}

1;
