use Moops;

# PODCLASSNAME

# ABSTRACT: XMLDECL_END_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::XMLDECL_END_COMPLETED {
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
                                               NOTIFY => [ 'XMLDECL_END_COMPLETED' ]
                                              };
                                          }
                          );

  method N_XMLDECL_END_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # We guaranteed that the buffer was not reduced. Therefore, from positions 0 up to pos(), this is
    # the declaration. And there is a declaration specific rule.
    # Please note that EOL handling was paused until this event.
    #
    # The test on x#85 and x#2028 characters is INDEPENDANT of the xml version because we
    # allow them in both grammars: in the declaration we do not know yet the final version.
    # XML 1.0 grammar reject them in its space definition
    # XML 1.0 grammar accept them in its space definition, except in the declaration
    # Therefore it is ok to do this test systematically at the end of declaration, regardless
    # of the XML grammar version.
    #
    # Even if the user gave a hint on the xml version.
    #
    my $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $decl = substr($MarpaX::Languages::XML::Impl::Parser::buffer, 0, $pos);
    #
    # EOL handling was suspended until $parser->inDecl is true.
    #
    if ($decl =~ /([\x{85}\x{2028}])/p) {
      #
      # We will be smart enough to reposition exactly where it fails
      #
      pos($MarpaX::Languages::XML::Impl::Parser::buffer) = $-[1];
      $parser->redoLineAndColumnNumbers();
      $parser->throw('Parse', $context, "Invalid character \\x{" . sprintf('%X', ord(${^MATCH})) . "} in declaration");
    }
    #
    # Ask for at least one char more to trigger EOL handling and
    # for the buffer to be reduced if possible.
    # The parser will do these things in this order.
    #
    $context->immediateAction(IMMEDIATEACTION_READONECHAR|IMMEDIATEACTION_REDUCE);
    #
    # Say we are not anymore in a decl context
    #
    $parser->inDecl(false);

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;

