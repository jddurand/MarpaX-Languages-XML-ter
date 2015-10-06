use Moops;

# PODCLASSNAME

# ABSTRACT: Parser role

role MarpaX::Languages::XML::Role::Parser {

  # VERSION

  # AUTHORITY

  requires 'encodingName';
  requires 'setPosCharBuffer';
  requires 'deltaPosCharBuffer';
  requires 'getCharBuffer';
  requires 'getCharBufferPosition';
  requires 'xmlVersion';
  requires 'xmlns';
  requires 'vc';
  requires 'wfc';
  requires 'blockSize';
  requires 'parseByteStream';
  requires 'parseCharStream';
  requires 'rc';
  requires 'get_grammar';
  requires 'get_grammar_endEventName';
  requires 'count_contexts';
  requires 'push_context';
  requires 'lastLexemes';
  requires 'get_lastLexeme';
  requires 'set_lastLexeme';
  requires 'saxHandler';
  requires 'get_saxHandle';
  requires 'exists_saxHandle';
  requires 'namespaceSupport';
  requires 'line';
  requires 'column';
  requires 'inDecl';
  requires 'throw';
  requires 'redoLineAndColumnNumbers';
  requires 'entities';
  requires 'exists_entity';
  requires 'get_entity';

}

1;
