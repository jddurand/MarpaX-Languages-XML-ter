package MarpaX::Languages::XML::Type::Grammar::Event;
use Type::Library
  -base,
  -declare => qw/GrammarEvent/;
use Type::Utils -all;
use Types::Standard -types;

# VERSION

# AUTHORITY

declare GrammarEvent,
  as InstanceOf['MarpaX::Languages::XML::Impl::Grammar::Event'];

1;
