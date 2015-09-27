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

  #
  # The followings are just to avoid creating them more than once
  #
  has _unicode_newline_regexp => ( is => 'rw',  isa => RegexpRef, default => sub { return qr/\R/; }  );
  has _grammars               => ( is => 'rw',  isa => HashRef[Grammar],  lazy => 1, builder => 1, handles_via => 'Hash', handles => { _get_grammar => 'get' } );

  method _trigger_unicode_newline(Bool $unicode_newline --> Undef) {
    $self->_unicode_newline_regexp($unicode_newline ? qr/\R/ : qr/\n/);
  }

  method _build__grammars( --> HashRef[Grammar]) {
    my %grammars = ();
    foreach (qw/document prolog element/) {
      $grammars{$_} = MarpaX::Languages::XML::Impl::Grammar->new(xmlVersion => $self->xmlVersion, xmlns => $self->xmlns, startSymbol => $_);
    }
    return \%grammars;
  }

  method parse(Str $source --> Int) {
    #
    # Prepare variables to build the context
    #
    my $io         = MarpaX::Languages::XML::Impl::IO->new(source => $source);
    my $grammar    = $self->_get_grammar('document');
    my $dispatcher = MarpaX::Languages::XML::Impl::Dispatcher->new();
    #
    # We want to handle buffer direcly with no COW: the buffer scalar is localized
    #
    local $MarpaX::Languages::XML::Impl::Parser::buffer = '';
    $io->buffer(\$MarpaX::Languages::XML::Impl::Parser::buffer);
    #
    # Create context
    #
    my $context = MarpaX::Languages::XML::Impl::Context->new(io => $io, grammar => $grammar, dispatcher => $dispatcher);

    #
    # And events framework. They are:
    # - WFC constraints (configurable)
    # - VC constraints (configurable)
    # - other events (not configurable)
    #
    my $pluginFactory = MarpaX::Languages::XML::Impl::PluginFactory->new(grammar => $grammar);
    $pluginFactory
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::WFC',     $self->elements_wfc)
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::VC',      $self->elements_vc)
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::IO',      ':all')
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::General', ':all')
      ;
    #
    # Go
    #
    $io->block_size($self->blockSize);

    return $self->_parse_prolog($context)->_parse_element($context)->rc;
  }

  method _parse_prolog(Context $context --> Parser) {
    #
    # Get compiled grammar
    #
    my $compiledGrammar = $context->grammar->compiledGrammar;
    #
    # Get symbols IDs of interest from the compiled grammar
    #
    my  ($_ENCNAME_ID, $_XMLDECL_START_ID, $_XMLDECL_END_ID, $_VERSIONNUM_ID, $_ELEMENT_START_ID) = @{$compiledGrammar->symbol_by_name_hash}
      {qw/_ENCNAME_ID   _XMLDECL_START_ID   _XMLDECL_END_ID   _VERSIONNUM_ID   _ELEMENT_START_ID/};
    #
    # Create a recognizer and initalize it
    #
    my $recognizer = Marpa::R2::Scanless::R->new({grammar => $compiledGrammar});
    $recognizer->read(\'  ');
    $context->recognizer($recognizer);
    #
    # Enable these events
    #
    foreach (qw/ENCNAME_COMPLETED XMLDECL_START_COMPLETED XMLDECL_END_COMPLETED VERSIONNUM_COMPLETED ELEMENT_START_COMPLETED prolog_COMPLETED/) {
      $recognizer->activate($_, 1);
    }
    #
    # And parse prolog
    #
    return $self->_generic_parse($context, 'prolog$', false);
  }

  method _parse_element(Context $context --> Parser) {

    return $self;
  }


  method _reduce(Context $context --> Parser) {
    my $io = $context->io;
    my $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
    if ($pos >= $length) {
      $MarpaX::Languages::XML::Impl::Parser::buffer = '';
    } else {
      substr($MarpaX::Languages::XML::Impl::Parser::buffer, 0, $pos, '');
    }
    #
    # Re-position internal buffer
    #
    pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;

    return $self;
  }

  method _read(Context $context, Bool $eolHandling --> Parser) {

    $context->io->read;
    $context->dispatcher->process('EOL', $context) if ($eolHandling);

    return $self;
  }

  method _generic_parse(Context $context, Str $endEventName, Bool $eolHandling --> Parser) {
    #
    # Constant variables
    #
    my $grammar                        = $context->grammar;
    my $compiledGrammar                = $grammar->compiledGrammar;
    my $recognizer                     = $context->recognizer;
    my $io                             = $context->io;
    my $line                           = $context->line;
    my $column                         = $context->column;
    my $dispatcher                     = $context->dispatcher;
    my $unicode_newline_regexp         = $self->_unicode_newline_regexp;
    #
    # Non-constant variables
    #
    my $pos                            = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length                         = length($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $remaining                      = $length - $pos;
    my @lexeme_match_by_symbol_ids     = $grammar->elements_lexemesRegexpBySymbolId;
    my @lexeme_exclusion_by_symbol_ids = $grammar->elements_lexemesExclusionsRegexpBySymbolId;
    my @lexeme_minlength_by_symbol_ids = $grammar->elements_lexemesMinlengthBySymbolId;
    my $previous_can_stop              = 0;
    my $_XMLNSCOLON_ID                 = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNSCOLON'};
    my $_XMLNS_ID                      = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNS'};
    my $eof                            = 0;
    #
    # Make sure that this variable is initialized to a false value
    #
    $context->callbackSaidStop(false);
    #
    # Infinite loop until user says to stop or error
    #
    while (1) {
      my @event_names                      = map { $_->[0] } @{$recognizer->events()};
      $self->_logger->debugf('Events  : %s', $recognizer->events);
      my @terminals_expected_to_symbol_ids = $recognizer->terminals_expected_to_symbol_ids();
      $self->_logger->debugf('Expected: %s', $recognizer->terminals_expected);
      $self->_logger->tracef('     Ids: %s', \@terminals_expected_to_symbol_ids);
      #
      # First the events
      #
      my $can_stop = 0;
      foreach (@event_names) {
        #
        # Catch the end event name
        #
        $can_stop = 1 if ($_ eq $endEventName);
        #
        # Dispatch events
        #
        $dispatcher->notify($_, $context);
        #
        # Return if one of the callbacks said stop
        #
        return $self if ($context->callbackSaidStop);
      }
      #
      # Then the expected lexemes
      #
      while (1) {
        my %length = ();
        my $max_length = 0;
        if (@terminals_expected_to_symbol_ids) {
          if (! $length) {
            $self->_read($context, $eolHandling);
            $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
            if ($length <= 0) {
              $self->_logger->debugf('EOF');
              return $self;
            }
            pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;
          }
          my @undecidable = grep { $lexeme_minlength_by_symbol_ids[$_] > $remaining } @terminals_expected_to_symbol_ids;
          if (@undecidable && ! $eof) {
            my $needed = max(map { $lexeme_minlength_by_symbol_ids[$_] } @undecidable) - $remaining;
            $self->_logger->tracef('Undecidable: need at least %d characters more', $needed);
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
              $self->_logger->debugf('EOF');
              $eof = true;
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
            if (($length_matched_data >= $remaining) && (! $eof)) { # Match up to the end of buffer is avoided as much as possible
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
                $self->_logger->debugf('EOF');
                $eof = true;
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
            if ($can_stop || $previous_can_stop) {
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
          $self->_logger->debugf('Match: %s', {map { $compiledGrammar->symbol_name($_) => $length{$_} } keys %length});
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
          if ($can_stop || $previous_can_stop) {
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
      $previous_can_stop = $can_stop;
    }
    #
    # Never reached -;
    #
    return $self;
  }

  with 'MarpaX::Languages::XML::Role::Parser';
  with 'MooX::Role::Logger';
}

1;
