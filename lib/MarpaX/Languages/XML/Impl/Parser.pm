use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
  use MarpaX::Languages::XML::Impl::WFC;
  use MarpaX::Languages::XML::Impl::VC;
  use MarpaX::Languages::XML::Role::Parser;

  method parse() {
  }

  extends qw/MarpaX::Languages::XML::Impl::WFC
             MarpaX::Languages::XML::Impl::VC/;

  with qw/MarpaX::Languages::XML::Role::Parser/;
}

1;

