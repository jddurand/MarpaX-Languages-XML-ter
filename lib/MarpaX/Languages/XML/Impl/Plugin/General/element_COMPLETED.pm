use Moops;

# PODCLASSNAME

# ABSTRACT: element_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::element_COMPLETED {
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
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
                                               NOTIFY => [ 'element_COMPLETED' ]
                                              };
                                          }
                          );

  method N_element_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Immediate stop for this context
    #
    $context->immediateAction(IMMEDIATEACTION_POP_CONTEXT|IMMEDIATEACTION_RETURN);

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;

