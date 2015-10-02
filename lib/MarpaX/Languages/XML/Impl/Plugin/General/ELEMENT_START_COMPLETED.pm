use Moops;

# PODCLASSNAME

# ABSTRACT: ELEMENT_START_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::ELEMENT_START_COMPLETED {
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
                                               NOTIFY => [ 'ELEMENT_START_COMPLETED' ]
                                              };
                                          }
                          );

  method N_ELEMENT_START_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Push element context
    #
    my $newContext = MarpaX::Languages::XML::Impl::Context->new(
                                                                grammar          => $parser->get_grammar('element'),
                                                                endEventName     => $parser->get_grammar_endEventName('element')
                                                               );
    $parser->_push_context($newContext);
    #
    # Position is already after ELEMENT_START: push that lexeme in the new context so that we can
    # continue. We disable/enable the ELEMENT_START_COMPLETED to avoid recursivity
    #
    $newContext->recognizer->activate('ELEMENT_START_COMPLETED', 0);
    $newContext->recognizer->lexeme_read('_ELEMENT_START', 0, 1, '<');
    $newContext->recognizer->activate('ELEMENT_START_COMPLETED', 1);
    #
    # We prepare the current context to do as if the element was eat, we are
    # careful to not generate any corresponding event
    #
    if ($context->grammar->xmlns) {
      $context->recognizer->lexeme_read('_NCNAME', 0, 1, 'dummy');
    } else {
      $context->recognizer->lexeme_read('_NAME', 0, 1, 'dummy');
    }
    $context->recognizer->activate('element_COMPLETED', 0);
    $context->recognizer->lexeme_read('_EMPTYELEM_END', 0, 1, '/>');
    $context->recognizer->activate('element_COMPLETED', 1);
    $context->immediateAction(IMMEDIATEACTION_RESUME);

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;


