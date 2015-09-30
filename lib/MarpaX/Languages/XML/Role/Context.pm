use Moops;

# PODCLASSNAME

# ABSTRACT: Context role

role MarpaX::Languages::XML::Role::Context {

  # VERSION

  # AUTHORITY

  requires 'grammar';
  requires 'endEventName';
  requires 'namespaceSupport';
  requires 'recognizer';
  requires 'line';
  requires 'column';
  requires 'immediateAction';
  requires 'parentContext';
  requires 'restartRecognizer';

}

1;
