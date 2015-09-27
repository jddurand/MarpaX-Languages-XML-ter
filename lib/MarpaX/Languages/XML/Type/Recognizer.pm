package MarpaX::Languages::XML::Type::Recognizer;
use Type::Library
  -base,
  -declare => qw/Recognizer/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare Recognizer, as InstanceOf['MarpaX::R2::Scanless::R'];

;
1;
