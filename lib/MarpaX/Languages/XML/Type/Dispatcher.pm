package MarpaX::Languages::XML::Type::Dispatcher;
use Type::Library
  -base,
  -declare => qw/Dispatcher/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Dispatcher,
  as InstanceOf['MarpaX::Languages::XML::Impl::Dispatcher'];

1;
