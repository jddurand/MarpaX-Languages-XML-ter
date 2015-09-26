package MarpaX::Languages::XML::Type::State;
use Type::Library
  -base,
  -declare => qw/State/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare State, as ConsumerOf['MarpaX::Languages::XML::Role::State'];

;
1;
