class ServiceTaxonomyNormalizer {
  const ServiceTaxonomyNormalizer._();

  static String normalize(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return '';

    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_foldDiacritics(char));
    }

    final cleaned = buffer.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> tokenize(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) return const [];
    return normalized
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.length >= 2)
        .where((token) => !_stopWords.contains(token))
        .toList(growable: false);
  }

  static String _foldDiacritics(String char) {
    switch (char) {
      case '\u00e0':
      case '\u00e1':
      case '\u00e2':
      case '\u00e3':
      case '\u00e4':
      case '\u00e5':
        return 'a';
      case '\u00e7':
        return 'c';
      case '\u00e8':
      case '\u00e9':
      case '\u00ea':
      case '\u00eb':
        return 'e';
      case '\u00ec':
      case '\u00ed':
      case '\u00ee':
      case '\u00ef':
        return 'i';
      case '\u00f1':
        return 'n';
      case '\u00f2':
      case '\u00f3':
      case '\u00f4':
      case '\u00f5':
      case '\u00f6':
        return 'o';
      case '\u00f9':
      case '\u00fa':
      case '\u00fb':
      case '\u00fc':
        return 'u';
      default:
        return char;
    }
  }
}

const _stopWords = <String>{
  'a',
  'ao',
  'as',
  'com',
  'da',
  'das',
  'de',
  'do',
  'dos',
  'e',
  'em',
  'na',
  'nas',
  'no',
  'nos',
  'o',
  'os',
  'para',
  'por',
  'um',
  'uma',
};
