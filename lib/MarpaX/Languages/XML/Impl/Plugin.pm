use Moops;

# PODCLASSNAME

# ABSTRACT: Plugin generic implementation

class MarpaX::Languages::XML::Impl::Plugin {
  use MarpaX::Languages::XML::Role::Plugin;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::State -all;
  use MooX::HandlesVia;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;

  has doc => (is => 'ro', isa => Str, default => '');

  has xmlVersion => (is => 'ro', isa => XmlVersion, default => '1.0');

  has subscriptions => (is => 'rwp', isa => HashRef[ArrayRef[Str]],
                        default => sub { return {} },
                        handles_via => 'Hash',
                        handles => {
                                    keys_subscriptions => 'keys',
                                    get_subscriptions => 'get'
                                   }
                       );

  method plugin_register(Dispatcher $dispatcher --> PluggableConstant) {
    foreach ($self->keys_subscriptions) {
      my $eventNamesArrayRef = $self->get_subscriptions($_);
      $self->_logger->tracef('Subscription of %s to event type %s => %s', blessed($self), $_, $eventNamesArrayRef);
      $dispatcher->subscribe($self, $_, @{$eventNamesArrayRef});
    }

    return EAT_NONE;
  }

  with 'MarpaX::Languages::XML::Role::Plugin';
  with 'MooX::Role::Logger';
}

1;

