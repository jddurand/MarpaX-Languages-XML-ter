use Moops;

# PODCLASSNAME

# ABSTRACT: entity implementation

class MarpaX::Languages::XML::Impl::Entity {
  use MarpaX::Languages::XML::Role::Entity;
  use MarpaX::Languages::XML::Type::EntityType -all;

  has name    => (is => 'ro', isa => Maybe[Str], required => 1); # document and external DTD subset have no name
  has type    => (is => 'ro', isa => EntityType, required => 1); # Parsed or Unparsed
  has content => (is => 'ro', isa => Str,        required => 1); # Better than Value and will hold anything

  with qw/MarpaX::Languages::XML::Role::Entity/;
}

1;
