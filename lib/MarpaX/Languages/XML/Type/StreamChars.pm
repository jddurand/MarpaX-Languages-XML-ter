package MarpaX::Languages::XML::Type::StreamChars;
use Type::Library
  -base,
  -declare => qw/StreamChars/;
use Type::Utils -all;
use Types::Encodings -types;       # To get Bytes
use Encode;

# VERSION

# AUTHORITY

# Note: the same thing as Types::Encodings::Chars except this is in streaming mode
#       Types::Standard is defining the _croak() routine

our $CHECK = $ENV{XML_DEBUG} ? Encode::FB_WARN : Encode::FB_QUIET;

declare StreamChars,
  as Chars;

1;
