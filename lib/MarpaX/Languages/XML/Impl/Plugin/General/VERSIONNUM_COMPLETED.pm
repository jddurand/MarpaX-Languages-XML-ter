use Moops;

# PODCLASSNAME

# ABSTRACT: VERSIONNUM_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::VERSIONNUM_COMPLETED {
  use MarpaX::Languages::XML::Impl::Context;
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
                                               NOTIFY => [ 'VERSIONNUM_COMPLETED' ]
                                              };
                                          }
                          );

  my $versionnumId;

  method DEMOLISH {
    undef $versionnumId;
  }

  method N_VERSIONNUM_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Get declared version number
    # This has a cost but happens only once.
    #
    $versionnumId //= $context->grammar->compiledGrammar->symbol_by_name_hash->{'_VERSIONNUM'};
    my $versionnum = $parser->get_lastLexeme($versionnumId);
    if ($versionnum ne $context->grammar->xmlVersion) {
      $self->_logger->tracef('XML says version number %s while grammar is currently using %s', $versionnum, $context->grammar->xmlVersion);
      #
      # Inform parser. Look to its xmlVersion implementation, this will call clearers.
      #
      $parser->xmlVersion($versionnum);
      #
      # Make sure we restart from the beginning
      # Please note that per def $parser->inDecl is false at this stage.
      # This mean that the char buffer is guaranteed to never have been
      # reduced -;
      #
      $parser->setPosCharBuffer(0);
      #
      # Replace context elements (this will automatically restart the recognizer)
      #
      $context->grammar($parser->get_grammar($context->grammar->startSymbol));
      $context->endEventName($parser->get_grammar_endEventName($context->grammar->startSymbol));
      #
      # And replay
      #
      $context->immediateAction(IMMEDIATEACTION_RETURN);
    } else {
      $self->_logger->tracef('XML and Grammar agree with version number %s', $versionnum);
    }

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;

