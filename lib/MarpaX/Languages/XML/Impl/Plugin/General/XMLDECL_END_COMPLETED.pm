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
  use Throwable::Factory
    DeclException => [ qw/$decl/ ];

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
    # the declaration. And there declaration specific rules.
    #
    if ($self->xmlVersion eq '1.1') {
      my $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
      my $decl = substr($MarpaX::Languages::XML::Impl::Parser::buffer, 0, $pos);
      #
      # Okay, I do not understand how this can happen since the grammar will reject these
      # characters.
      #
      if ($decl =~ /[\x{85}\x{2028}]/p) {
        DeclException->throw("Invalid character \\x{" . sprintf('%X', ord(${^MATCH}) . "}"), decl => $decl);
      }
    }
    #
    # Say we are not anymore in a declaration
    #
    $parser->inDecl(false);

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;

