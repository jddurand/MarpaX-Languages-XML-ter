use Moops;

# PODCLASSNAME

# ABSTRACT: End-of-line plugin implementation

class MarpaX::Languages::XML::Impl::Plugin::IO::EOL :assertions {
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               PROCESS => [ 'EOL' ]
                                              };
                                          }
                          );

  method P_EOL(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    $self->_logger->tracef('P_EOL');
    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

