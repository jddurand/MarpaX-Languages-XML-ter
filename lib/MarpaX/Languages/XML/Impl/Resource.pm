use Moops;

# PODCLASSNAME

# ABSTRACT: Resource implementation on top of MarpaX::RFC::RFC3986 and MarpaX::RFC::RFC3987

# VERSION

# AUTHORITY

class MarpaX::Languages::XML::Impl::Resource {
  use MarpaX::Languages::XML::Role::Resource;
  use MarpaX::Languages::XML::Type::IRI -all;
  use MarpaX::Languages::XML::Type::Resource -all;
  use MarpaX::Languages::XML::Type::URI -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::RFC::RFC3986;
  use MarpaX::RFC::RFC3987;

  has xmlVersion => (is => 'ro',  isa => XmlVersion, required => 1);
  has name       => (is => 'ro',  isa => Str, required => 1);
  has identifier => (is => 'rwp', isa => URI|IRI, lazy => 1, builder => 1);

  method _build_identifier( --> URI|IRI) {
    if ($self->xmlVersion eq '1.0') {
      return MarpaX::RFC::RFC3986->new($self->name); # URI
    } else {
      return MarpaX::RFC::RFC3987->new($self->name); # IRI
    }
  }

  with 'MarpaX::Languages::XML::Role::Resource';
}

1;
