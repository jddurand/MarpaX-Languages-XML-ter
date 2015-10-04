use Moops;

# ABSTRACT: Exception role

# VERSION

# AUTHORITY

role MarpaX::Languages::XML::Role::Exception {
  use Data::Hexdumper qw/hexdump/;

  requires 'parser';
  requires 'context';

  around stringify {

    my $string = $self->${^NEXT}(@_);
    #
    # In any case, we remove EOLs in message
    #
    $string =~ s/\s*\z//;
    #
    # All the rest is subject to $ENV{XML_DEBUG}
    # ------------------------------------------
    my $xmlDebug = $ENV{XML_DEBUG} || 0;
    return $string if (! $xmlDebug);
    #
    # Get recognizer;
    #
    my $recognizer = $self->context->recognizer;
    #
    # Add grammar progress
    # --------------------
    $string .= "\n"
      . "Grammar progress:\n"
      . "-----------------\n"
      . $recognizer->show_progress;
    #
    # Add expected terminals
    # ----------------------
    $string .= "\n"
      . "Terminals expected:\n"
      . "-------------------\n"
      . join(', ', @{$recognizer->terminals_expected}) . "\n";
    #
    # Add data dump before and after
    # ------------------------------
    my $dataBefore = '';
    my $dataAfter = '';
    my $pos = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
    if ($pos > 0) {
      my $previous_pos = ($pos >= 48) ? $pos - 48 : 0;
      $dataBefore = hexdump(data => $MarpaX::Languages::XML::Impl::Parser::buffer,
                            start_position    => $previous_pos,
                            end_position      => $pos - 1,
                            suppress_warnings => 1,
                            space_as_space    => 1
                           );
    }
    $dataAfter = hexdump(data => $MarpaX::Languages::XML::Impl::Parser::buffer,
                         start_position    => $pos,
                         end_position      => (($pos + 47) <= $length) ? $pos + 47 : $length,
                         suppress_warnings => 1,
                         space_as_space    => 1
                        );
    #
    # Data::HexDumper is a great module, except there is no option
    # to ignore 0x00, which is an impossible character in XML.
    #
    if (length($dataBefore) > 0) {
      my $nbzeroes = ($dataBefore =~ s/( 00)(?= (?::|00))/   /g);
      if ($nbzeroes) {
        $dataBefore =~ s/\.{$nbzeroes}$//;
      }
    }
    if (length($dataAfter) > 0) {
      my $nbzeroes = ($dataAfter =~ s/( 00)(?= (?::|00))/   /g);
      if ($nbzeroes) {
        $dataAfter =~ s/\.{$nbzeroes}$//;
      }
    }
    if (length($dataBefore) > 0) {
      $string .= "\n"
        . "Characters around the error:\n"
        . "----------------------------\n"
        . $dataBefore
        . "  <error>\n"
        . $dataAfter;
    }
    $string .= "\n"
      . "Characters just after the error:\n"
      . "--------------------------------\n"
      . $dataAfter;

    return $string;
  }
}

1;
