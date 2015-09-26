use Moops;

# PODCLASSNAME

# ABSTRACT: State implementation

class MarpaX::Languages::XML::Impl::State {
  use MarpaX::Languages::XML::Role::State;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::LastLexemes -all;
  use MarpaX::Languages::XML::Type::NamespaceSupport -all;

  has origin           => ( is => 'ro', isa => Str );
  has context          => ( is => 'ro', isa => Context );
  has lastLexemes      => ( is => 'ro', isa => LastLexemes );
  has namespaceSupport => ( is => 'ro', isa => NamespaceSupport );

  with qw/MarpaX::Languages::XML::Role::State/;
}

1;

