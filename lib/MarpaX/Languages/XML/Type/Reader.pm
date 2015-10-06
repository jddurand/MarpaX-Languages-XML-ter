package MarpaX::Languages::XML::Type::Reader;
use Type::Library
  -base,
  -declare => qw/Reader/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Reader, as ConsumerOf['MarpaX::Languages::XML::Role::Reader'];

;
1;
