use Moops;

# PODCLASSNAME

# ABSTRACT: PluginFactory constraint implementation

class MarpaX::Languages::XML::Impl::PluginFactory {
  use File::Basename;
  use File::Spec;
  use File::Find;
  use MarpaX::Languages::XML::Role::PluginFactory;
  use Module::Path qw/module_path/;
  use MooX::HandlesVia;
  use MooX::Role::Logger;
  use Try::Tiny;
  use Types::Standard -all;

  has fromModule           => ( is => 'ro', isa => Str, default => sub { caller() } );
  has relativePathPatterns => ( is => 'ro', isa => ArrayRef[RegexpRef|Str], default => sub { [ qw/^Plugin::.+\.pm\z/ ] },
                                handles_via => 'Array',
                                handles     => {
                                                'elements_relativePathPatterns' => 'elements'
                                               }
                              );
  has findOptions          => ( is => 'ro', isa => HashRef, default => sub { { no_chdir => 1 } } );

  method require_plugins (--> ArrayRef[Str]) {
    my $modulePath = module_path($self->fromModule);
    if (Undef->check($modulePath)) {
      $self->_logger->warnf('Module %s not found', $self->fromModule);
      return [];
    }
    my ($filename, $dirs, $suffix) = fileparse($modulePath, qr/\.[^.]*/);
    #
    # We assume that module's filename (without a suffix) is also a directory
    #
    my $fromDir = File::Spec->catdir($dirs, $filename);
    return if (! -d $fromDir);
    #
    # Scan the directory
    #
    my @loaded = ();
    find(sub {
           my $fullPath = File::Spec->canonpath($File::Find::name);
           return if (! -e $fullPath || -d _ || -b _);
           try {
             require $fullPath;
             $self->_logger->debugf('%s: %s', $fullPath, 'require ok');
             push(@loaded, $fullPath);
           } catch {
             $self->_logger->debugf('%s: %s', $fullPath, 'require ko');
             $self->_logger->tracef('%s: %s', $fullPath, $_);
           };
         },  $fromDir);
    return \@loaded;
  }

  with qw/MarpaX::Languages::XML::Role::PluginFactory
          MooX::Role::Logger/;
}

1;

