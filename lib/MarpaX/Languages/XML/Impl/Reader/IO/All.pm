use Moops;

# PODCLASSNAME

# ABSTRACT: Reader implementation for IO:All

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Reader::IO::All {
  use MarpaX::Languages::XML::Role::Reader;

  has io   => (is => 'ro', isa => InstanceOf['IO::All'], required => 1);
  has _eof => (is => 'rw', isa => Bool, default => false);

  my $buffer = '';
  method BUILD {
    $self->io->binmode;               # bytes only
    $self->io->buffer(\$buffer);      # internal read buffer
  }

  method BUILDARGS(@args) {
    unshift(@args, 'io') if (@args % 2 == 1);
    return { @args };
  }

  {
    no warnings 'redefine';
    #
    # We follow exactly Java's *Stream semantics:
    #
    # Reads up to len bytes of data from the input stream into an array of bytes.
    # An attempt is made to read as many as len bytes, but a smaller number may be read. The number of bytes actually read is returned as an integer.
    #
    # This method blocks until input data is available, end of file is detected, or an exception is thrown.
    #
    # If len is zero, then no bytes are read and 0 is returned; otherwise, there is an attempt to read at least one byte.
    # If no byte is available because the stream is at end of file, the value -1 is returned; otherwise, at least one byte is read and stored into b.

    method read(... --> Int) {
      (! $_[2])   && return  0;                            # If len is zero, then no bytes are read and 0 is returned
      $self->_eof && return -1;                            # If no byte is available because the stream is at end of file, the value -1 is returned
      #
      # Take care: underlying read can read MORE than asked
      #
      my $currentLength = length($buffer);
      if ($currentLength < $_[2]) {
        my $need = $_[2] - $currentLength;
        $self->io->block_size($need), $self->io->read;     # Reads up to needed bytes of data - we assume underlying read will block until some bytes, or EOF, or error
        $currentLength = length($buffer);
      }
      my $done = ($currentLength <= $_[2]) ? $currentLength : $_[2];
      (! $done) && $self->_eof(true) && return -1;         # We do not trust underlying EOF
      substr($_[0], $_[1], $done, substr($buffer, 0, $done, '')), $done
    }
  }

  with 'MarpaX::Languages::XML::Role::Reader';
}

