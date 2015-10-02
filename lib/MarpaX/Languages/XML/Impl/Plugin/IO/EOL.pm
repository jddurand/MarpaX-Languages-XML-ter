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
  use Throwable::Factory
    EOLException => undef;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               PROCESS => [ 'EOL' ]
                                              };
                                          }
                          );

  my $_impl;

  method BUILD {
    if ($self->xmlVersion eq '1.0') {
      $_impl = \&_impl10;
    } else {
      $_impl = \&_impl11;
    }
  };

  method _impl11(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    return EAT_CLIENT;
  }

  method _impl10(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    return EAT_CLIENT;
  }

  sub P_EOL {
    #
    # Faster like this
    #
    goto &$_impl;
  }

  with 'MooX::Role::Logger';
}

1;

