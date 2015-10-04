package MarpaX::Languages::XML::Type::EntityType;
use Type::Library
  -base,
  -declare => qw/EntityType/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare EntityType,
  as Enum[qw/Parsed Unparsed/];

1;
