package MarpaX::Languages::XML::Type::State;
use Type::Library
  -base,
  -declare => qw/State StateRef/;
use Type::Utils -all;
use Types::Standard -types;
use MarpaX::Languages::XML::Type::Context -all;
use MarpaX::Languages::XML::Type::LastLexemes -all;
use MarpaX::Languages::XML::Type::NamespaceSupport -all;

# VERSION

# AUTHORITY

declare State,
  as Dict[
          context          => Context,
          lastLexemes      => LastLexemes,
          namespaceSupport => NamespaceSupport
         ];

declare StateRef,
  as Ref[State]
;
1;
