class TrustSafetyTextNormalizer {
  const TrustSafetyTextNormalizer._();

  static String normalize(String input) {
    if (input.trim().isEmpty) return '';

    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final mapped = _accentMap[char] ?? char;

      if (_isAsciiLetterOrDigit(mapped)) {
        buffer.write(mapped);
      } else if (_isWhitespace(mapped) || _isSeparator(mapped)) {
        buffer.write(' ');
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _isAsciiLetterOrDigit(String char) {
    if (char.length != 1) return false;
    final code = char.codeUnitAt(0);
    return (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
  }

  static bool _isWhitespace(String char) => RegExp(r'\s').hasMatch(char);

  static bool _isSeparator(String char) {
    return const {
      '-',
      '_',
      '/',
      '\\',
      '.',
      ',',
      ';',
      ':',
      '!',
      '?',
      '(',
      ')',
      '[',
      ']',
      '{',
      '}',
      '"',
      "'",
      '`',
      '+',
      '*',
      '&',
      '|',
      '@',
      '#',
      '\$',
      '%',
      '^',
      '~',
      '<',
      '>',
      '=',
    }.contains(char);
  }

  static const Map<String, String> _accentMap = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
}
