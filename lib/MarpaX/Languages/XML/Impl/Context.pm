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
  use MarpaX::Languages::XML::Type::Reader -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MooX::Role::Logger;
  use MooX::HandlesVia;
  use Types::Common::Numeric -all;

  has reader          => ( is => 'ro',  isa => Reader,            required => 1 );
  has encodingName    => ( is => 'ro',  isa => Str|Undef,         required => 1 );
  has readCharsMethod => ( is => 'ro',  isa => CodeRef,           required => 1 );
  has eof             => ( is => 'rw',  isa => Bool,              default => false );
  has grammar         => ( is => 'rw',  isa => Grammar,           required => 1, trigger => 1);
  has endEventName    => ( is => 'rw',  isa => Str,               required => 1);
  has recognizer      => ( is => 'rwp', isa => Recognizer,        init_arg => undef );
  has immediateAction => ( is => 'rw',  isa => ImmediateAction,   default => IMMEDIATEACTION_NONE );

  method _startRecognizer(Grammar $grammar --> Undef) {
    my $recognizer = Marpa::R2::Scanless::R->new({grammar => $grammar->compiledGrammar});
    $recognizer->read(\'  ');
    $self->_set_recognizer($recognizer);
    return;
  }

  method _trigger_grammar(Grammar $grammar --> Undef) {
    return $self->_startRecognizer($grammar);
    return;
  }

  method restartRecognizer( --> Context) {
    #
    # I should understand series_restart() OOTD
    #
    $self->_startRecognizer($self->grammar);
    return $self;
  }

  method activate(Str $eventName, Bool $value --> Context) {
    my $onOff = $value ? 1 : 0;
    $self->_logger->tracef('Setting event %s to %d', $eventName, $onOff);
    $self->recognizer->activate($eventName, $onOff);
    return $self;
  }

  with 'MarpaX::Languages::XML::Role::Context';
  with 'MooX::Role::Logger';
}

1;

