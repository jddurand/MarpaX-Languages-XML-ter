package MarpaX::Languages::XML::Type::StartSymbol;
use Type::Library
  -base,
  -declare => qw/StartSymbol/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare StartSymbol,
  as Enum[qw/document extParsedEnt extSubset/];

1;
