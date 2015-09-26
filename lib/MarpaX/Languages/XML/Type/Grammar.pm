package MarpaX::Languages::XML::Type::Grammar;
use Type::Library
  -base,
  -declare => qw/Grammar/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Grammar, as ConsumerOf['MarpaX::Languages::XML::Role::Grammar'];

;
1;
