use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
  use MarpaX::Languages::XML::Impl::Dispatcher;
  use MarpaX::Languages::XML::Impl::WFC;
  use MarpaX::Languages::XML::Impl::VC;
  use MarpaX::Languages::XML::Role::Parser;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::WFC -all;
  use MarpaX::Languages::XML::Type::VC -all;

  has _wfcInstance => ( is => 'rwp', isa => WFC );
  has _vcInstance  => ( is => 'rwp', isa => VC );

  has dispatcher => ( is => 'ro', isa => Dispatcher,    lazy => 1, builder => 1 );

  has wfc        => ( is => 'ro', isa => ArrayRef[Str], required => 1, trigger => 1 );
  has vc         => ( is => 'ro', isa => ArrayRef[Str], required => 1, trigger => 1 );

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

  method parse() {
  }

  with qw/MarpaX::Languages::XML::Role::Parser/;
}

1;

