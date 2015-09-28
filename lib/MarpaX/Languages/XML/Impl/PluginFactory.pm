use Moops;

# PODCLASSNAME

# ABSTRACT: PluginFactory role implementation

class MarpaX::Languages::XML::Impl::PluginFactory {
  use Module::Find qw/findallmod/;
  use Class::Load qw/try_load_class/;
  use MarpaX::Languages::XML::Role::PluginFactory;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::PluginFactory -all;
  use MooX::Role::Logger;

  # VERSION

  # AUTHORITY

  method listAllPlugins(ClassName $class: Str $package) {
    return $class->_listPlugins($package, ':all');
  }

  method _listPlugins(Str $package, @plugins) {
    my @list = ();
    foreach (@plugins) {
      if ($_ eq ':all') {
        my $packageAndThen = quotemeta($package . '::');
        push(@list, map { s/^$packageAndThen//; $_; } grep { index($_, 'no-') < 0 } findallmod($package));
      } elsif ($_ eq ':none') {
        @list = ();
      } else {
        if (index($_, 'no-') == 0) {
          my $exclude = $_;
          substr($exclude, 0, 3, '');
          @list = grep { $_ ne $exclude } @list;
        } else {
          push(@list, $_);
        }
      }
    }
    my %unique = ();
    @list = grep { ++$unique{$_} == 1 } @list;

    return @list;
  }

  method registerPlugins(XmlVersion $xmlVersion, Dispatcher $dispatcher, Str $package, @plugins  --> PluginFactory) {
    my @list = $self->_listPlugins($package, @plugins);
    if (! @list) {
      $self->_logger->tracef('No subclass for %s', $package);
    } else {
      $self->_logger->tracef('Got modules for %s', $package);
    }
    foreach (@list) {
      my $pluginClass = join('::', $package, $_);
      if (index($_, 'no-') == 0) {
        substr($_, 0, 3, '');
        $pluginClass = join('::', $package, $_);
        $self->_logger->tracef('Disable load of %s', $pluginClass);
      }
      my ($success, $errorMessage);
      #
      # Even if this named "try_xxx" this can croak
      #
      try {
        ($success, $errorMessage) = try_load_class($pluginClass);
      } catch {
        $success = 0;
        $errorMessage = $_;
      };
      if ($success) {
        $dispatcher->plugin_add($pluginClass, $pluginClass->new(xmlVersion => $xmlVersion));
      } else {
        $self->_logger->tracef('Failure to load %s: %s', $pluginClass, $errorMessage);
      }
    }
    return $self;
  }

  with 'MooX::Role::Logger';
  with 'MarpaX::Languages::XML::Role::PluginFactory';

}

1;
