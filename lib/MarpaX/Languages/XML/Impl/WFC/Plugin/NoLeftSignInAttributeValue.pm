use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint "No < sign in attribute value" implementation

class MarpaX::Languages::XML::Impl::WFC::Plugin::NoLeftSignInAttributeValue :assertions {
  use MarpaX::Languages::XML::Role::WFC::Plugin::NoLeftSignInAttributeValue;
  use MooX::Object::Pluggable;
  use MooX::Options;

  option wfcNoLeftSigneInAttributeValue => ( is => 'rw', isa => Bool, default => true, doc => q{Well-Formed constraints} );

  method execute(Str $attributeValue --> Bool) {
    assert(index('<', $attributeValue) >= 0);
  }

  with qw/MarpaX::Languages::XML::Role::WFC::Plugin::NoLeftSignInAttributeValue/;
}

1;

