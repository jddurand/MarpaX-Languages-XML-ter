use Moops;

# PODCLASSNAME

# ABSTRACT: PluginsRegister implementation

class MarpaX::Languages::XML::Impl::PluginsRegister {
  use Module::Find qw/findallmod/;
  use Class::Load qw/try_load_class/;
  use MarpaX::Languages::XML::Role::PluginsRegister;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MooX::Role::Logger;
  use MooX::Singleton;

  #
  # I suppose a parameterized role would have looked better -;
  #

  method pluginsRegister(Str $package, Dispatcher $dispatcher, @plugins  --> Undef) {
    if (grep {$_ eq ':all'} @plugins) {
      my $packageAndThen = quotemeta($package . '::');
      @plugins = map { s/^$packageAndThen//; $_; } findallmod($package);
    }
    foreach (@plugins) {
      my $pluginClass = join('::', $package, $_);
      my ($ok, $errorMessage) = try_load_class($pluginClass);
      if (! $ok) {
        $self->_logger->warnf('%s not loaded: %s', $pluginClass, $errorMessage);
      } else {
        $pluginClass->new->plugin_register($dispatcher);
      }
    }
    return;
  }

  with 'MarpaX::Languages::XML::Role::PluginsRegister';
  with 'MooX::Role::Logger';
  with 'MooX::Singleton';
}

1;

