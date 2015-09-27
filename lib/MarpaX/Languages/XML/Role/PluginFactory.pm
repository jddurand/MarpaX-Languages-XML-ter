use Moops;

# PODCLASSNAME

# ABSTRACT: PluginFactory role

role MarpaX::Languages::XML::Role::PluginFactory {

  # VERSION

  # AUTHORITY

  requires 'listAllPlugins';
  requires 'registerPlugins';

}

1;
