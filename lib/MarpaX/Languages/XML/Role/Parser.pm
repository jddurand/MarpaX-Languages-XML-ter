use Moops;

# PODCLASSNAME

# ABSTRACT: Parser role

role MarpaX::Languages::XML::Role::Parser {
  # VERSION

  # AUTHORITY

  requires 'xmlVersion';
  requires 'xmlns';
  requires 'vc';
  requires 'wfc';
  requires 'blockSize';
  requires 'parse';
  requires 'rc';
}

1;
