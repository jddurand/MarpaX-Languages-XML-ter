use Moops;

# PODCLASSNAME

# ABSTRACT: Reader implementation for IO:Handle

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Reader::IO::Handle {
  use MarpaX::Languages::XML::Role::Reader;
  use Carp qw/croak/;

  has io   => (is => 'ro', isa => InstanceOf['IO::Handle'], required => 1);
  has _eof => (is => 'rw', isa => Bool, default => false);

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
      return 0 if (! $_[2]);                           # If len is zero, then no bytes are read and 0 is returned
      return -1 if ($self->_eof);                      # If no byte is available because the stream is at end of file, the value -1 is returned

      my $done = $self->io->read($_[0], $_[2], $_[1]);
      croak($!) if (! defined($done));
      if (! $done) {
        $self->_eof(true);                             # We handle ourself the EOF notion
        return -1;
      }
      return $done;
    }
  }

  with 'MarpaX::Languages::XML::Role::Reader';
}

1;
