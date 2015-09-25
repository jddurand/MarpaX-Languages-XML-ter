use Moops;

# PODCLASSNAME

# ABSTRACT Marpa powered XML parser

class MarpaX::Languages::XML {
  use MarpaX::Languages::XML::Impl::Parser;

  extends qw/MarpaX::Languages::XML::Impl::Parser/;
}

1;
