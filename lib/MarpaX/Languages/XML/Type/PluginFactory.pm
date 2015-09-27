package MarpaX::Languages::XML::Type::PluginFactory;
use Type::Library
  -base,
  -declare => qw/PluginFactory/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare PluginFactory,
  as ConsumerOf['MarpaX::Languages::XML::Role::PluginFactory'];

1;
