use Moops;

# PODCLASSNAME

# ABSTRACT: Reader implementation for Str

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Reader::Str {
  use IO::String;
  use MarpaX::Languages::XML::Role::Reader;
  use MarpaX::Languages::XML::Impl::Reader::IO::String;

  has io  => (is => 'ro', isa => Str, required => 1);
  has _io => (is => 'rw', isa => InstanceOf['MarpaX::Languages::XML::Impl::Reader::IO::String']);

  method BUILD {
    $self->_io(MarpaX::Languages::XML::Impl::Reader::IO::String->new(IO::String->new($self->io)));
  }

  method BUILDARGS(@args) {
    unshift(@args, 'io') if (@args % 2 == 1);
    print STDERR "RETURNING { @args }\n";
    return { @args };
  }

  {
    no warnings 'redefine';
    method read(... --> Int) {
      $self->_io->read(@_)
    }
  }

  with 'MarpaX::Languages::XML::Role::Reader';
}
