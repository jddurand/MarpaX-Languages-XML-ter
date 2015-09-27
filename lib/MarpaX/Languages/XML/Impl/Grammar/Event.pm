use Moops;

# PODCLASSNAME

# ABSTRACT: Grammar Event implementation

class MarpaX::Languages::XML::Impl::Grammar::Event {
  use MarpaX::Languages::XML::Role::PluginFactory;
  use MarpaX::Languages::XML::Role::Grammar::Event;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MooX::HandlesVia;

  has dispatcher => (
                     is => 'ro',
                     isa => Dispatcher,
                     required => 1
                    );

  has event => (
              is => 'ro',
              isa => ArrayRef[Str],
              handles_via => 'Array',
              handles => {
                          'elements_event' => 'elements'
                         },
              required => 1,
              trigger => 1,
             );

  method _trigger_event(ArrayRef[Str] $event  --> Undef) {
    $self->pluginsAdd(__PACKAGE__, $self->dispatcher, $self->elements_event);
    return;
  }

  with 'MarpaX::Languages::XML::Role::PluginFactory';
  with 'MarpaX::Languages::XML::Role::Grammar::Event';
}

1;

