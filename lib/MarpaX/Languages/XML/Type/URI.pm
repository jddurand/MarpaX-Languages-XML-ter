package MarpaX::Languages::XML::Type::URI;
use Type::Library
  -base,
  -declare => qw/URI/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare URI, as InstanceOf['MarpaX::RFC::RFC3986'];

;
1;
