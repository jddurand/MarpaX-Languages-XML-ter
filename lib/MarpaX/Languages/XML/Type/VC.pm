package MarpaX::Languages::XML::Type::VC;
use Type::Library
  -base,
  -declare => qw/VC/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare VC,
  as InstanceOf['MarpaX::Languages::XML::Impl::VC'];

1;
