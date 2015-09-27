use Moops;

# PODCLASSNAME

# ABSTRACT: IO implementation

class MarpaX::Languages::XML::Impl::IO {
  use MarpaX::Languages::XML::Role::IO;
  use MarpaX::Languages::XML::Type::IO -all;
  use Fcntl qw/:seek/;
  use IO::All;
  use IO::All::LWP;
  use MooX::Role::Logger;
  use Throwable::Factory
    IOException    => [qw/$source/]
    ;
  use Types::Common::Numeric -all;

  # VERSION

  # AUTHORITY

  has source            => ( is => 'ro',  isa => Str,  required => 1, trigger => 1 );

  has _io               => ( is => 'rw',  isa => InstanceOf['IO::All'] );
  has _block_size_value => ( is => 'rw',  isa => PositiveInt, default => 1024 );

  method _trigger_source(Str $source --> Undef) {
    $self->_open($source);
  }

  method DEMOLISH {
    $self->_close();
  }

  method _open(Str $source, @args --> Undef) {

    $self->_logger->tracef('Opening %s %s', $source, \@args);
    $self->_io(io($source))->open(@args);

    return;
  }

  method _close( --> Undef) {
    $self->_logger->tracef('Closing %s', $self->source);
    $self->_io->close();

    return;
  }

  method block_size(@args --> IO) {

    $self->_io->block_size($self->block_size_value(@args));

    return $self;
  }

  method block_size_value(@args --> PositiveInt) {

    my $rc = $self->_block_size_value(@args);
    $self->_logger->tracef('%s block-size %s %s', @args ? 'Setting' : 'Getting', @args ? '->' : '<-', $rc);

    return $rc;
  }

  method binary( --> IO) {

    $self->_logger->tracef('Setting binary mode');
    $self->_io->binary();

    return $self;
  }

  method length( --> PositiveOrZeroInt) {

    my $rc = $self->_io->length();
    $self->_logger->tracef('Getting length -> %s', $rc);

    return $rc;
  }

  method buffer(@args --> ScalarRef) {

    $self->_logger->tracef('%s buffer', @args ? 'Setting' : 'Getting');
    return $self->_io->buffer(@args);
  }


  {
    no warnings 'redefine';
    method read( --> IO) {

      $self->_logger->tracef('Reading %d units', $self->_block_size_value);
      $self->_io->read;

      return $self;
    }
  }

  method eof( --> Bool) {
    return $self->_io->eof;
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

  method encoding(Str $encoding --> IO) {

    $self->_logger->tracef('Setting encoding "%s"', $encoding);
    $self->_io->encoding($encoding);

    return $self;
  }

  method pos(PositiveOrZeroInt $pos --> IO) {

    my $pos_ok = 0;
    try {
      my $tell = $self->tell;
      if ($tell != $pos) {
        $self->seek($pos, SEEK_SET);
        if ($self->tell != $pos) {
          IOException->throw(
                             sprintf('Failure setting position from %d to %d failure', $tell, $pos),
                             source => $self->source
                            );
        } else {
          $pos_ok = 1;
        }
      } else {
        $pos_ok = 1;
      }
    };
    if (! $pos_ok) {
      #
      # Ah... not seekable perhaps
      # The only alternative is to reopen the stream
      #
      my $orig_block_size = $self->block_size_value;
      $self->close;
      $self->open($self->_source);
      $self->binary;
      $self->block_size($pos);
      $self->read;
      if ($self->length != $pos) {
        #
        # Really I do not know what else to do
        #
        IOException->throw(
                           "Re-opening failed to position at byte $pos",
                           source => $self->_source
                          );
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

