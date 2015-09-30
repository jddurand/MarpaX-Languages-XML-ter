use Moops;

# PODCLASSNAME

# ABSTRACT: Context implementation

class MarpaX::Languages::XML::Impl::Context {
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
  use MarpaX::Languages::XML::Role::Context;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::IO -all;
  use MarpaX::Languages::XML::Type::ImmediateAction -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MarpaX::Languages::XML::Type::LastLexemes -all;
  use MarpaX::Languages::XML::Type::NamespaceSupport -all;
  use MooX::HandlesVia;
  use Types::Common::Numeric -all;
  use Throwable::Factory
    IOException    => undef
    ;

  has io               => ( is => 'rw',   isa => IO,                required => 1 );
  has grammar          => ( is => 'rw',   isa => Grammar,           required => 1, trigger => 1 );
  has endEventName     => ( is => 'rw',   isa => Str,               required => 1 );
  has namespaceSupport => ( is => 'rwp',  isa => NamespaceSupport,  required => 1 );
  has recognizer       => ( is => 'rwp',  isa => Recognizer,        init_arg => undef );
  has line             => ( is => 'rw',   isa => PositiveOrZeroInt, default => 1 );
  has column           => ( is => 'rw',   isa => PositiveOrZeroInt, default => 1 );
  has lastLexemes      => ( is => 'rw',   isa => LastLexemes,       default => sub { return [] },
                            handles_via => 'Array',
                            handles => {
                                        get_lastLexeme => 'get',
                                        set_lastLexeme => 'set',
                                       }
                          );
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

  with 'MarpaX::Languages::XML::Role::Context';
}

1;

