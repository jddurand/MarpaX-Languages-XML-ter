use Moops;

# PODCLASSNAME

# ABSTRACT: STag_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::STag_COMPLETED {
  use MarpaX::Languages::XML::Impl::Context;
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::ImmediateAction -all;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'STag_COMPLETED' ]
                                              };
                                          }
                          );

  method N_STag_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    $parser->_logger->tracef('STag_COMPLETED event, number of remaining context is %d', $parser->count_contexts);
    #
    # Push content context in any case
    #
    my $newContext = MarpaX::Languages::XML::Impl::Context->new(
                                                                io               => $context->io,
                                                                grammar          => $parser->get_grammar('content'),
                                                                encoding         => $context->encoding,
                                                                dispatcher       => $dispatcher,
                                                                namespaceSupport => $context->namespaceSupport,
                                                                endEventName     => $parser->get_grammar_endEventName('content')
                                                               );
    $parser->_push_context($newContext);
    #
    # We are pushing a nullable, this is why it is ok to say stop for a further resume
    #
    $parser->_logger->tracef('STag_COMPLETED event: asking for a stop of %s', $context->grammar->startSymbol);
    $context->immediateAction('IMMEDIATEACTION_PAUSE');

    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

