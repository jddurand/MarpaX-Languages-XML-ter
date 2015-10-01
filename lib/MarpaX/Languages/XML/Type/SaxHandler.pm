package MarpaX::Languages::XML::Type::SaxHandler;
use Type::Library
  -base,
  -declare => qw/SaxHandler/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare SaxHandler,
  as HashRef[CodeRef];

1;
