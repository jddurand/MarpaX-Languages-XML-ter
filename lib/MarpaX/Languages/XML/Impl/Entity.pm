use Moops;

# PODCLASSNAME

# ABSTRACT: entity implementation

class MarpaX::Languages::XML::Impl::Entity {
  use MarpaX::Languages::XML::Role::Entity;
  use MarpaX::Languages::XML::Type::EntityType -all;

  has name => (is => 'ro', isa => Str|Undef,  required => 1); # document and external DTD subset have no name
  has type => (is => 'ro', isa => EntityType, required => 1);

  with qw/MarpaX::Languages::XML::Role::Entity/;
}

1;
