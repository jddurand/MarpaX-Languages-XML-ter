use Moops;

# ABSTRACT: XML::SAX::Exception extension with progress report, expected terminals and data dump

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Exception {
  use XML::SAX::Exception;
  use MarpaX::Languages::XML::Role::Exception;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Parser -all;

  has parser  => ( is => 'ro', isa => Parser,  required => 1 );
  has context => ( is => 'ro', isa => Context, required => 1 );

  extends 'XML::SAX::Exception';
  with 'MarpaX::Languages::XML::Role::Exception';
};

class MarpaX::Languages::XML::Exception::Impl::NotSupported extends MarpaX::Languages::XML::Impl::Exception {
};

class MarpaX::Languages::XML::Exception::Impl::NotRecognized extends MarpaX::Languages::XML::Impl::Exception {
};

class MarpaX::Languages::XML::Exception::Impl::Parse extends MarpaX::Languages::XML::Impl::Exception {
};

1;
