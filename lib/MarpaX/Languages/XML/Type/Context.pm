package MarpaX::Languages::XML::Type::Context;
use Type::Library
  -base,
  -declare => qw/Context/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Context,
  as ConsumerOf['MarpaX::Languages::XML::Role::Context'];

1;
