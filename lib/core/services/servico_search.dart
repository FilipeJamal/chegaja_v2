// lib/core/services/servico_search.dart
// Indexador simples para pesquisa de servicos com pesos e sinonimos.

class ServicoSearchIndex<T> {
  ServicoSearchIndex({
    required Iterable<T> items,
    required String Function(T) id,
    required String Function(T) name,
    required List<String> Function(T) keywords,
    String Function(T)? mode,
  }) {
    var index = 0;
    for (final item in items) {
      final entry = _Entry<T>(
        index: index,
        item: item,
        id: id(item),
        name: name(item),
        keywords: keywords(item),
        mode: mode?.call(item) ?? '',
      );
      _entries.add(entry);
      _indexEntry(entry);
      index++;
    }
    _sortedByName = [..._entries]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  final List<_Entry<T>> _entries = [];
  final Map<String, List<_TokenRef>> _index = {};
  late final List<_Entry<T>> _sortedByName;

  List<T> search(
    String query, {
    int limit = 50,
  }) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return _sortedByName.take(limit).map((e) => e.item).toList();
    }

    final tokens = _tokenize(normalized);
    final scores = <int, double>{};

    for (final token in tokens) {
      final refs = _index[token];
      if (refs == null) continue;
      for (final ref in refs) {
        scores.update(ref.index, (v) => v + ref.weight,
            ifAbsent: () => ref.weight);
      }
    }

    if (scores.isEmpty) {
      for (final entry in _entries) {
        if (entry.nameNormalized.contains(normalized) ||
            entry.keywordsNormalized.contains(normalized)) {
          scores[entry.index] = 1.0;
        }
      }
    }

    final hasUrgent = tokens.any(_urgentTokens.contains);
    final hasSchedule = tokens.any(_scheduleTokens.contains);
    final hasBudget = tokens.any(_budgetTokens.contains);

    scores.removeWhere((index, _) {
      final entry = _entries[index];
      return entry.negatives.any(tokens.contains);
    });

    for (final entry in _entries) {
      final score = scores[entry.index];
      if (score == null) continue;

      var boosted = score;
      if (entry.nameNormalized == normalized) {
        boosted += 20;
      } else if (entry.nameNormalized.startsWith(normalized)) {
        boosted += 6;
      }

      if (hasUrgent && entry.modeNormalized == 'IMEDIATO') {
        boosted += 2.5;
      }
      if (hasSchedule && entry.modeNormalized == 'AGENDADO') {
        boosted += 1.8;
      }
      if (hasBudget && entry.modeNormalized == 'ORCAMENTO') {
        boosted += 1.8;
      }

      scores[entry.index] = boosted;
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final byScore = b.value.compareTo(a.value);
        if (byScore != 0) return byScore;
        final nameA = _entries[a.key].name.toLowerCase();
        final nameB = _entries[b.key].name.toLowerCase();
        return nameA.compareTo(nameB);
      });

    return ranked
        .take(limit)
        .map((e) => _entries[e.key].item)
        .toList();
  }

  void _indexEntry(_Entry<T> entry) {
    final tokenWeights = <String, double>{};

    void addTokens(String raw, double weight) {
      final normalized = _normalize(raw);
      if (normalized.isEmpty) return;
      for (final token in _tokenize(normalized)) {
        tokenWeights.update(token, (v) => v + weight, ifAbsent: () => weight);
      }
    }

    addTokens(entry.name, 5.0);

    for (final keyword in entry.keywords) {
      final parsed = _parseKeyword(keyword);
      if (parsed.isNegative) {
        for (final token in _tokenize(_normalize(parsed.value))) {
          entry.negatives.add(token);
        }
        continue;
      }
      addTokens(parsed.value, parsed.weight);
    }

    for (final kv in tokenWeights.entries) {
      final list = _index.putIfAbsent(kv.key, () => <_TokenRef>[]);
      list.add(_TokenRef(entry.index, kv.value));
    }
  }
}

