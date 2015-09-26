use Moops;

# PODCLASSNAME

# ABSTRACT: State role

role MarpaX::Languages::XML::Role::Grammar {

  # VERSION

  # AUTHORITY

  requires 'compiledGrammar';
  requires 'lexemesRegexp';
  requires 'lexemesExclusionsRegexp';
  requires 'xmlVersion';
  requires 'withNamespace';
  requires 'startSymbol';
}

1;
