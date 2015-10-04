package MarpaX::Languages::XML::Type::Exception;
use Type::Library
  -base,
  -declare => qw/Exception/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Exception, as Enum[qw/NotSupported NotRecognized Parse/];

1;
