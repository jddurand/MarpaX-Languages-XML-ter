package MarpaX::Languages::XML::Type::BytesOrChars;
use Type::Library
  -base,
  -declare => qw/BytesOrChars/;
use Type::Utils -all;
use Types::Encodings -types;       # To get Bytes
use Encode;

# VERSION

# AUTHORITY

declare BytesOrChars,
  as Chars|Bytes;

1;
