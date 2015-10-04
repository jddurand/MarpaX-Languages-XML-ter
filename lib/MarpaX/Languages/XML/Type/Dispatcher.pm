package MarpaX::Languages::XML::Type::Dispatcher;
use Type::Library
  -base,
  -declare => qw/Dispatcher/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Dispatcher,
  as ConsumerOf['MarpaX::Languages::XML::Role::Dispatcher'];

1;
