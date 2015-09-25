use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint "No < sign in attribute value" implementation

class MarpaX::Languages::XML::Impl::WFC::NoLeftSignInAttributeValue :assertions {
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::State -all;
  use MarpaX::Languages::XML::Role::WFC::NoLeftSignInAttributeValue;
  use MooX::HandlesVia;
  use MooX::Role::Pluggable::Constants;
  use MooX::Role::Logger;

  has subscriptions => (is => 'rwp', isa => HashRef[ArrayRef[Str]],
                        default => sub {
                          return {
                                  NOTIFY => [ 'AttValue_COMPLETE' ]
                                 };
                        },
                        handles_via => 'Hash',
                        handles => {
                                    'keys_subscriptions' => 'keys',
                                    'get_subscriptions' => 'get'
                                   }
                       );

  method plugin_register(Dispatcher $dispatcher --> PluggableConstant) {
    foreach ($self->keys_subscriptions) {
      my $eventNamesArrayRef = $self->get_subscriptions($_);
      $self->_logger->debugf('%s: Subscribing to %s events %s', __PACKAGE__, $_, $eventNamesArrayRef);
      $dispatcher->subscribe($self, $_, @{$eventNamesArrayRef});
    }

    return EAT_NONE;
  }

  method N_AttValue_COMPLETE(Dispatcher $dispatcher, Ref $stateRef, @args --> PluggableConstant) {
    my $state = State->assert_return(${$stateRef});

    return EAT_CLIENT;
  }

  with 'MarpaX::Languages::XML::Role::WFC::NoLeftSignInAttributeValue';
  with 'MooX::Role::Logger';
}

1;

