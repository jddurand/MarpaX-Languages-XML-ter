use Moops;

# PODCLASSNAME

# ABSTRACT: Context implementation

class MarpaX::Languages::XML::Impl::Context {
  use Marpa::R2;
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
  use MarpaX::Languages::XML::Marpa::R2::Hooks;
  use MarpaX::Languages::XML::Role::Context;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::ImmediateAction -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MooX::HandlesVia;
  use Types::Common::Numeric -all;

  has grammar         => ( is => 'rwp', isa => Grammar,           required => 1, trigger => 1 );
  has endEventName    => ( is => 'ro',  isa => Str,               required => 1 );
  has recognizer      => ( is => 'rwp', isa => Recognizer,        init_arg => undef );
  has immediateAction => ( is => 'rw',  isa => ImmediateAction,   default => IMMEDIATEACTION_NONE );

  method _startRecognizer(Grammar $grammar --> Undef) {
    my $recognizer = Marpa::R2::Scanless::R->new({grammar => $grammar->compiledGrammar});
    $recognizer->read(\'  ');
    $self->_set_recognizer($recognizer);
  }

  method _trigger_grammar(Grammar $grammar --> Undef) {
    return $self->_startRecognizer($grammar);
  }

  method restartRecognizer( --> Context) {
    #
    # I should understand series_restart() OOTD
    #
    return $self->_startRecognizer($self->grammar);
  }

  with 'MarpaX::Languages::XML::Role::Context';
}

1;

