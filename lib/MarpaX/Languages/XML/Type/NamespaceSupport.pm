package MarpaX::Languages::XML::Type::NamespaceSupport;
use Type::Library
  -base,
  -declare => qw/NamespaceSupport/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare NamespaceSupport,
  as InstanceOf['XML::NamespaceSupport'];

1;
