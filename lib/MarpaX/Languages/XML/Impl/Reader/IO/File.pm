use Moops;

# PODCLASSNAME

# ABSTRACT: Reader implementation for IO:File

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Reader::IO::File {
  use MarpaX::Languages::XML::Impl::Reader::IO::Handle;
  extends 'MarpaX::Languages::XML::Impl::Reader::IO::Handle';

  has '+io' => (is => 'ro', isa => InstanceOf['IO::File'], required => 1);

  method BUILD {
    $self->io->binmode;               # bytes only
  }
}
