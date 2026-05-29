class ProviderSearchNormalizer {
  const ProviderSearchNormalizer._();

  static String normalize(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return '';

    final buffer = StringBuffer();
    var previousWasSpace = true;

    for (final rune in trimmed.runes) {
      final replacement = _replaceRune(rune);
      for (final codeUnit in replacement.codeUnits) {
        final isLetter = codeUnit >= 97 && codeUnit <= 122;
        final isDigit = codeUnit >= 48 && codeUnit <= 57;
        if (isLetter || isDigit) {
          buffer.writeCharCode(codeUnit);
          previousWasSpace = false;
        } else if (!previousWasSpace) {
          buffer.write(' ');
          previousWasSpace = true;
        }
      }
    }

    return buffer.toString().trim();
  }

  static List<String> normalizeTerms(Iterable<Object?> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      if (value == null) continue;
      final normalized = normalize(value.toString());
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      result.add(normalized);
    }

    return result;
  }

  static String _replaceRune(int rune) {
    switch (rune) {
      case 0x00e0:
      case 0x00e1:
      case 0x00e2:
      case 0x00e3:
      case 0x00e4:
      case 0x00e5:
      case 0x0101:
      case 0x0103:
      case 0x0105:
        return 'a';
      case 0x00e6:
        return 'ae';
      case 0x00e7:
      case 0x0107:
      case 0x010d:
        return 'c';
      case 0x010f:
      case 0x0111:
        return 'd';
      case 0x00e8:
      case 0x00e9:
      case 0x00ea:
      case 0x00eb:
      case 0x0113:
      case 0x0117:
      case 0x0119:
        return 'e';
      case 0x011f:
      case 0x0123:
        return 'g';
      case 0x00ec:
      case 0x00ed:
      case 0x00ee:
      case 0x00ef:
      case 0x012b:
      case 0x012f:
        return 'i';
      case 0x0142:
        return 'l';
      case 0x00f1:
      case 0x0144:
        return 'n';
      case 0x00f2:
      case 0x00f3:
      case 0x00f4:
      case 0x00f5:
      case 0x00f6:
      case 0x00f8:
      case 0x014d:
        return 'o';
      case 0x0153:
        return 'oe';
      case 0x0155:
      case 0x0159:
        return 'r';
      case 0x00df:
        return 'ss';
      case 0x015b:
      case 0x0161:
      case 0x015f:
        return 's';
      case 0x00f9:
      case 0x00fa:
      case 0x00fb:
      case 0x00fc:
      case 0x016b:
        return 'u';
      case 0x00fd:
      case 0x00ff:
        return 'y';
      case 0x017a:
      case 0x017c:
      case 0x017e:
        return 'z';
      default:
        return String.fromCharCode(rune);
    }
  }
}
