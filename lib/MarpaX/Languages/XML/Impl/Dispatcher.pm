use Moops;

# PODCLASSNAME

# ABSTRACT: Dispatcher implementation

class MarpaX::Languages::XML::Impl::Dispatcher {
  use MarpaX::Languages::XML::Role::Dispatcher;

  method notify(@args --> Undef) {
    $self->_pluggable_process('NOTIFY', @args);
    return;
  }

  with qw/MarpaX::Languages::XML::Role::Dispatcher/;
}

1;

