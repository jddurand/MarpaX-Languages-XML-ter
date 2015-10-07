package MarpaX::Languages::XML::Type::Resource;
use Type::Library
  -base,
  -declare => qw/Resource/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Resource, as ConsumerOf['MarpaX::Languages::XML::Role::Resource'];

;
1;
