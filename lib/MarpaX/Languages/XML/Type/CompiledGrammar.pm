package MarpaX::Languages::XML::Type::CompiledGrammar;
use Type::Library
  -base,
  -declare => qw/CompiledGrammar/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare CompiledGrammar, as InstanceOf['Marpa::R2::Scanless::G'];

;
1;
