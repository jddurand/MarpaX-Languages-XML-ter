package MarpaX::Languages::XML::Type::LexemesExclusionsRegexp;
use Type::Library
  -base,
  -declare => qw/LexemesExclusionsRegexp/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare LexemesExclusionsRegexp, as HashRef[RegexpRef];

;
1;
