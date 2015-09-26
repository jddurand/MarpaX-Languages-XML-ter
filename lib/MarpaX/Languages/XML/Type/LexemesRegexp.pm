package MarpaX::Languages::XML::Type::LexemesRegexp;
use Type::Library
  -base,
  -declare => qw/LexemesRegexp/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare LexemesRegexp, as HashRef[RegexpRef];

;
1;
