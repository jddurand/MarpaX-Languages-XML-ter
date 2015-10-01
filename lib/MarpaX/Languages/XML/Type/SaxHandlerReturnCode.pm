package MarpaX::Languages::XML::Type::SaxHandlerReturnCode;
use Type::Library
  -base,
  -declare => qw/SaxHandlerReturnCode/;
use Type::Utils -all;
use Types::Standard -types;
use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;

# VERSION

# AUTHORITY

declare SaxHandlerReturnCode,
  as Enum[EXIT_SUCCESS, EXIT_FAILURE];

1;
