use Moops;

# PODCLASSNAME

# ABSTRACT: Validation constraint implementation

class MarpaX::Languages::XML::Impl::VC {
  use MarpaX::Languages::XML::Role::VC;
  use MooX::Object::Pluggable;
  use MooX::Options;

  option vc => ( is => 'rw', isa => Bool, default => true, trigger => 1, short => 'v', negativable => 1, doc => q{Validation constraints. Default to a true value. Option is negativable with '--no-' prefix.} );

  method _trigger_vc (Bool $vc, @rest --> Undef) {
    if ($vc) {
      $self->load_plugins();
    }
    return;
  }

  with qw/MarpaX::Languages::XML::Role::VC/;
}

1;

