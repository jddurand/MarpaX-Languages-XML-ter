use Moops;

# PODCLASSNAME

# ABSTRACT: PluginFactory implementation

class MarpaX::Languages::XML::Impl::PluginFactory {
  use Module::Find qw/findallmod/;
  use Class::Load qw/try_load_class/;
  use MarpaX::Languages::XML::Role::PluginFactory;
  use MarpaX::Languages::XML::Type::Dispatcher -all;

  #
  # I suppose a parameterized role would have looked better -;
  #

  method install(ClassName $class: Str $package, Dispatcher $dispatcher, @plugins  --> Undef) {
    if (grep {$_ eq ':all'} @plugins) {
      my $packageAndThen = quotemeta($package . '::');
      @plugins = map { s/^$packageAndThen//; $_; } findallmod($package);
    }
    foreach (@plugins) {
      my $pluginClass = join('::', $package, $_);
      if (try_load_class($pluginClass)) {
        $dispatcher->plugin_add($pluginClass, $pluginClass->new);
      }
    }
    return;
  }

  with 'MarpaX::Languages::XML::Role::PluginFactory';
}

1;

