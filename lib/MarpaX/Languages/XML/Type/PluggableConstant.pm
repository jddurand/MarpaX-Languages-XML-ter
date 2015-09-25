package MarpaX::Languages::XML::Type::PluggableConstant;
use MooX::Role::Pluggable::Constants qw/EAT_NONE EAT_CLIENT EAT_PLUGIN EAT_ALL/;
use Type::Library
  -base,
  -declare => qw/PluggableConstant/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare PluggableConstant,
  as Enum[EAT_NONE, EAT_CLIENT, EAT_PLUGIN, EAT_ALL];

1;
