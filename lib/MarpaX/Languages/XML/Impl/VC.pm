use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint implementation

class MarpaX::Languages::XML::Impl::VC {
  use MarpaX::Languages::XML::Impl::PluginsRegister;
  use MarpaX::Languages::XML::Role::VC;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MooX::HandlesVia;

  #
  # Singleton
  #
  my $pluginsRegister = MarpaX::Languages::XML::Impl::PluginsRegister->instance;

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
    return $pluginsRegister->pluginsRegister(__PACKAGE__, $self->dispatcher, $self->elements_vc);
  }

  with 'MarpaX::Languages::XML::Role::VC';
}

1;

