use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
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
  use Throwable::Factory
    ParseException    => undef
    ;
  use Types::Common::Numeric -all;

  # VERSION

  # AUTHORITY

  has xmlVersion     => ( is => 'ro',  isa => XmlVersion,        required => 1 );
  has xmlns          => ( is => 'ro',  isa => Bool,              required => 1 );
  has vc             => ( is => 'ro',  isa => ArrayRef[Str],     required => 1, handles_via => 'Array', handles => { elements_vc => 'elements' } );
  has wfc            => ( is => 'ro',  isa => ArrayRef[Str],     required => 1, handles_via => 'Array', handles => { elements_wfc => 'elements' } );
  has blockSize      => ( is => 'ro',  isa => PositiveOrZeroInt, default => 1024 * 1024 );
  has rc             => ( is => 'rwp', isa => Int,               default => 0 );

  #
  # The followings are just to avoid creating them more than once
  #
  has _grammars      => ( is => 'rw',  isa => HashRef[Grammar],  lazy => 1, builder => 1, handles_via => 'Hash', handles => { _get_grammar => 'get' } );

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
    # - WFC constraints
    # - VC constraints
    # - other events
    #
    my $pluginFactory = MarpaX::Languages::XML::Impl::PluginFactory->new(grammar => $grammar);
    $pluginFactory
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::General', ':all')
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::IO',      ':all')
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::VC',      $self->elements_vc)
      ->registerPlugins($grammar, $dispatcher, 'MarpaX::Languages::XML::Impl::Plugin::WFC',     $self->elements_wfc)
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
    # Create a recognizer
    #
    my $recognizer = Marpa::R2::Scanless::R->new({grammar => $compiledGrammar});
    $context->recognizer($recognizer);
    #
    # Enable these events
    #
    foreach (qw/ENCNAME_COMPLETED XMLDECL_START_COMPLETED XMLDECL_END_COMPLETED VERSIONNUM_COMPLETED ELEMENT_START_COMPLETED/) {
      $recognizer->activate($_, 1);
    }
    return $self;
  }

  method _parse_element(Context $context --> Parser) {

    return $self;
  }


  with 'MarpaX::Languages::XML::Role::Parser';
}

