package MarpaX::Languages::XML::Type::LexemesMinlength;
use Type::Library
  -base,
  -declare => qw/LexemesMinlength/;
use Type::Utils -all;
use Types::Standard -types;
use Types::Common::Numeric -all;

# VERSION

# AUTHORITY

declare LexemesMinlength, as HashRef[PositiveInt];

;
1;
