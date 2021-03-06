use Moops;

# PODCLASSNAME

# ABSTRACT: Encoding implementation

class MarpaX::Languages::XML::Impl::Encoding {
  use Config;
  use Encode qw/encode decode/;
  use Encode::Guess;
  use MarpaX::Languages::XML::Role::Encoding;
  use MarpaX::Languages::XML::Type::Encoding -all;
  use Throwable::Factory
    GuessException    => undef
    ;
  use MooX::HandlesVia;
  use Types::Common::Numeric -all;

  #
  # Largest possible notion of S before EOL handling [#x20|#x9|#xD|#xA|x#85|x#2028]
  # regardless of the xml version (the parser will croak if it see x#85 or x#2028
  # and xml version is 1.0). We use the Unicode Replacement Character U+FFFD as
  # well so that the guess will not stop
  #
  # Now some words on x#85 or x#2028 error reporting: we make sure that in both
  # XML 1.0 and 1.1 grammars these characters are accepted, regardless of the
  # final version. See S_START rule.
  #
  # The following is S_START plus the Unicode Replacement Character.
  #
  our $S = qr/[\x{20}\x{9}\x{D}\x{A}\x{85}\x{2028}\x{FFFD}]++/;

  # VERSION

  # AUTHORITY

  has value     => ( is => 'rwp', isa => Str);
  has bytes     => ( is => 'ro',  isa => Str, required => 1, trigger => 1);

  has _bom      => ( is => 'rw',  isa => Str, handles_via => 'String', handles => { _length__bom  => 'length' } );
  has _guess    => ( is => 'rw',  isa => Str, handles_via => 'String', handles => { _length__guess => 'length' } );
  has _bom_size => ( is => 'rw',  isa => PositiveOrZeroInt);

  method byteStart( --> PositiveOrZeroInt) {
    return $self->_bom_size;
  }

  method _trigger_bytes(Str $bytes --> Undef) {
    my $value = $self->_bom_from_bytes($bytes) || $self->_guess_from_bytes($bytes);
    if (length($value) <= 0) {
      $self->_logger->debugf('Assuming relaxed (perl) UTF8 encoding');
      $value = 'UTF8';
    }
    $self->_set_value($value);
    return;
  }

  method _bom_from_bytes(Str $bytes --> Str) {

    $self->_bom('');
    $self->_bom_size(0);
    return '' if (length($bytes) <= 0);

    #
    # 5 bytes
    #
    if ($bytes =~ m/^\x{2B}\x{2F}\x{76}\x{38}\x{2D}/) { # If no following character is encoded, 38 is used for the fourth byte and the following byte is 2D
      $self->_bom('UTF-7');
      $self->_bom_size(5);
    }
    #
    # 4 bytes
    #
    elsif ($bytes =~ m/^(?:\x{2B}\x{2F}\x{76}\x{38}|\x{2B}\x{2F}\x{76}\x{39}|\x{2B}\x{2F}\x{76}\x{2B}|\x{2B}\x{2F}\x{76}\x{2F})/s) { # 3 bytes + all possible values of the 4th byte
      $self->_bom('UTF-7');
      $self->_bom_size(4);
    }
    elsif ($bytes =~ m/^(?:\x{00}\x{00}\x{FF}\x{FE}|\x{FE}\x{FF}\x{00}\x{00})/s) { # UCS-4, unusual octet order (2143 or 3412)
      $self->_bom('UCS-4');
      $self->_bom_size(4);
    }
    elsif ($bytes =~ m/^\x{00}\x{00}\x{FE}\x{FF}/s) { # UCS-4, big-endian machine (1234 order)
      $self->_bom('UTF-32BE');
      $self->_bom_size(4);
    }
    elsif ($bytes =~ m/^\x{FF}\x{FE}\x{00}\x{00}/s) { # UCS-4, little-endian machine (4321 order)
      $self->_bom('UTF-32LE');
      $self->_bom_size(4);
    }
    elsif ($bytes =~ m/^\x{DD}\x{73}\x{66}\x{73}/s) {
      $self->_bom('UTF-EBCDIC');
      $self->_bom_size(4);
    }
    elsif ($bytes =~ m/^\x{84}\x{31}\x{95}\x{33}/s) {
      $self->_bom('GB-18030');
      $self->_bom_size(4);
    }
    #
    # 3 bytes
    #
    elsif ($bytes =~ m/^\x{EF}\x{BB}\x{BF}/s) { # UTF-8
      $self->_bom('UTF-8');
      $self->_bom_size(3);
    }
    elsif ($bytes =~ m/^\x{F7}\x{64}\x{4C}/s) {
      $self->_bom('UTF-1');
      $self->_bom_size(3);
    }
    elsif ($bytes =~ m/^\x{0E}\x{FE}\x{FF}/s) { # Signature recommended in UTR #6
      $self->_bom('SCSU');
      $self->_bom_size(3);
    }
    elsif ($bytes =~ m/^\x{FB}\x{EE}\x{28}/s) {
      $self->_bom('BOCU-1');
      $self->_bom_size(3);
    }
    #
    # 2 bytes
    #
    elsif ($bytes =~ m/^\x{FE}\x{FF}/s) { # UTF-16, big-endian
      $self->_bom('UTF-16BE');
      $self->_bom_size(2);
    }
    elsif ($bytes =~ m/^\x{FF}\x{FE}/s) { # UTF-16, little-endian
      $self->_bom('UTF-16LE');
      $self->_bom_size(2);
    }

    if ($self->_length__bom > 0) {
      $self->_logger->debugf('BOM says encoding is "%s" using %d bytes', $self->bom, $self->bom_size);
    } else {
      $self->_logger->debugf('No encoding information from BOM');
    }

    return $self->_bom;
  }