class _Entry<T> {
  _Entry({
    required this.index,
    required this.item,
    required this.id,
    required this.name,
    required this.keywords,
    required String mode,
  })  : nameNormalized = _normalize(name),
        keywordsNormalized = _normalize(keywords.join(' ')),
        modeNormalized = _normalizeMode(mode);

  final int index;
  final T item;
  final String id;
  final String name;
  final List<String> keywords;
  final String nameNormalized;
  final String keywordsNormalized;
  final String modeNormalized;
  final Set<String> negatives = <String>{};
}

class _TokenRef {
  const _TokenRef(this.index, this.weight);
  final int index;
  final double weight;
}

class _ParsedKeyword {
  const _ParsedKeyword({
    required this.value,
    required this.weight,
    required this.isNegative,
  });
  final String value;
  final double weight;
  final bool isNegative;
}

_ParsedKeyword _parseKeyword(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const _ParsedKeyword(value: '', weight: 0, isNegative: false);
  }

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('x:') ||
      lower.startsWith('neg:') ||
      lower.startsWith('!') ||
      lower.startsWith('-')) {
    final value = trimmed.replaceFirst(RegExp(r'^(x:|neg:|!|-)'), '');
    return _ParsedKeyword(value: value, weight: 0, isNegative: true);
  }

  if (lower.startsWith('s:') || lower.startsWith('syn:')) {
    return _ParsedKeyword(value: trimmed.substring(trimmed.indexOf(':') + 1), weight: 4.0, isNegative: false);
  }
  if (lower.startsWith('m:')) {
    return _ParsedKeyword(value: trimmed.substring(2), weight: 2.6, isNegative: false);
  }
  if (lower.startsWith('p:')) {
    return _ParsedKeyword(value: trimmed.substring(2), weight: 2.6, isNegative: false);
  }
  if (lower.startsWith('o:')) {
    return _ParsedKeyword(value: trimmed.substring(2), weight: 2.2, isNegative: false);
  }
  if (lower.startsWith('i:')) {
    return _ParsedKeyword(value: trimmed.substring(2), weight: 1.6, isNegative: false);
  }

  return _ParsedKeyword(value: trimmed, weight: 3.0, isNegative: false);
}

String _normalizeMode(String raw) {
  final value = raw.toUpperCase().trim();
  if (value == 'POR_PROPOSTA' || value == 'POR_ORCAMENTO' || value == 'ORCAMENTO') {
    return 'ORCAMENTO';
  }
  if (value == 'AGENDADO') return 'AGENDADO';
  if (value == 'IMEDIATO') return 'IMEDIATO';
  return value;
}

List<String> _tokenize(String value) {
  if (value.isEmpty) return const [];
  final parts = value.split(' ');
  final tokens = <String>[];
  for (final part in parts) {
    final token = part.trim();
    if (token.isEmpty) continue;
    if (token.length < 2) continue;
    if (_stopWords.contains(token)) continue;
    tokens.add(token);
  }
  return tokens;
}

String _normalize(String input) {
  final lower = input.toLowerCase().trim();
  if (lower.isEmpty) return '';

  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_foldDiacritics(ch));
  }

  final cleaned = buffer.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _foldDiacritics(String ch) {
  switch (ch) {
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
    case '\u00fd':
    case '\u00ff':
      return 'y';
    default:
      return ch;
  }
}

const Set<String> _stopWords = {
  'de',
  'do',
  'da',
  'dos',
  'das',
  'para',
  'por',
  'com',
  'sem',
  'e',
  'ou',
  'a',
  'o',
  'os',
  'as',
  'um',
  'uma',
  'no',
  'na',
  'nos',
  'nas',
};

const Set<String> _urgentTokens = {
  'urgente',
  'ja',
  'agora',
  'hoje',
  'imediato',
  '24h',
  'rapido',
};

const Set<String> _scheduleTokens = {
  'agendar',
  'agenda',
  'marcar',
  'amanha',
  'semana',
  'agendado',
};

const Set<String> _budgetTokens = {
  'orcamento',
  'orcar',
  'proposta',
  'cotacao',
  'preco',
};
