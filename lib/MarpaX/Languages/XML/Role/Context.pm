use Moops;

# PODCLASSNAME

# ABSTRACT: Context role

role MarpaX::Languages::XML::Role::Context {

  # VERSION

  # AUTHORITY

  requires 'io';
  requires 'grammar';
  requires 'dispatcher';
  requires 'endEventName';
  requires 'namespaceSupport';
  requires 'eolHandling';
  requires 'encoding';
  requires 'recognizer';
  requires 'line';
  requires 'column';
  requires 'lastLexemes';
  requires 'get_lastLexeme';
  requires 'set_lastLexeme';
  requires 'previousCanStop';
  requires 'immediatePause';

}

1;
