package MarpaX::Languages::XML::Type::StreamChars;
use Type::Library
  -base,
  -declare => qw/StreamChars/;
use Type::Utils -all;
use Types::Encodings -types;       # To get Bytes
use Encode;

# VERSION

# AUTHORITY

declare StreamChars,
  as Chars;

1;
