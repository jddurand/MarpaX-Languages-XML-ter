use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
  use List::Util qw/max/;
  use Marpa::R2;
  use MarpaX::Languages::XML::Impl::Context;
  use MarpaX::Languages::XML::Impl::Dispatcher;
  use MarpaX::Languages::XML::Impl::Grammar;
  use MarpaX::Languages::XML::Impl::IO;
  use MarpaX::Languages::XML::Impl::Encoding;
  use MarpaX::Languages::XML::Impl::PluginFactory;
  use MarpaX::Languages::XML::Role::Parser;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Encoding -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::NamespaceSupport -all;
  use MarpaX::Languages::XML::Type::IO -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MarpaX::Languages::XML::Type::StartSymbol -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Marpa::R2::Hooks;
  use MooX::HandlesVia;
  use MooX::Role::Logger;

  use Throwable::Factory
    ParseException    => undef
    ;
  use Types::Common::Numeric -all;

  # VERSION

  # AUTHORITY

  has xmlVersion      => ( is => 'ro',  isa => XmlVersion,        required => 1 );
  has xmlns           => ( is => 'ro',  isa => Bool,              required => 1 );
  has vc              => ( is => 'ro',  isa => ArrayRef[Str],     required => 1, handles_via => 'Array', handles => { elements_vc => 'elements' } );
  has wfc             => ( is => 'ro',  isa => ArrayRef[Str],     required => 1, handles_via => 'Array', handles => { elements_wfc => 'elements' } );
  has blockSize       => ( is => 'ro',  isa => PositiveOrZeroInt, default => 1024 * 1024 );
  has rc              => ( is => 'rwp', isa => Int,               default => 0 );
  has unicode_newline => ( is => 'ro',  isa => Bool,              default => false, trigger => 1 );
  has startSymbol     => ( is => 'ro',  isa => StartSymbol,       default => 'document' );

  has _contexts       => ( is => 'rw',  isa => ArrayRef[Context], default => sub { [] }, 
                           handles_via => 'Array', handles => {
                                                               _count_contexts => 'count',
                                                               _push_context   => 'push',
                                                               _pop_context    => 'pop',
                                                               _get_context    => 'get'
                                                              }
                         );
  has _eof            => ( is => 'rw',  isa => Bool,              default => false, trigger => 1 );

  method _trigger__eof(Bool $eof) {
    $self->_logger->debugf('EOF');
  }

  around _push_context {
    my $count = $self->_count_contexts;
    my $rc = $self->${^NEXT}(@_);
    $self->_logger->debugf('Pushed %s context (%d -> %d), canStop=%s', $_[0]->grammar->startSymbol, $count, $count + 1, $_[0]->previousCanStop);
    return $rc;
  };

  around _pop_context {
    my $count = $self->_count_contexts;
    my $previousContext = $self->_get_context(-1);
    my $rc = $self->${^NEXT}(@_);
    my $startSymbol = $rc->grammar->startSymbol;
    my $previousCanStop = $rc->previousCanStop;
    $self->_logger->debugf('Popped %s context (%d -> %d), canStop=%s', $startSymbol, $count, $count - 1, $previousCanStop);
    if ($startSymbol eq 'prolog') {
      #
      # After prolog we want to continue to element
      #
      my $grammar = $self->_get_grammar('element');
      my $context = MarpaX::Languages::XML::Impl::Context->new(
                                                               io               => $previousContext->io,
                                                               grammar          => $grammar,
                                                               encoding         => $previousContext->encoding,
                                                               dispatcher       => $previousContext->dispatcher,
                                                               namespaceSupport => $previousContext->namespaceSupport,
                                                               endEventName     => 'element_COMPLETED'
                                                              );
      $self->_push_context($context);
    }
    elsif ($startSymbol eq 'element') {
      if ($self->_count_contexts <= 0) {
        #
        # After the root element we want to continue to MiscAny
        #
        my $grammar = $self->_get_grammar('MiscAny');
        my $context = MarpaX::Languages::XML::Impl::Context->new(
                                                                 io               => $previousContext->io,
                                                                 grammar          => $grammar,
                                                                 encoding         => $previousContext->encoding,
                                                                 dispatcher       => $previousContext->dispatcher,
                                                                 namespaceSupport => $previousContext->namespaceSupport,
                                                                 endEventName     => '!nullable'
                                                                );
        $self->_push_context($context);
      }
    }
    return $rc;
  };

  has _unicode_newline_regexp => ( is => 'rw',  isa => RegexpRef,                          default => sub { return qr/\R/; }  );
  has _grammars               => ( is => 'rw',  isa => HashRef[Grammar],                   lazy => 1, builder => 1, handles_via => 'Hash', handles => { _get_grammar => 'get' } );
  has _grammars_events        => ( is => 'rw',  isa => HashRef[HashRef[HashRef[Str]]],     lazy => 1, builder => 1, handles_via => 'Hash', handles => { _get_grammar_events => 'get' } );
  has _namespaceSupport       => ( is => 'rw',  isa => NamespaceSupport,                   lazy => 1, builder => 1 );
  #
  # In the case of document, in reality with start with prolog
  #
  method _realStartSymbol( --> Str) {
    my $startSymbol = $self->startSymbol;

    return ($startSymbol eq 'document') ? 'prolog' : $startSymbol;
  }

  method _trigger_unicode_newline(Bool $unicode_newline --> Undef) {
    $self->_unicode_newline_regexp($unicode_newline ? qr/\R/ : qr/\n/);
  }

  method _build__grammars_events( --> HashRef[HashRef[HashRef[Str]]]) {
    return {
            prolog => {
                       completed => {
                                     ENCNAME_COMPLETED       => 'ENCNAME',
                                     XMLDECL_START_COMPLETED => 'XMLDECL_START',
                                     XMLDECL_END_COMPLETED   => 'XMLDECL_END',
                                     VERSIONNUM_COMPLETED    => 'VERSIONNUM',
                                     ELEMENT_START_COMPLETED => 'ELEMENT_START',
                                     prolog_COMPLETED        => 'prolog'
                                    }
                      },
            element => {
                        completed => {
                                      element_COMPLETED       => 'element',
                                      STag_COMPLETED          => 'STag',
                                     },
                        nulled => {
                                   start_element      => 'start_element',
                                   end_element        => 'end_element'
                                  }
                       },
            MiscAny => {
#                        nulled => {
#                                      '!nullable'       => 'nullable',
#                                     }
                       },
            content => {
#                        completed => {
#                                      content_COMPLETED       => 'content',
#                                     }
                       }
           };
  }

  method _build__grammars( --> HashRef[Grammar]) {
    my %grammars = ();
    foreach (qw/prolog element MiscAny content/) {
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

  method _safe_string(Str $string --> Str) {
    #
    # Replace any character that would not be a known ASCII printable one with its hexadecimal value a-la-XML
    #
    # http://stackoverflow.com/questions/9730054/how-can-i-dump-a-string-in-perl-to-see-if-there-are-any-character-differences
    #
    $string =~ s/([^\x20-\x7E])/sprintf("&#x%x;", ord($1))/ge;
    return $string;
  }

  method parse(Str $source --> Int) {
    #
    # Prepare variables that do not change for any context
    #
    my $io               = MarpaX::Languages::XML::Impl::IO->new(source => $source);
    my $dispatcher       = MarpaX::Languages::XML::Impl::Dispatcher->new();
    my $namespaceSupport = $self->_namespaceSupport;
    #
    # Add events framework. They are:
    # - WFC constraints (configurable)
    # - VC constraints (configurable)
    # - other events (not configurable)
    #
    my $pluginFactory = MarpaX::Languages::XML::Impl::PluginFactory->new();
    $pluginFactory
      ->registerPlugins($self->xmlVersion, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::WFC',     $self->elements_wfc)
      ->registerPlugins($self->xmlVersion, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::VC',      $self->elements_vc)
      ->registerPlugins($self->xmlVersion, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::IO',      ':all')
      ->registerPlugins($self->xmlVersion, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::General', ':all')
      ;
    #
    # We want to handle buffer direcly with no COW: the buffer scalar is localized.
    # And have the block size as per the argument
    #
    local $MarpaX::Languages::XML::Impl::Parser::buffer = '';
    $io->buffer(\$MarpaX::Languages::XML::Impl::Parser::buffer);
    $io->block_size($self->blockSize);
    #
    # Start with the appropriate symbol
    #
    my $realStartSymbol = $self->_realStartSymbol;
    #
    # Push first context
    #
    my $grammar = $self->_get_grammar($realStartSymbol); # prolog, extParsedEnt, extSubset, element
    my $context = MarpaX::Languages::XML::Impl::Context->new(
                                                             io               => $io,
                                                             grammar          => $grammar,
                                                             dispatcher       => $dispatcher,
                                                             namespaceSupport => $namespaceSupport,
                                                             endEventName     => $realStartSymbol . '_COMPLETED'
                                                            );
    $self->_push_context($context);
    #
    # In the case od document, we do NOT start at document, so we fake the event ourself
    #
    if ($self->startSymbol eq 'document') {
      $dispatcher->notify('start_document', $self, $context);
    }
    #
    # Make sure that context will be demolished
    #
    ($io, $grammar, $dispatcher, $namespaceSupport, $context) = ();
    #
    # Loop until there is no more context
    #
    while ($self->_count_contexts) {
      $self->_parse_generic($self->_get_context(-1));
      $self->_logger->tracef('Number of remaining contexts: %d', $self->_count_contexts);
    };
    #
    # Return code eventually under SAX handler control
    #
    return $self->rc;
  }

  method _reduce(Context $context --> Parser) {
    my $io     = $context->io;
    my $pos    = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);

    if ($pos >= $length) {
      $MarpaX::Languages::XML::Impl::Parser::buffer = '';
    } else {
      substr($MarpaX::Languages::XML::Impl::Parser::buffer, 0, $pos, '');
    }

    return $self;
  }

  method _read(Context $context, Bool $eolHandling --> Parser) {

    $context->io->read;
    $context->dispatcher->process('EOL', $self, $context) if ($eolHandling);

    return $self;
  }

  method _parse_generic(Context $context --> Parser) {
    #
    # Constant variables
    #
    my $endEventName                   = $context->endEventName;
    my $eolHandling                    = $context->eolHandling;
    my $grammar                        = $context->grammar;
    my $compiledGrammar                = $grammar->compiledGrammar;
    my $startSymbol                    = $grammar->startSymbol;
    my $recognizer                     = $context->recognizer;
    my $io                             = $context->io;
    my $line                           = $context->line;
    my $column                         = $context->column;
    my $dispatcher                     = $context->dispatcher;
    my $unicode_newline_regexp         = $self->_unicode_newline_regexp;
    my @lexeme_match_by_symbol_ids     = $grammar->elements_lexemesRegexpBySymbolId;
    my @lexeme_exclusion_by_symbol_ids = $grammar->elements_lexemesExclusionsRegexpBySymbolId;
    my @lexeme_minlength_by_symbol_ids = $grammar->elements_lexemesMinlengthBySymbolId;
    my $_XMLNSCOLON_ID                 = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNSCOLON'};
    my $_XMLNS_ID                      = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNS'};
    #
    # Non-constant variables
    #
    my $pos                            = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length                         = length($MarpaX::Languages::XML::Impl::Parser::buffer);   # Faster than $io->length
    my $remaining                      = $length - $pos;
    my $previousCanStop                = $context->previousCanStop;
    #
    # Initialize immediatePause flag
    #
    $context->immediatePause(false);
    #
    # Infinite loop until user says to stop or error
    #
    while (1) {
      my @event_names                      = map { $_->[0] } @{$recognizer->events()};
      $self->_logger->tracef('%s Events  : %s', $startSymbol, $recognizer->events);
      my @terminals_expected_to_symbol_ids = $recognizer->terminals_expected_to_symbol_ids();
      $self->_logger->tracef('%s Expected: %s', $startSymbol, $recognizer->terminals_expected);
      $self->_logger->tracef('%s      Ids: %s', $startSymbol, \@terminals_expected_to_symbol_ids);
      if (grep {$_ eq 'element_COMPLETED'} @event_names) {
        print STDERR $recognizer->show_progress;
      }
      #
      # First the events
      #
      my $canStop = false;
      foreach (@event_names) {
        #
        # Catch the end event name
        #
        $canStop = true if ($_ eq $endEventName);
        #
        # Dispatch events
        #
        $dispatcher->notify($_, $self, $context);
      }
      #
      # Immediate pause ?
      #
      last if ($context->immediatePause);
      #
      # Then the expected lexemes
      #
      while (1) {
        my %length = ();
        my $max_length = 0;
        if (@terminals_expected_to_symbol_ids) {
          if ($length <= 0) {
            if ($self->_eof) {
              if ($canStop || $previousCanStop) {
                $self->_pop_context();
                return $self;
              } else {
                ParseException->throw("EOF but $startSymbol grammar is not over");
              }
            } else {
              $self->_read($context, $eolHandling);
              $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
              if ($length <= 0) {
                $self->_eof(true);
                if ($canStop || $previousCanStop) {
                  $self->_pop_context();
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
            my $needed = max(map { $lexeme_minlength_by_symbol_ids[$_] } @undecidable) - $remaining;
            $self->_logger->tracef('%s Undecidable: need at least %d characters more', $startSymbol, $needed);
            my $old_block_size_value = $io->block_size_value;
            if ($old_block_size_value != $needed) {
              $io->block_size($needed);
            }
            $self->_read($context, $eolHandling);
            if ($old_block_size_value != $needed) {
              $io->block_size($old_block_size_value);
            }
            pos($MarpaX::Languages::XML::Impl::Parser::buffer) = $pos;
            my $new_length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
            if ($new_length > $length) {
              #
              # Something was read
              #
              $length = $new_length;
              $remaining = $length - $pos;
              next;
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
              $self->_reduce($context)->_read($context, $eolHandling);
              $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;
              $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
              if ($length > $remaining) {
                #
                # Something was read
                #
                $remaining = $length;
                $terminals_expected_again = 1;
                last;
              } else {
                $remaining = $length;
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
              $self->_pop_context();
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
          $self->_logger->debugf('Match: %s: %s', {map { $compiledGrammar->symbol_name($_) => $length{$_} } keys %length}, $self->_safe_string($data));
          foreach (keys %length) {
            #
            # Remember last data for this lexeme
            #
            $context->set_lastLexeme($_, $data);
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
          $line = $context->line($next_line);
          $column = $context->column($next_column);
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
            $self->_pop_context();
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
      $previousCanStop = $context->previousCanStop($canStop);
    }
    #
    # Reached only in the case of immediate pause
    #
    $self->_logger->tracef('%s Immediate pause', $startSymbol);
    $context->previousCanStop($previousCanStop);
    return $self;
  }

  with 'MarpaX::Languages::XML::Role::Parser';
  with 'MooX::Role::Logger';
}

1;
