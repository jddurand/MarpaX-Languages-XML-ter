use Moops;

# PODCLASSNAME

# ABSTRACT: Context role

role MarpaX::Languages::XML::Role::Context {

  # VERSION

  # AUTHORITY

  requires 'grammar';
  requires 'endEventName';
  requires 'recognizer';
  requires 'immediateAction';
  requires 'restartRecognizer';

}

1;
