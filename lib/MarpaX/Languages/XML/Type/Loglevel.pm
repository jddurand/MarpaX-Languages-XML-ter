package MarpaX::Languages::XML::Type::Loglevel;
use Type::Library
  -base,
  -declare => qw/Loglevel/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Loglevel,
  as Enum[qw/DEBUG INFO WARN ERROR FATAL TRACE/];

1;
