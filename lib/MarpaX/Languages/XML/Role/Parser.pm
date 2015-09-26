use Moops;

# PODCLASSNAME

# ABSTRACT: Parser role

role MarpaX::Languages::XML::Role::Parser {
  # VERSION

  # AUTHORITY

  requires 'xmlVersion';
  requires 'withNamespace';
  requires 'vc';
  requires 'wfc';
  requires 'dispatcher';
  requires 'parse';
}

1;
