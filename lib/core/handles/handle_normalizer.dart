class HandleNormalizer {
  const HandleNormalizer._();

  static String normalize(String input) {
    var value = input.trim();
    if (value.startsWith('@')) {
      value = value.substring(1).trim();
    }
    if (value.isEmpty) return '';

    final buffer = StringBuffer();
    var lastWasSpace = false;

    for (final rune in value.runes) {
      final mapped = _mapRune(rune);
      if (_isWhitespaceRune(rune)) {
        if (!lastWasSpace) {
          buffer.write(' ');
          lastWasSpace = true;
        }
        continue;
      }
      buffer.write(mapped);
      lastWasSpace = false;
    }

    return buffer.toString().trim();
  }

  static String _mapRune(int rune) {
    if (rune >= 0x41 && rune <= 0x5A) {
      return String.fromCharCode(rune + 32);
    }
    if ((rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0x30 && rune <= 0x39) ||
        rune == 0x2E ||
        rune == 0x5F ||
        rune == 0x2D ||
        rune == 0x40 ||
        rune == 0x2B) {
      return String.fromCharCode(rune);
    }

    switch (rune) {
      case 0x00C0:
      case 0x00C1:
      case 0x00C2:
      case 0x00C3:
      case 0x00C4:
      case 0x00C5:
      case 0x00E0:
      case 0x00E1:
      case 0x00E2:
      case 0x00E3:
      case 0x00E4:
      case 0x00E5:
        return 'a';
      case 0x00C7:
      case 0x00E7:
        return 'c';
      case 0x00C8:
      case 0x00C9:
      case 0x00CA:
      case 0x00CB:
      case 0x00E8:
      case 0x00E9:
      case 0x00EA:
      case 0x00EB:
        return 'e';
      case 0x00CC:
      case 0x00CD:
      case 0x00CE:
      case 0x00CF:
      case 0x00EC:
      case 0x00ED:
      case 0x00EE:
      case 0x00EF:
        return 'i';
      case 0x00D1:
      case 0x00F1:
        return 'n';
      case 0x00D2:
      case 0x00D3:
      case 0x00D4:
      case 0x00D5:
      case 0x00D6:
      case 0x00F2:
      case 0x00F3:
      case 0x00F4:
      case 0x00F5:
      case 0x00F6:
        return 'o';
      case 0x00D9:
      case 0x00DA:
      case 0x00DB:
      case 0x00DC:
      case 0x00F9:
      case 0x00FA:
      case 0x00FB:
      case 0x00FC:
        return 'u';
      default:
        return String.fromCharCode(rune).toLowerCase();
    }
  }

  static bool _isWhitespaceRune(int rune) {
    return rune == 0x09 ||
        rune == 0x0A ||
        rune == 0x0B ||
        rune == 0x0C ||
        rune == 0x0D ||
        rune == 0x20 ||
        rune == 0xA0;
  }
}
