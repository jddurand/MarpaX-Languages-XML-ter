use Moops;

# PODCLASSNAME

# ABSTRACT: PluginFactory role

role MarpaX::Languages::XML::Role::PluginFactory {
  use Module::Find qw/findallmod/;
  use Class::Load qw/try_load_class/;
  use MarpaX::Languages::XML::Role::PluginFactory;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MooX::Role::Logger;

  # VERSION

  # AUTHORITY

  method listAllPlugins(ClassName $class: Str $package) {
    return $class->listPlugins($package, ':all');
  }

  method listPlugins(Str $package, @plugins) {
    if (grep {$_ eq ':all'} @plugins) {
      my $packageAndThen = quotemeta($package . '::');
      @plugins = map { s/^$packageAndThen//; $_; } findallmod($package);
    } elsif (grep {$_ eq ':none'} @plugins) {
      @plugins = ();
    }
    return @plugins;
  }

  method install(Str $package, Dispatcher $dispatcher, @plugins  --> Bool) {
    my @list = $self->listPlugins($package, @plugins);
    if (! @list) {
      $self->_logger->tracef('No subclass for %s', $package);
    } else {
      $self->_logger->tracef('Got modules for %s', $package);
    }
    my $rc = false;
    foreach (@list) {
      my $pluginClass = join('::', $package, $_);
      if (try_load_class($pluginClass)) {
        $self->_logger->tracef('Success loading %s', $pluginClass);
        $dispatcher->plugin_add($pluginClass, $pluginClass->new);
        $rc = true;
      } else {
        $self->_logger->tracef('Failure to load %s', $pluginClass);
      }
    }
    return $rc;
  }

  with 'MooX::Role::Logger';
}

1;
