use Moops;

# PODCLASSNAME

# ABSTRACT: Reader implementation on top of IO:All, IO::File, IO::Handle, IO::String, Str

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Reader {
  use Carp qw/croak/;
  use MarpaX::Languages::XML::Impl::Reader::IO::All;
  use MarpaX::Languages::XML::Impl::Reader::IO::File;
  use MarpaX::Languages::XML::Impl::Reader::IO::Handle;
  use MarpaX::Languages::XML::Impl::Reader::IO::String;
  use MarpaX::Languages::XML::Impl::Reader::Str;
  use MarpaX::Languages::XML::Role::Reader;
  use MarpaX::Languages::XML::Type::Reader -all;

   my $ReaderType = Reader->plus_coercions(
                                           InstanceOf['IO::All'],    q{ MarpaX::Languages::XML::Impl::Reader::IO::All->new($_)    },
                                           InstanceOf['IO::File'],   q{ MarpaX::Languages::XML::Impl::Reader::IO::File->new($_)   },
                                           InstanceOf['IO::Handle'], q{ MarpaX::Languages::XML::Impl::Reader::IO::Handle->new($_) },
                                           InstanceOf['IO::String'], q{ MarpaX::Languages::XML::Impl::Reader::IO::String->new($_) },
                                           Str,                      q{ MarpaX::Languages::XML::Impl::Reader::Str->new($_)        }
                                          );

  has io   => (is => 'ro', isa => InstanceOf['IO::All', 'IO::File', 'IO::Handle', 'IO::String']|Str, required => 1);
  has _reader => (is => 'rw', isa => $ReaderType, coerce => 1);

  method BUILD {
    $self->_reader($self->io);
  }

  method BUILDARGS(@args) {
    unshift(@args, 'io') if (@args % 2 == 1);
    return { @args };
  }

  {
    no warnings 'redefine';
    method read(... --> Int) {
      $self->_reader->read(@_)
    }
  }

  with 'MarpaX::Languages::XML::Role::Reader';
}

