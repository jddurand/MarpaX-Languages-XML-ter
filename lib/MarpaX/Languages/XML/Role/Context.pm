use Moops;

# PODCLASSNAME

# ABSTRACT: Context role

role MarpaX::Languages::XML::Role::Context {

  # VERSION

  # AUTHORITY

  requires 'grammar';
  requires 'set_grammar';
  requires 'endEventName';
  requires 'set_endEventName';
  requires 'recognizer';
  requires 'immediateAction';
  requires 'restartRecognizer';

}

1;
