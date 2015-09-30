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
  requires 'startSymbol';
  requires 'get_grammar';
  requires 'get_grammar_endEventName';
  requires 'count_contexts';
  requires 'get_context';
  requires 'read';
  requires 'eof';
  requires 'eolHandling';
}

1;
