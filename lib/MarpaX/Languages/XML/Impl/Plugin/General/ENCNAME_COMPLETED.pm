use Moops;

# PODCLASSNAME

# ABSTRACT: ENCNAME_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::ENCNAME_COMPLETED {
  use Encode qw/encode/;
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
                                               NOTIFY => [ 'ENCNAME_COMPLETED' ]
                                              };
                                          }
                          );

  my $encnameId;

  method DEMOLISH {
    undef $encnameId;
  }

  method N_ENCNAME_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Get declared encoding
    # This has a cost but happens only once
    #
    $encnameId //= $context->grammar->compiledGrammar->symbol_by_name_hash->{'_ENCNAME'};
    my $encname = $parser->get_lastLexeme($encnameId);
    #
    # _ENCNAME matches only ASCII characters, so uc() is ok
    #
    if (uc($encname) ne $parser->encodingName) {
      $self->_logger->tracef('XML says encoding %s while IO is currently using %s', $encname, $parser->encodingName);
      #
      # Check this is a supported encoding trying on a fake string that can never fail
      #
      try {
        my $string = 'abcd';
        my $octets  = encode($encname, $string, Encode::FB_CROAK);
        $self->_logger->tracef('Encoding %s is a supported name', $encname);
      } catch {
        $parser->throw('Parse', $context, "Encoding $encname verification failure: $_");
      };
      #
      # Inform parser. The grammar does not change. Just the encoding.
      #
      $parser->encodingName($encname);
      #
      # Make sure we restart from the beginning
      # Please note that per def $parser->inDecl is false at this stage.
      # This mean that the char buffer is guaranteed to never have been
      # reduced -;
      #
      $parser->setPosCharBuffer(0);
      #
      # And replay
      #
      $context->restartRecognizer;
      $context->immediateAction(IMMEDIATEACTION_RETURN);
    } else {
      $self->_logger->tracef('XML and IO agree with encoding %s', $encname);
    }

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;

