use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint implementation

class MarpaX::Languages::XML::Impl::VC {
  use MarpaX::Languages::XML::Role::PluginFactory;
  use MarpaX::Languages::XML::Role::VC;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MooX::HandlesVia;

  has dispatcher => (
                     is => 'ro',
                     isa => Dispatcher,
                     required => 1
                    );

  has vc => (
              is => 'ro',
              isa => ArrayRef[Str],
              handles_via => 'Array',
              handles => {
                          'elements_vc' => 'elements'
                         },
              required => 1,
              trigger => 1,
             );

  method _trigger_vc(ArrayRef[Str] $vc  --> Undef) {
    return $self->pluginsAdd(__PACKAGE__, $self->dispatcher, $self->elements_vc);
  }

  with 'MarpaX::Languages::XML::Role::PluginFactory';
  with 'MarpaX::Languages::XML::Role::VC';
}

1;

