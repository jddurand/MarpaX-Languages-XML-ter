package MarpaX::Languages::XML::Type::Encoding;
use Type::Library
  -base,
  -declare => qw/Encoding/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Encoding, as ConsumerOf['MarpaX::Languages::XML::Role::Encoding'];

1;
