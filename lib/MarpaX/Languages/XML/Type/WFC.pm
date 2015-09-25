package MarpaX::Languages::XML::Type::WFC;
use Type::Library
  -base,
  -declare => qw/WFC/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare WFC,
  as InstanceOf['MarpaX::Languages::XML::Impl::WFC'];

1;
