package MarpaX::Languages::XML::Type::Parser;
use Type::Library
  -base,
  -declare => qw/Parser/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Parser, as ConsumerOf['MarpaX::Languages::XML::Role::Parser'];

1;
