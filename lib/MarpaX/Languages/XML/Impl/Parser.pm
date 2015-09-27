use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
  use Marpa::R2;
  use MarpaX::Languages::XML::Impl::Context;
  use MarpaX::Languages::XML::Impl::Grammar::Event;
  use MarpaX::Languages::XML::Impl::Grammar;
  use MarpaX::Languages::XML::Impl::Dispatcher;
  use MarpaX::Languages::XML::Impl::IO;
  use MarpaX::Languages::XML::Impl::Encoding;
  use MarpaX::Languages::XML::Impl::WFC;
  use MarpaX::Languages::XML::Impl::VC;
  use MarpaX::Languages::XML::Role::Parser;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Encoding -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::Grammar::Event -all;
  use MarpaX::Languages::XML::Type::NamespaceSupport -all;
  use MarpaX::Languages::XML::Type::IO -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Type::WFC -all;
  use MarpaX::Languages::XML::Type::VC -all;
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
  has vc             => ( is => 'ro',  isa => ArrayRef[Str],     required => 1 );
  has wfc            => ( is => 'ro',  isa => ArrayRef[Str],     required => 1 );
  has blockSize      => ( is => 'ro',  isa => PositiveOrZeroInt, default => 1024 * 1024 );
  has rc             => ( is => 'rwp', isa => Int,               default => 0 );

  has _dispatcher    => ( is => 'rw',  isa => Dispatcher,        lazy => 1, builder => 1 );
  has _wfcInstance   => ( is => 'rw',  isa => WFC,               lazy => 1, builder => 1 );
  has _vcInstance    => ( is => 'rw',  isa => VC,                lazy => 1, builder => 1 );
  has _eventInstance => ( is => 'rw',  isa => GrammarEvent,      lazy => 1, builder => 1 );
  #
  # The following is just to avoid rebuilding grammars everytime
  #
  has _grammars      => ( is => 'rw',  isa => HashRef[Grammar],  lazy => 1, builder => 1, handles_via => 'Hash', handles => { _get_grammar => 'get' } );

  method _build__dispatcher( --> Dispatcher )  {
    return MarpaX::Languages::XML::Impl::Dispatcher->new();
  }

  method _build__wfcInstance( --> WFC) {
    return MarpaX::Languages::XML::Impl::WFC->new(dispatcher => $self->_dispatcher, wfc => $self->wfc);
  }

  method _build__vcInstance( --> VC) {
    return MarpaX::Languages::XML::Impl::VC->new(dispatcher => $self->_dispatcher, vc => $self->wfc);
  }

  method _build__eventInstance( --> GrammarEvent) {
    return MarpaX::Languages::XML::Impl::Grammar::Event->new(dispatcher => $self->_dispatcher, event => [qw/:all/]);
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
    my $io               = MarpaX::Languages::XML::Impl::IO->new(source => $source);
    my $grammar          = $self->_get_grammar('document');
    #
    # We want to handle buffer direcly with no COW: we could either pass it in
    # parameters or localize it. I choose localization so that method signatures
    # will not eat it. And this is easier since there are a lot of different
    # packages involved -;
    #
    local $MarpaX::Languages::XML::Impl::Parser::buffer = '';
    $io->buffer(\$MarpaX::Languages::XML::Impl::Parser::buffer);
    #
    # Create context
    #
    my $context = MarpaX::Languages::XML::Impl::Context->new(io => $io, grammar => $grammar);
    #
    # Go
    #
    $io->block_size($self->blockSize);
    $self->_eventInstance;
    $self->_wfcInstance;
    $self->_vcInstance;

    return $self
      ->_parse_prolog($context)
      ->_parse_element($context)
      ->rc;
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
  method _generic_parse(IO $io, Encoding $encoding, Grammar $grammar, NamespaceSupport $ns, Recognizer $r, Str $endEventName, Bool $eolHandling, Bool $resume, State $previousState? --> Parser) {
    #
    # Start recognizer if not resuming
    #
    $r->read(\'  ') if (! $resume);
    #
    # Create a State compatible hash
    #
  #
  # Variables that need initialization
  #
  my $global_pos       = $self->{_global_pos};
  my $LineNumber       = $self->{LineNumber};
  my $ColumnNumber     = $self->{ColumnNumber};
  my $pos              = $self->{_pos};
  my $length           = $self->{_length};
  my $remaining        = $self->{_remaining};
  my @lexeme_match_by_symbol_ids     = $grammar->elements_lexeme_match_by_symbol_ids;
  my @lexeme_exclusion_by_symbol_ids = $grammar->elements_lexeme_exclusion_by_symbol_ids;
  my $previous_can_stop = 0;
  my $_XMLNSCOLON_ID   = $grammar->scanless->symbol_by_name_hash->{'_XMLNSCOLON'};
  my $_XMLNS_ID        = $grammar->scanless->symbol_by_name_hash->{'_XMLNS'};
  my $eol_impl         = $grammar->eol_impl;
  #
  # Infinite loop until user says to stop or error
  #
  while (1) {
    my @event_names = map { $_->[0] } @{$r->events()};
    my @terminals_expected_to_symbol_ids = $r->terminals_expected_to_symbol_ids();
    if ($MarpaX::Languages::XML::Impl::Parser::is_debug) {
      #
      # If trace if on, then debug is on
      #
      $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE Pos: %d, Length: %d, Remaining: %d", $LineNumber, $ColumnNumber, $pos, $length, $remaining) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
      if ($self->_remaining > 0) {
        my $data = hexdump(data => substr($_[1], $pos, 16),
                           suppress_warnings => 1,
                           space_as_space    => 1
                          );
        my $nbzeroes = ($data =~ s/( 00)(?= (?::|00))/   /g);
        if ($nbzeroes) {
          $data =~ s/\.{$nbzeroes}$//;
        }
        $self->_logger->debugf("$LOG_LINECOLUMN_FORMAT_HERE [.....] %s", $LineNumber, $ColumnNumber, $data);
      } else {
        $self->_logger->debugf("$LOG_LINECOLUMN_FORMAT_HERE [.....] %s", $LineNumber, $ColumnNumber, 'none');
      }
      if ($MarpaX::Languages::XML::Impl::Parser::is_trace) {
        $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE %s/%s/%s: Events                : %s", $LineNumber, $ColumnNumber, $grammar->spec, $grammar->xml_version, $grammar->start, \@event_names);
        $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE %s/%s/%s: Expected terminals    : %s", $LineNumber, $ColumnNumber, $grammar->spec, $grammar->xml_version, $grammar->start, $r->terminals_expected());
        $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE %s/%s/%s: Expected terminals IDs: %s", $LineNumber, $ColumnNumber, $grammar->spec, $grammar->xml_version, $grammar->start, \@terminals_expected_to_symbol_ids);
      }
    }
    #
    # First the events
    #
    my $can_stop = 0;
    foreach (@event_names) {
      #
      # The end event name ?
      #
      $can_stop = 1 if ($_ eq $end_event_name);
      #
      # Callback ?
      #
      my $code = $callbacks_ref->{$_};
      #
      # A callback has no other argument but the buffer, the recognizer and the grammar
      # Take care: in our model, any true value in return will mean immediate stop
      #
      return if ($code && $self->$code($_[1], $r, $grammar));
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
        if ($_[1] =~ $lexeme_match_by_symbol_ids[$_]) {
          my $matched_data = ${^MATCH};
          my $length_matched_data = length($matched_data);
          #
          # Match reaches end of buffer ?
          #
          if ((($pos + $length_matched_data) >= $length) && ! $self->{_eof}) { # Match up to the end of buffer is avoided as much as possible
            $self->_logger->tracef("$LOG_LINECOLUMN_FORMAT_HERE Lexeme %s (%s) is reaching end-of-buffer",
                                   $LineNumber,
                                   $ColumnNumber,
                                   $_,
                                   $grammar->scanless->symbol_name($_)) if ($MarpaX::Languages::XML::Impl::Parser::is_trace);
            my $old_remaining = $remaining;
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
