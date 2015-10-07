package MarpaX::Languages::XML::Type::IRI;
use Type::Library
  -base,
  -declare => qw/IRI/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare IRI, as InstanceOf['MarpaX::RFC::RFC3987'];

;
1;
