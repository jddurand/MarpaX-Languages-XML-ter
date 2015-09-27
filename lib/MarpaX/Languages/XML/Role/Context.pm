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
  requires 'pos';
  requires 'line';
  requires 'column';
  requires 'lastLexemes';
  requires 'namespaceSupport';
  requires 'callbackSaidStop';
}

1;
