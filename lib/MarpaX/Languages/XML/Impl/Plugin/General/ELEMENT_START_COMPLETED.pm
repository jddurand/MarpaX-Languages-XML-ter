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

  my $_NAME_LEXEME_NAME;

  method BUILD {
    $_NAME_LEXEME_NAME = $self->xmlns ? '_NCNAME' : '_NAME';
  };

  method N_ELEMENT_START_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # If this is the root element, no need anymore for these events:
    #
    if ($parser->count_contexts == 1) {
      $context->activate('ENCNAME_COMPLETED', 0);
      $context->activate('XMLDECL_END_COMPLETED', 0);
      $context->activate('VERSIONNUM_COMPLETED', 0);
    }
    #
    # Push element context
    #
    my $newContext = MarpaX::Languages::XML::Impl::Context->new(
                                                                reader          => $context->reader,
                                                                encodingName    => $context->encodingName,
                                                                readCharsMethod => $context->readCharsMethod,
                                                                grammar         => $parser->get_grammar('element'),
                                                                endEventName    => $parser->get_grammar_endEventName('element')
                                                               );
    $self->_logger->tracef('ELEMENT_START_COMPLETED : push element context');
    $parser->push_context($newContext);
    #
    # Position is already after ELEMENT_START: push that lexeme in the new context so that we can
    # continue. We disable/enable the ELEMENT_START_COMPLETED to avoid recursivity
    #
    $newContext->activate('ELEMENT_START_COMPLETED', 0);
    $newContext->recognizer->lexeme_read('_ELEMENT_START', 0, 1);
    $newContext->activate('ELEMENT_START_COMPLETED', 1);
    #
    # We prepare the current context to do as if the element was eat, we are
    # careful to not generate any corresponding event
    #
    $context->recognizer->lexeme_read($_NAME_LEXEME_NAME, 0, 1);
    $context->activate('element_COMPLETED', 0);
    $context->recognizer->lexeme_read('_EMPTYELEM_END', 0, 1);
    $context->activate('element_COMPLETED', 1);
    #
    # Next time with this context, we do not want to pile-up again an element context:
    # We say it is has to return, but is not popped up because it will have to resume
    # when the lement we just piled up will be overt. But it will not have to say it
    # needs again an element context -;
    #
    $context->immediateAction(IMMEDIATEACTION_MARK_EVENTS_DONE|IMMEDIATEACTION_RETURN);

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;


