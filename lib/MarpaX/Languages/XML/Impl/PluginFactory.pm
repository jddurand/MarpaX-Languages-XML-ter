use Moops;

# PODCLASSNAME

# ABSTRACT: PluginFactory constraint implementation

class MarpaX::Languages::XML::Impl::PluginFactory {
  use File::Basename;
  use File::Spec;
  use File::Find;
  use MarpaX::Languages::XML::Role::PluginFactory;
  use Module::Path qw/module_path/;
  use Module::Runtime qw/use_package_optimistically/;
  use MooX::HandlesVia;
  use MooX::Role::Logger;
  use Types::Common::String -all;

  has fromModule     => ( is => 'ro', isa => Str, default => sub { caller() } );
  has modulePatterns => ( is => 'ro', isa => ArrayRef[RegexpRef|Str], default => sub { [ qw/\bPlugin\b/ ] },
                          handles_via => 'Array',
                          handles     => {
                                          'elements_modulePatterns' => 'elements'
                                         }
                        );
  has findOptions    => ( is => 'ro', isa => HashRef, default => sub { { no_chdir => 1 } } );

  method require_plugins (--> ArrayRef[Str]) {
    my $modulePath = module_path($self->fromModule);
    if (Undef->check($modulePath)) {
      $self->_logger->warnf('Module %s not found', $self->fromModule);
      return [];
    }
    my ($moduleFilenameWithoutSuffix, $moduleDirs, $moduleSuffix) = fileparse($modulePath, qr/\.[^.]*/);
    #
    # We assume that module's filename (without a suffix) is also a directory
    #
    my $fromDir = File::Spec->catdir($moduleDirs, $moduleFilenameWithoutSuffix);
    if (! -d $fromDir) {
      $self->_logger->tracef('%s: %s', $fromDir, $!);
      return [];
    }
    #
    # Scan the directory
    #
    $self->_logger->tracef('Scanning %s', $fromDir);
    my @loaded = ();
    find(sub {
           my $fullPath = File::Spec->canonpath($File::Find::name);
           return if (! -e $fullPath || -d _ || -b _);

           my $relativePath = File::Spec->abs2rel($fullPath, $fromDir);
           my ($relatileFilenameWithoutSuffix, $relativeDirs, $relativeSuffix) = fileparse($relativePath, qr/\.[^.]*/);
           my @relativeDirs = grep { NonEmptySimpleStr->check($_) } File::Spec->splitdir($relativeDirs);
           my $moduleName = join('::', $self->fromModule, @relativeDirs, $relatileFilenameWithoutSuffix);

           $self->_logger->tracef('%s ?', $moduleName);
           return if (! grep {$moduleName =~ $_} $self->elements_modulePatterns);

           my $gotModule = use_package_optimistically($moduleName);
           if (! $gotModule) {
             $self->_logger->tracef('%s: %s', $moduleName, 'use_package_optimistically failure');
           } else {
             $self->_logger->tracef('%s: %s => %s', $moduleName, 'use_package_optimistically success', $gotModule);
             push(@loaded, $moduleName);
           }
         },  $fromDir);
    return \@loaded;
  }

  with qw/MarpaX::Languages::XML::Role::PluginFactory
          MooX::Role::Logger/;
}

1;

