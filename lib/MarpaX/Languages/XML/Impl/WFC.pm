use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint implementation

class MarpaX::Languages::XML::Impl::WFC {
  use MarpaX::Languages::XML::Impl::PluginFactory;
  use MarpaX::Languages::XML::Role::WFC;
  use MooX::Object::Pluggable;
  use MooX::Options;

  option wfc => ( is => 'rw', isa => Bool, default => true, short => 'w', negativable => 1, doc => q{Well-Formed constraints. Default to a true value. Option is negativable with '--no-' prefix.} );

  around BUILD {
    $self->${^NEXT}(@_);
    my $pluginFactory = MarpaX::Languages::XML::Impl::PluginFactory->new(fromModule => __PACKAGE__);
    my @plugins = $pluginFactory->load_plugins;
  }

  method _trigger_wfc (Bool $wfc, @rest --> Undef) {
    if ($wfc) {
      $self->load_plugins();
    }
    return;
  }

  with qw/MarpaX::Languages::XML::Role::WFC/;
}

1;

