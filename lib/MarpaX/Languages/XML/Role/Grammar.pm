use Moops;

# PODCLASSNAME

# ABSTRACT: Grammar role

role MarpaX::Languages::XML::Role::Grammar {

  # VERSION

  # AUTHORITY

  requires 'compiledGrammar';

  requires 'lexemesRegexp';
  requires 'exists_lexemesRegexp';
  requires 'get_lexemesRegexp';

  requires 'lexemesRegexpBySymbolId';
  requires 'elements_lexemesRegexpBySymbolId';

  requires 'lexemesMinlength';
  requires 'exists_lexemesMinlength';
  requires 'get_lexemesMinlength';

  requires 'lexemesMinlengthBySymbolId';
  requires 'elements_lexemesMinlengthBySymbolId';

  requires 'lexemesExclusionsRegexp';
  requires 'exists_lexemesExclusionsRegexp';
  requires 'get_lexemesExclusionsRegexp';

  requires 'lexemesExclusionsRegexpBySymbolId';
  requires 'elements_lexemesExclusionsRegexpBySymbolId';

  requires 'xmlVersion';
  requires 'xmlns';
  requires 'startSymbol';
  requires 'events';
}

1;
