use Moops;

# PODCLASSNAME

# ABSTRACT: Context role

role MarpaX::Languages::XML::Role::Context {

  # VERSION

  # AUTHORITY

  requires 'reader';
  requires 'encodingName';
  requires 'readCharsMethod';
  requires 'eof';
  requires 'grammar';
  requires 'endEventName';
  requires 'recognizer';
  requires 'activate';
  requires 'immediateAction';
  requires 'restartRecognizer';

}

1;
