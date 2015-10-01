use Moops;

# PODCLASSNAME

# ABSTRACT: end_document Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::end_document {
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
                                               NOTIFY => [ 'end_document' ]
                                              };
                                          }
                          );

  method N_end_document(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    if ($parser->exists_saxHandle('end_document')) {
      my $codeRef = $parser->get_saxHandle('end_document');
      $self->$codeRef;
    }

    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

