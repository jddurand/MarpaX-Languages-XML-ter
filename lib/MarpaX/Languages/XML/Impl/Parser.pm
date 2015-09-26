use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
  use MarpaX::Languages::XML::Impl::Grammar;
  use MarpaX::Languages::XML::Impl::Dispatcher;
  use MarpaX::Languages::XML::Impl::WFC;
  use MarpaX::Languages::XML::Impl::VC;
  use MarpaX::Languages::XML::Role::Parser;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Type::WithNamespace -all;
  use MarpaX::Languages::XML::Type::WFC -all;
  use MarpaX::Languages::XML::Type::VC -all;

  has xmlVersion    => ( is => 'ro', isa => XmlVersion,    default => '1.0' );
  has withNamespace => ( is => 'ro', isa => WithNamespace, default => false );
  has vc            => ( is => 'ro', isa => ArrayRef[Str], required => 1, trigger => 1 );
  has wfc           => ( is => 'ro', isa => ArrayRef[Str], required => 1, trigger => 1 );
  has dispatcher    => ( is => 'ro', isa => Dispatcher,    lazy => 1, builder => 1 );

  has _wfcInstance => ( is => 'rwp', isa => WFC );
  has _vcInstance  => ( is => 'rwp', isa => VC );
  has _grammar     => ( is => 'rwp', isa => Grammar, lazy => 1, builder => 1 );

  method _build_dispatcher( --> Dispatcher )  {
    return MarpaX::Languages::XML::Impl::Dispatcher->new();
  }

  method _trigger_wfc(ArrayRef[Str] $wfc --> Undef) {
    my $wfcInstance = MarpaX::Languages::XML::Impl::WFC->new(dispatcher => $self->dispatcher, wfc => $wfc);
    $self->_set__wfcInstance($wfcInstance);
    return;
  }

  method _trigger_vc(ArrayRef[Str] $vc --> Undef) {
    my $vcInstance = MarpaX::Languages::XML::Impl::VC->new(dispatcher => $self->dispatcher, vc => $vc);
    $self->_set__vcInstance($vcInstance);
    return;
  }

  method _build__grammar( --> Grammar) {
    return MarpaX::Languages::XML::Impl::Grammar->new(
                                                      xmlVersion => $self->xmlVersion,
                                                      withNamespace => $self->withNamespace
                                                     );
  }

  method parse() {
    my $compiledGrammar = $self->_grammar->compiledGrammar;
  }

  with qw/MarpaX::Languages::XML::Role::Parser/;
}

1;

