use Moops;

# PODCLASSNAME

# ABSTRACT: IO implementation on top of IO:All

class MarpaX::Languages::XML::Impl::IO {
  use MarpaX::Languages::XML::Impl::Encoding;
  use MarpaX::Languages::XML::Role::IO;
  use MarpaX::Languages::XML::Type::IO -all;
  use Fcntl qw/:seek/;
  use IO::All;
  use IO::All::LWP;
  use MooX::Role::Logger;
  use Throwable::Factory
    IOException => undef;
    ;
  use Types::Common::Numeric -all;

  # VERSION

  # AUTHORITY

  has encodingName      => ( is => 'rwp', isa => Str,  predicate => 1, init_arg => undef );
  has _source           => ( is => 'rw',  isa => Str);
  has _io               => ( is => 'rw',  isa => InstanceOf['IO::All'] );
  has _block_size_value => ( is => 'rw',  isa => PositiveInt, default => 1024 );
  has _buffer           => ( is => 'rw',  isa => ScalarRef, predicate => 1 );

  method BUILD {
    $self->_io(io);
  }

  method _guessEncoding( --> IO) {
    #
    # Guess encoding
    # --------------
    #
    # Set binary mode
    #
    $self->binmode;
    $self->_set_encodingName('binary');
    #
    # Position at the beginning
    #
    $self->pos(0);
    #
    # Read the first bytes. 1024 is far enough.
    #
    my $old_block_size = $self->block_size_value();
    $self->block_size(1024) if ($old_block_size != 1024);
    $self->read;
    return $self if ($self->length <= 0);
    #
    # The stream is supposed to be opened with the correct encoding, if any
    # If there was no guess from the BOM, default will be UTF-8. Nevertheless we
    # do NOT set it immediately: if it UTF-8, the beginning of the XML file will
    # start with one byte chars only, which is compatible with binary mode.
    # And if it is not UTF-8, the first chars will tell us more.
    # If the encoding is setted to something else but what the BOM eventually says
    # this will be handled by a callback from the grammar.
    #
    # In theory we should have the localized buffer available. We "//" just in case
    #
    my $bytes = ${$self->buffer};
    #
    # An XML processor SHOULD work with case-insensitive encoding name. So we uc()
    # (note: per def an encoding name contains only Latin1 character, i.e. uc() is ok)
    #
    my $encoding = MarpaX::Languages::XML::Impl::Encoding->new(bytes => $bytes);
    #
    # Make sure we are positionned at the beginning of the buffer and at correct
    # source position. This is inefficient for everything that is not seekable.
    # And reset it appropriately to Encoding object
    #
    $self->pos($encoding->byteStart);
    $self->clear;
    $self->encoding($encoding->value);
    $self->block_size($old_block_size) if ($old_block_size != 1024);

    return $self;
  }

  method open(Str $source --> IO) {

    $self->_source($source);
    $self->_logger->tracef('Opening %s', $source);
    $self->_io->open($source);
    $self->_guessEncoding if (! $self->has_encodingName);
    #
    # Restore user buffer if there was one
    #
    $self->buffer($self->_buffer) if ($self->_has_buffer);
    #
    # And block-size
    #
    $self->block_size($self->_block_size_value);

    return $self;
  }

  method close( --> IO) {
    $self->_logger->tracef('Closing %s', $self->_source);
    $self->_io->close();

    return $self;
  }

  method block_size(@args --> IO) {

    $self->_io->block_size($self->block_size_value(@args));

    return $self;
  }

  method eof( --> Bool) {

    return $self->_io->eof;
  }

  method block_size_value(... --> PositiveInt) {

    my $rc = $self->_block_size_value(@_);
    $self->_logger->tracef('%s block-size %s %s', @_ ? 'Setting' : 'Getting', @_ ? '->' : '<-', $rc);

    return $rc;
  }

  method name(... --> PositiveInt) {

    my $rc = $self->_io->name(@_);

    return $self;
  }

  method binmode( --> IO) {

    $self->_logger->tracef('Setting binary mode');
    $self->_io->binary;
    $self->_set_encodingName('binary');

    return $self;
  }

  method length( --> PositiveOrZeroInt) {

    my $rc = $self->_io->length();
    $self->_logger->tracef('Getting length -> %s', $rc);

    return $rc;
  }

  method buffer(@args --> ScalarRef) {

    $self->_logger->tracef('%s buffer', @args ? 'Setting' : 'Getting');
    $self->_buffer($args[0]) if (@args);
    return $self->_io->buffer(@args);
  }


  {
    no warnings 'redefine';
    method read( --> IO) {

      $self->_logger->tracef('Reading %d units', $self->_block_size_value);
      $self->_io->read;

      return $self;
    }
    method write(@args --> IO) {

      $self->_logger->tracef('Writing to IO object');
      $self->_io->write(@args);

      return $self;
    }
  }

  method append(@args --> IO) {

    $self->_logger->tracef('Appending to IO object');
    $self->_io->append(@args);

    return $self;
  }

  method clear( --> IO) {

    $self->_logger->tracef('Clearing buffer');
    $self->_io->clear;

    return $self;
  }

  method tell( --> PositiveOrZeroInt) {

    my $rc = $self->_io->tell;
    $self->_logger->tracef('Tell -> %s', $rc);

    return $rc;
  }

  method seek(@args --> IO) {

    $self->_logger->tracef('Seek %s', \@args);
    $self->_io->seek(@args);

    return $self;
  }

  method reopen(--> IO) {
    $self->open($self->_source)
      ->binmode
      #
      # Take care! pos() and buffer are back to zero
      #
      ->clear;
  }

  method encoding(Str $encodingName --> IO) {

    if (uc($self->encodingName) ne uc($encodingName)){ # encoding name is not case sensitive
      $self->_logger->tracef('New encoding layer %s disagree with previous layer %s: reopening the stream and resetting buffer', $encodingName, $self->encodingName);
      $self->reopen;
    }
    $self->_logger->tracef('Setting encoding layer %s', $encodingName);
    $self->_io->encoding($encodingName);
    $self->_set_encodingName($encodingName);

    return $self;
  }

  method pos(PositiveOrZeroInt $pos --> IO) {

    my $pos_ok = 0;
    my $tell = $self->tell;
    if ($tell != $pos) {
      $self->seek($pos, SEEK_SET);
      if ($self->tell != $pos) {
        $self->_logger->tracef('Failure setting position from %d to %d failure', $tell, $pos);
      } else {
        $pos_ok = 1;
      }
    } else {
      $pos_ok = 1;
    }
    if (! $pos_ok) {
      #
      # Ah... not seekable perhaps
      # The only alternative is to reopen the stream
      #
      my $orig_block_size = $self->block_size_value;
      $self->reopen
        ->binmode
        ->encoding($self->encodingName)
        ->block_size($pos)
        ->read;
      if ($self->length != $pos) {
        #
        # Really I do not know what else to do
        #
        IOException->throw("Re-opening failed to position at byte $pos");
      } else {
        #
        # Restore original io block size
        $self->block_size($self->block_size_value($orig_block_size));
      }
    }

    return $self;
  }

  with 'MarpaX::Languages::XML::Role::IO';
  with 'MooX::Role::Logger';
}

1;

