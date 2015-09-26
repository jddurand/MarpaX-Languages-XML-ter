package MarpaX::Languages::XML::Type::IO;
use Type::Library
  -base,
  -declare => qw/IO/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare IO, as ConsumerOf['MarpaX::Languages::XML::Role::IO'];

1;
