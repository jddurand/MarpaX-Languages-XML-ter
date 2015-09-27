use Moops;

# PODCLASSNAME

# ABSTRACT: Context role

role MarpaX::Languages::XML::Role::Context {

  # VERSION

  # AUTHORITY

  requires 'io';
  requires 'grammar';
  requires 'dispatcher';
  requires 'encoding';
  requires 'recognizer';
  requires 'line';
  requires 'column';
  requires 'lastLexemes';
  requires 'get_lastLexeme';
  requires 'set_lastLexeme';
  requires 'namespaceSupport';
  requires 'callbackSaidStop';
  requires 'inDeclaration';
}

1;
