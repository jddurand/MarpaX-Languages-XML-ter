use Moops;

# PODCLASSNAME

# ABSTRACT: Dispatcher implementation

class MarpaX::Languages::XML::Impl::Dispatcher {
  use MarpaX::Languages::XML::Role::Dispatcher;

  method notify {
    $self->_pluggable_process('NOTIFY', @_)     # No ';' for fewer hops
  }

  method process {
    $self->_pluggable_process('PROCESS', @_)     # No ';' for fewer hops
  }

  with qw/MarpaX::Languages::XML::Role::Dispatcher/;
}

1;
