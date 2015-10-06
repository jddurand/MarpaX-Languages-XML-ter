use Moops;

# PODCLASSNAME

# ABSTRACT: IO implementation on top of IO::All or IO::String

# Note: try to use io->string. You will get almost nothing usable
# plus the overhead is tfar too high for something in memory.

class MarpaX::Languages::XML::Impl::IO {
  use Fcntl qw/:seek/;
  use IO::All;
  use IO::All::LWP;
  use IO::String;
  use MarpaX::Languages::XML::Impl::Encoding;
  use MarpaX::Languages::XML::Role::IO;
  use MarpaX::Languages::XML::Type::IO -all;
  use MooX::Role::Logger;
  use Throwable::Factory IOException => undef;
  use Types::Common::Numeric -all;

  # VERSION

  # AUTHORITY

  has source            => ( is => 'ro',  isa => Str|ScalarRef,     required => 1 );

  has _encodingName     => ( is => 'rw',  isa => Str,               trigger => 1, lazy => 1, builder => 1, reader => 'encodingName');
  has _byteStart        => ( is => 'rw',  isa => PositiveOrZeroInt, trigger => 1, default => 0,            reader => 'byteStart');
  has _io               => ( is => 'rw',  isa => InstanceOf['IO::All']|InstanceOf['IO::String'] );
  has _is_string        => ( is => 'rw',  isa => Bool );

  method BUILD {
    $self->_logger->tracef('Opening %s', $self->source);
    $self->_is_string(ScalarRef->check($self->source));
    $self->_open;
  }

  method DEMOLISH {
    $self->_logger->tracef('Closing %s', $self->source);
  }

  method _trigger__encodingName(Str $encodingName) {
    $self->_logger->tracef('Setted encodingName to %s', $encodingName);
  }

  method _trigger__byteStart(PositiveOrZeroInt $byteStart) {
    $self->_logger->tracef('Setted byteStart to %d', $byteStart);
  }

  method _build__encodingName( --> Str) {
    #
    # No-op for an IO::String
    #
    return '' if ($self->_is_string);
    #
    # Read first BYTES (1024 is the IO::all default and is enough)
    #
    $self->binmode->read;
    my $encoding = MarpaX::Languages::XML::Impl::Encoding->new(bytes => ${$self->_io->buffer});
    $self->_byteStart($encoding->byteStart);
    return $encoding->value;
  }

  method _open( --> IO) {
    # Note: doing ->encoding() before the pos() ensure that byteStart is
    #       calculated if needed
    $self->_io($self->_is_string ? IO::String->new($self->source) : io($self->source))->encoding($self->encodingName);
    $self->seek($self->byteStart, SEEK_SET);
    return $self;
  }

  method binmode(... --> IO) {
    $self->_logger->tracef('Setting binary mode %s', \@_);
    $self->_io->binmode(@_);
    return $self;
  }

  method length( --> PositiveOrZeroInt) {
    my $rc = $self->_is_string ? length(${$self->source}) : $self->_io->length();
    $self->_logger->tracef('Getting length -> %s', $rc);
    return $rc;
  }

  method eof( --> Bool) {
    my $rc = $self->_io->eof;
    $self->_logger->tracef('Getting EOF -> %s', $rc ? 'yes' : 'no');
    return $rc;
  }

  {
    no warnings 'redefine';
    method read(... --> IO) {
      my $rc = $self->_io->read(@_);
      $self->_logger->tracef('Reading %d units -> %d done', $rc);
      return $self;
    }
  }

  method tell( --> PositiveOrZeroInt) {
    my $rc = $self->_io->tell;
    $self->_logger->tracef('Tell -> %s', $rc);
    return $rc;
  }

  method seek(... --> IO) {
    $self->_logger->tracef('Seek %s', \@_);
    $self->_io->seek(@_);
    return $self;
  }

  method reopen(--> IO) {
    $self->_logger->tracef('Reopening %s', $self->source);
    $self->_open;
  }

  method encoding(Str $encodingName --> IO) {
    if (uc($self->encodingName) ne uc($encodingName)){ # encoding name is not case sensitive
      $self->_logger->tracef('New encoding layer %s disagree with previous layer %s: reopening the stream and resetting buffer', $encodingName, $self->encodingName);
      #
      # User's responsability to change byteStart if needed;
      #
      $self->_set__encodingName($encodingName);
      $self->reopen;
    }
    return $self;
  }

  with 'MarpaX::Languages::XML::Role::IO';
  with 'MooX::Role::Logger';
}

1;
