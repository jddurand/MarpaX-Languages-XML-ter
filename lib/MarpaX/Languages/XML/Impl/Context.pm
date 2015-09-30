use Moops;

# PODCLASSNAME

# ABSTRACT: Context implementation

class MarpaX::Languages::XML::Impl::Context {
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
  use MarpaX::Languages::XML::Role::Context;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::ImmediateAction -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MarpaX::Languages::XML::Type::NamespaceSupport -all;
  use MooX::HandlesVia;
  use Types::Common::Numeric -all;

  has grammar          => ( is => 'rwp',  isa => Grammar,           required => 1, trigger => 1 );
  has endEventName     => ( is => 'rwp',  isa => Str,               required => 1 );
  has namespaceSupport => ( is => 'rwp',  isa => NamespaceSupport,  required => 1 );
  has recognizer       => ( is => 'rwp',  isa => Recognizer,        init_arg => undef );
  has line             => ( is => 'rw',   isa => PositiveOrZeroInt, default => 1 );
  has column           => ( is => 'rw',   isa => PositiveOrZeroInt, default => 1 );
  has immediateAction => ( is => 'rw', isa => ImmediateAction, default => IMMEDIATEACTION_NONE );
  has parentContext   => ( is => 'rw', isa => Context|Undef, default => undef );

  method DEMOLISH {
    my $parentContext = $self->parentContext;
    if (Context->check($parentContext)) {
      #
      # Transfer line and column information into parent
      #
      $parentContext->line($self->line);
      $parentContext->column($self->column);
    }
  }

  method _trigger_grammar(Grammar $grammar --> Undef) {
    #
    # And create a recognizer
    #
    my $recognizer = Marpa::R2::Scanless::R->new({grammar => $grammar->compiledGrammar});
    $recognizer->read(\'  ');
    $self->_set_recognizer($recognizer);

    return;
  }

  method restartRecognizer( --> Context) {
    #
    # I should understand series_restart() OOTD
    #
    $self->_set_grammar($self->grammar);
  }

  with 'MarpaX::Languages::XML::Role::Context';
}

1;