1;
__DATA__
  method _reduce(Context $context --> Parser) {
    my $io = $context->io;
    my $pos = $io->pos;
    if ($pos >= $io->length) {
      $io->clear;
    } else {
      substr($MarpaX::Languages::XML::Impl::Parser::buffer, 0, $pos, '');
    }
    #
    # Re-position internal buffer
    #
    pos($MarpaX::Languages::XML::Impl::Parser::buffer) = 0;

    return $self;
  }

  method _read(Context $context --> Parser) {

    $context->io->read;
    $context->dispatcher->notify('IORead', $MarpaX::Languages::XML::Impl::Parser::buffer) if (! $context->inDeclaration);

    return $self;
  }

  method _generic_parse(Context $context, Recognizer $r, Str $endEventName, Bool $eolHandling, Bool $resume --> Parser) {
    #
    # Start recognizer if not resuming
    #
    $r->read(\'  ') if (! $resume);
    #
    # Variables that need initialization
    #
    my $io                             = $context->io;
    my $line                           = $context->line;
    my $column                         = $context->column;
    my $pos                            = $context->pos;
    my $dispatcher                     = $context->dispatcher;
    my $length                         = length($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $remaining                      = $length - $pos;
    my @lexeme_match_by_symbol_ids     = $grammar->elements_lexemesRegexpBySymbolId;
    my @lexeme_exclusion_by_symbol_ids = $grammar->elements_lexemesExclusionsRegexpBySymbolId;
    my $previous_can_stop              = 0;
    my $_XMLNSCOLON_ID                 = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNSCOLON'};
    my $_XMLNS_ID                      = $grammar->compiledGrammar->symbol_by_name_hash->{'_XMLNS'};
    #
    # Infinite loop until user says to stop or error
    #
    while (1) {
      my @event_names                      = map { $_->[0] } @{$r->events()};
      my @terminals_expected_to_symbol_ids = $r->terminals_expected_to_symbol_ids();
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
        return if ($context->callbackSaidStop);
      }
      #
      # Then the expected lexemes
      # This is a do {} while () because of end-of-buffer management
      #
      my $terminals_expected_again = 0;
      do {
        my %length = ();
        my $max_length = 0;
        foreach (@terminals_expected_to_symbol_ids) {
          #
          # It is a configuration error to have $lexeme_match{$_} undef at this stage
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
            if ((($pos + $length_matched_data) >= $length) && ! $io->eof) { # Match up to the end of buffer is avoided as much as possible
              $self->_reduce(->_my $old_remaining = $remaining;
              $remaining = $self->_reduceAndRead($_[1], $r, $pos, $length, \$pos, \$length, $grammar, $eol, $eol_impl);
            if ($remaining > $old_remaining) {
              #
              # Something was read
              #
              $terminals_expected_again = 1;
              last;
            } else {
              $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE Nothing more read",
                                     $LineNumber,
                                     $ColumnNumber) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
              $self->{_eof} = 1;
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
          $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE [Match] %s: length=%d",
                                 $LineNumber,
                                 $ColumnNumber,
                                 $grammar->scanless->symbol_name($_),
                                 length($matched_data)) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
          $length{$_} = $length_matched_data;
          $max_length = $length_matched_data if ($length_matched_data > $max_length);
        }
      }
      #
      # Push terminals if any
      #
      if (@terminals_expected_to_symbol_ids) {
        if (! $max_length) {
          if ($can_stop || $previous_can_stop) {
            $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE No predicted lexeme found but grammar end flag is on",
                                   $LineNumber,
                                   $ColumnNumber) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
            return;
          } else {
            $self->_parse_exception('No predicted lexeme found', $r);
          }
        }
        my $data = undef;
        #
        # Special case of _XMLNSCOLON and _XMLNS: we /know/ in advance they have
        # higher priority
        #
        if (exists($length{$_XMLNSCOLON_ID})) {
          $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE Lexeme _XMLNSCOLON detected and has priority", $LineNumber, $ColumnNumber) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
          $data = 'xmlns:';
          $max_length = length($data);
          %length = ($_XMLNSCOLON_ID => $max_length);
        } elsif (exists($length{$_XMLNS_ID})) {
          $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE Lexeme _XMLNS detected and has priority", $LineNumber, $ColumnNumber) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
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
            ($length{$_} == $max_length) ? do { do { $data //= substr($_[1], $pos, $max_length)}, 1 } : 0
          } keys %length;
        }
        #
        # Prepare trackers change
        #
        my $next_pos        = $self->{_next_pos}        = $pos + $max_length;
        my $next_global_pos = $self->{_next_global_pos} = $global_pos + $max_length;
        my $linebreaks;
        my $next_global_column;
        my $next_global_line;
        if ($linebreaks = () = $data =~ /$MarpaX::Languages::XML::Impl::Parser::newline_regexp/g) {
          $next_global_line   = $self->{_next_global_line}   = $LineNumber + $linebreaks;
          $next_global_column = $self->{_next_global_column} = 1 + ($max_length - $+[0]);
        } else {
          $next_global_line   = $self->{_next_global_line}   = $LineNumber;
          $next_global_column = $self->{_next_global_column} = $ColumnNumber + $max_length;
        }
        $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_MOVE Pushing %d characters with %s",
                               $LineNumber,
                               $ColumnNumber,
                               $next_global_line,
                               $next_global_column,
                               $max_length,
                               [ map { $grammar->scanless->symbol_name($_) } keys %length ]) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
        foreach (keys %length) {
          $self->_logger->debugf("$LOG_LINECOLUMN_FORMAT_HERE [Found] %s: length=%d",
                                 $LineNumber,
                                 $ColumnNumber,
                                 $grammar->scanless->symbol_name($_),
                                 $max_length) if ($MarpaX::Languages::XML::Impl::Parser::is_debug);
          #
          # Handle ourself lexeme event, if any
          # This is NOT a Marpa event, but our stuff.
          # This is why we base it on another reference
          # for speed (the lexeme ID). The semantic is quite similar to
          # Marpa's lexeme predicted event.
          #
          my $code = $lexeme_callbacks_ref->[$_];
          #
          # A lexeme event has also the data in the arguments
          # Take care: in our model, any true value in return will mean immediate stop
          #
          return if ($code && $self->$code($_[1], $r, $grammar, $data));
          #
          # Remember last data for this lexeme
          #
          $self->{_last_lexeme}->[$_] = $data;
          #
          # Do the alternative
          #
          $r->lexeme_alternative_by_symbol_id($_);
        }
        #
        # Make it complete from grammar point of view. Never fails because
        # I rely entirely on predicted lexemes.
        #
        $r->lexeme_complete(0, 1);
        #
        # Move trackers
        #
        $LineNumber   = $self->{LineNumber}   = $next_global_line;
        $ColumnNumber = $self->{ColumnNumber} = $next_global_column;
        $global_pos   = $self->{_global_pos}  = $next_global_pos;
        $pos          = $self->{_pos}         = $next_pos;
        $remaining    = $self->{_remaining}   = $length - $pos;
        #
        # Reposition internal buffer
        #
        pos($_[1]) = $pos;
      } else {
        #
        # No prediction: this is ok only if grammar end_of_grammar flag is set
        #
        if ($can_stop || $previous_can_stop) {
          $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE No prediction and grammar end flag is on", $LineNumber, $ColumnNumber) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
          return;
        } else {
          $self->_parse_exception('No prediction and grammar end flag is not set', $r);
        }
      }
    } while ($terminals_expected_again);
    #
    # Go to next events
    #
    $previous_can_stop = $can_stop;
  }
  #
  # Never reached -;
  #
  return;
}
