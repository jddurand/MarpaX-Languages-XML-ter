package MarpaX::Languages::XML::Type::Entity;
use Type::Library
  -base,
  -declare => qw/Entity/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Entity,
  as ConsumerOf['MarpaX::Languages::XML::Role::Entity'];

1;
