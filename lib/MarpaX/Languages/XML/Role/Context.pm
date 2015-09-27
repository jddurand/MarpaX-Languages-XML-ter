use Moops;

# PODCLASSNAME

# ABSTRACT: Context role

role MarpaX::Languages::XML::Role::Context {

  # VERSION

  # AUTHORITY

  requires 'io';
  requires 'grammar';
  requires 'encoding';
  requires 'recognizer';
  requires 'has_recognizer';
  requires 'pos';
  requires 'line';
  requires 'column';
  requires 'lastLexemes';
  requires 'namespaceSupport';
}

1;