  method _guess_from_bytes(Str $bytes --> Str) {
    #
    # Do ourself common guesses
    #
    $self->_guess('');
    return '' if (length($bytes) <= 0);

    if ($bytes =~ /^\x{00}\x{00}\x{00}\x{3C}/) { # '<' in UTF-32BE
      $self->_guess('UTF-32BE');
    }
    elsif ($bytes =~ /^\x{3C}\x{00}\x{00}\x{00}/) { # '<' in UTF-32LE
      $self->_guess('UTF-32LE');
    }
    elsif ($bytes =~ /^\x{00}\x{3C}\x{00}\x{3F}/) { # '<?' in UTF-16BE
      $self->_guess('UTF-16BE');
    }
    elsif ($bytes =~ /^\x{3C}\x{00}\x{3F}\x{00}/) { # '<?' in UTF-16LE
      $self->_guess('UTF-16LE');
    }
    elsif ($bytes =~ /^\x{3C}\x{3F}\x{78}\x{6D}/) { # '<?xml' in US-ASCII
      $self->_guess('ASCII');
    }

    if ($self->_length__guess <= 0) {
      my $is_ebcdic = $Config{'ebcdic'} || '';
      if ($is_ebcdic eq 'define') {
        $self->_logger->debugf('Encode::Guess not supported on EBCDIC platform, so no encoding guess');
        return $self->_guess;
      }

      my @suspect_list = ();
      if ($bytes =~ /\e/) {
        push(@suspect_list, qw/7bit-jis iso-2022-kr/);
      }
      elsif ($bytes =~ /[\x80-\xFF]{4}/) {
        push(@suspect_list, qw/euc-cn big5-eten euc-jp cp932 euc-kr cp949/);
      } else {
        push(@suspect_list, qw/utf-8/);
      }

      local $Encode::Guess::NoUTFAutoGuess = 0;
      try {
        my $enc = guess_encoding($bytes, @suspect_list);
        if (! defined($enc) || ! ref($enc)) {
          GuessException->throw($enc || 'unknown encoding');
        }
        $self->_guess(uc($enc->name || ''));
      } catch {
        $self->_logger->tracef('Encoding guess failure, %s', "$_");
        return;
      };
    }
    if ($self->_length__guess > 0) {
      $self->_logger->tracef('Guessed encoding %s', $self->_guess);
      #
      # Are we lucky enough to match an xml declaration ?
      #
      try {
        #
        # Decode as much as possible
        # We do not use Encode::FB_QUIET because we would like to catch ourself
        # the replacement character U+FFFD
        #
        my $string = decode($self->_guess, $bytes, Encode::FB_DEFAULT);
        if ($string =~ /^<\?xml(?:${S}version=(?:(?:"1\.[01]\")|(?:'1\.[01]\')))?${S}encoding=((?:"[A-Za-z][A-Za-z0-9._\-]*+")|(?:'[A-Za-z][A-Za-z0-9._\-]*+'))/p) {
          my $matched_data = ${^MATCH};
          my $encname = substr($string, $-[1], $+[1] - $-[1]);
          substr($encname,  0, 1, '');   # first  ["']
          substr($encname, -1, 1, '');   # second ["']
          #
          # Have we encountered the replacement character ?
          #
          if ($string =~ /[\x{FFFD}]/) {
            $self->_logger->tracef('XML declaration pre-detected using guessed encoding %s on %d bytes and says encoding is %s - not all characters were reconized correctly', $self->_guess, length($bytes), $encname);
            substr($string, $-[0], length($matched_data) - $-[0], '');
          } else {
            $self->_logger->tracef('XML declaration pre-detected using guessed encoding %s on %d bytes and says encoding is %s', $self->_guess, length($bytes), $encname);
          }
          #
          # Verify this is a valid encoding
          #
          try {
            my $octets  = encode($encname, $matched_data, Encode::FB_CROAK);
            $self->_logger->tracef('Success verifying XML declared encoding %s', $encname);
          } catch {
            $self->_logger->warnf('Failed to verify XML declared encoding %s: %s', $encname, $_);
            return;
          } finally {
            $self->_guess($encname);
          };
        } else {
          $self->_logger->tracef('Failed to find XML declaration using guessed encoding %s, staying with it', $self->_guess);
        }
      } catch {
        $self->_logger->tracef('Failed to try guessed encoding %s: %s', $self->_guess, $_);
        $self->_logger->tracef('Falling back to UTF-8');
        $self->_guess('UTF-8');
        return;
      };
    }

    if ($self->_length__guess > 0) {
      $self->_logger->debugf('Final guessed encoding is %s', $self->_guess);
    } else {
      $self->_logger->debugf('No encoding guess');
    }

    return $self->_guess;
  }

  method merge_with_encodingFromXmlProlog(Str $encodingFromXmlProlog --> Encoding) {

    my $finalEncoding;
    if ($self->_length__bom <= 0) {
      if (($self->_length__guess <= 0) || length($encodingFromXmlProlog) <= 0) {
        $finalEncoding = 'UTF-8';
      } else {
        #
        # General handling of 'LE' and 'BE' extensions
        #
        if (($self->_guess eq uc("${encodingFromXmlProlog}BE")) || ($self->_guess eq uc("${encodingFromXmlProlog}LE"))) {
          $finalEncoding = $self->_guess;
        } else {
          $finalEncoding = $encodingFromXmlProlog;
        }
      }
    } else {
      if ($self->_bom eq 'UTF-8') {
        #
        # Why trusting a guess when it is only a guess.
        #
        # if (($self->_length__guess > 0) && ($self->_guess ne 'UTF-8')) {
        #   $self->_logger->errorf('BOM encoding "%s" disagree with guessed encoding "%s"', $self->_bom, $encodingFromXmlProlog);
        # }
        if ((length($encodingFromXmlProlog) > 0) && (uc($encodingFromXmlProlog) ne 'UTF-8')) {
          GuessException->throw("BOM encoding '" . $self->_bom . "' disagree with XML encoding '$encodingFromXmlProlog");
        }
      } else {
        if ($self->_bom =~ /^(.*)[LB]E$/) {
          my $without_le_or_be = ($+[1] > $-[1]) ? substr($self->_bom, $-[1], $+[1] - $-[1]) : '';
          if ((length($encodingFromXmlProlog) > 0) && (uc($encodingFromXmlProlog) ne $without_le_or_be) && (uc($encodingFromXmlProlog) ne $self->_bom)) {
            GuessException->throw("BOM encoding '" . $self->_bom . "' disagree with XML encoding '$encodingFromXmlProlog");
          }
        }
      }
      #
      # In any case, BOM win. So we always inherit the correct $byte_start.
      #
      $finalEncoding = $self->_bom;
    }

    $self->_logger->debugf('BOM says encoding is "%s", guess says "%s", merge with XML "%s" says "%s"', $self->_bom, $self->_guess, $encodingFromXmlProlog, $finalEncoding);

    $self->_set_value($finalEncoding);
    return $self;
  }

  with 'MarpaX::Languages::XML::Role::Encoding';
  with 'MooX::Role::Logger';
}

1;

