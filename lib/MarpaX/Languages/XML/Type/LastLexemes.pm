package MarpaX::Languages::XML::Type::LastLexemes;
use Type::Library
  -base,
  -declare => qw/LastLexemes/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare LastLexemes,
  as ArrayRef[Maybe[Str]];

1;
