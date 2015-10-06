use Moops;

# PODCLASSNAME

# ABSTRACT: Reader implementation for IO:String

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Reader::IO::String {
  use MarpaX::Languages::XML::Role::Reader;

  has io         => (is => 'ro', isa => InstanceOf['IO::String'], required => 1);

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
    #
    # IO::String behaviour is OK as far as I know
    #

    method read(... --> Int) {
      (! $_[2])   && return  0;                            # If len is zero, then no bytes are read and 0 is returned
      my $io = $self->io;
      $io->eof && return -1;                               # If no byte is available because the stream is at end of file, the value -1 is returned
      #
      # This cannot return undef because we guaranteed this was opened with a valid Str
      # Neverthless IO::String does like if $_[0] is undef
      $_[0] = '' if (! defined($_[0]));
      $io->read($_[0], $_[2], $_[1])
    }
  }

  with 'MarpaX::Languages::XML::Role::Reader';
}
