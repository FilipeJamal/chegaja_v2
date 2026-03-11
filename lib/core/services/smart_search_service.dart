import 'dart:math';
import 'package:chegaja_v2/core/models/prestador.dart';
import 'package:chegaja_v2/core/repositories/prestador_repo.dart';

/// Serviço de Pesquisa Inteligente (Smart Search)
///
/// Capacidades:
/// 1. **Fuzzy Search**: Encontra resultados mesmo com erros ortográficos (Levenshtein).
/// 2. **Sinónimos Contextuais**: "lápis" -> "Design", "Pintura".
/// 3. **Scoring Ponderado**: Dá mais peso a matches no título do que nas keywords.
/// 4. **Normalização**: Remove acentos e caracteres especiais para melhor matching.
///
/// Uso:
/// ```dart
/// final results = SmartSearchService.instance.search('piza', items);
/// ```
class SmartSearchService {
  SmartSearchService._();
  static final SmartSearchService instance = SmartSearchService._();

  // Limite de distância para considerar um "match" (frouxo para permitir erros)
  static const int _maxEditDistance = 2; // ex: "piza" (4 chars) -> permite 1 erro. "restaurante" -> 2 erros.

  /// Mapa de Sinónimos Global (Expandir conforme necessário)
  static final Map<String, List<String>> _synonyms = {
     // Comida
    'comida': ['cozinheiro', 'chef', 'catering', 'bolo', 'doce'],
    'fome': ['cozinheiro', 'chef', 'entrega', 'restaurante'],
    'pao': ['padaria', 'pequeno almoco', 'lanche'],
    'doce': ['pastelaria', 'bolo', 'sobremesa'],
    'bolo': ['pastelaria', 'aniversario', 'festa'],
    'jantar': ['cozinheiro', 'chef', 'restaurante'],
    'almoco': ['cozinheiro', 'chef', 'restaurante'],

    // Casa / Limpeza
    'limpeza': ['domestica', 'faxina', 'limpar', 'higienizacao'],
    'sujo': ['limpeza', 'domestica'],
    'partido': ['reparacao', 'conserto', 'obras', 'manutencao'],
    'avariado': ['reparacao', 'tecnico', 'eletricista', 'picheleiro'],
    'agua': ['picheleiro', 'canalizador', 'fuga'],
    'luz': ['eletricista', 'lampada', 'energia'],

    // Veículos
    'carro': ['mecanico', 'reboque', 'lavagem', 'motorista'],
    'pneu': ['borracheiro', 'mecanico', 'roadside'],
    'boleia': ['motorista', 'taxi', 'uber', 'tvde'],

    // Criativos / Aulas
    'lapis': ['desenho', 'pintura', 'arte', 'aulas'],
    'pintar': ['pintor', 'obras', 'arte'],
    'musica': ['guitarra', 'piano', 'aulas', 'banda'],
    'festa': ['dj', 'banda', 'animacao', 'eventos', 'bolo'],

    // Animais
    'cao': ['passeador', 'treinador', 'veterinario', 'pet sitting'],
    'gato': ['veterinario', 'pet sitting'],
    'bicho': ['veterinario', 'pet'],
  };

  /// Realiza a pesquisa numa lista de objetos genéricos [T].
  ///
  /// [query]: O texto que o utilizador escreveu.
  /// [items]: A lista total de itens onde pesquisar.
  /// [idSelector]: Função para obter o ID do item.
  /// [nameSelector]: Função para obter o nome/título principal.
  /// [keywordsSelector]: Função para obter keywords ou tags do item.
  List<T> search<T>({
    required String query,
    required List<T> items,
    required String Function(T) idSelector,
    required String Function(T) nameSelector,
    required List<String> Function(T) keywordsSelector,
    int limit = 20,
  }) {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = _normalize(query);
    final queryTokens = normalizedQuery.split(' ').where((t) => t.isNotEmpty).toList();

    // 1. Expandir Query com Sinónimos
    final expandedTokens = <String>{...queryTokens};
    for (final token in queryTokens) {
      if (_synonyms.containsKey(token)) {
        expandedTokens.addAll(_synonyms[token]!);
      }
    }

    final scores = <String, double>{}; // ID -> Score

    for (final item in items) {
      final id = idSelector(item);
      final name = _normalize(nameSelector(item));
      final keywords = keywordsSelector(item).map(_normalize).toList();

      double score = 0.0;

      for (final searchToken in expandedTokens) {
        // A. Match Exato ou Parcial no Nome (Peso Alto)
        if (name.contains(searchToken)) {
          score += 10.0;
          if (name.startsWith(searchToken)) score += 5.0; // Bonus começo
          if (name == searchToken) score += 10.0; // Bonus exato absoluto
        } 
        // B. Fuzzy Match no Nome (Peso Médio)
        else if (_isFuzzyMatch(searchToken, name)) {
           score += 5.0;
        }

        // C. Match nas Keywords (Peso Baixo)
        for (final keyword in keywords) {
          if (keyword.contains(searchToken)) {
            score += 3.0;
          } else if (_isFuzzyMatch(searchToken, keyword)) {
            score += 1.0;
          }
        }
      }

      if (score > 0) {
        scores[id] = score;
      }
    }

    // Ordenar resultados pelo score
    final sortedResults = items
        .where((item) => scores.containsKey(idSelector(item)))
        .toList()
      ..sort((a, b) => scores[idSelector(b)]!.compareTo(scores[idSelector(a)]!));
    
    // Log de Analytics para melhoria contínua (opcional, pode ser muito verbose)
    // AnalyticsService.instance.logSearch(query); 

    return sortedResults.take(limit).toList();
  }

  /// Verifica se [token] é semelhante a [target] usando Levenshtein.
  bool _isFuzzyMatch(String token, String target) {
    if (token.length < 3) return false; // Ignora palavras muito curtas para fuzzy
    
    // Divide target em palavras para comparar palavra-a-palavra
    final targetWords = target.split(' ');
    
    for (final word in targetWords) {
      if ((word.length - token.length).abs() > _maxEditDistance) continue;
      
      final distance = _levenshtein(token, word);
      // Permite 1 erro para palavras pequenas (3-5), 2 erros para maiores (>5)
      final allowedErrors = token.length > 5 ? 2 : 1; 
      
      if (distance <= allowedErrors) return true;
    }
    return false;
  }

  /// Calcula distância de Levenshtein (custo de edição entre duas strings)
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final List<List<int>> matrix = List.generate(
      a.length + 1,
      (i) => List<int>.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // Deletion
          matrix[i][j - 1] + 1,      // Insertion
          matrix[i - 1][j - 1] + cost, // Substitution
        ].reduce(min);
      }
    }

    return matrix[a.length][b.length];
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ''); // Remove simbolos
  }
  /// Pesquisa prestadores combinando GeoQuery + Texto Inteligente
  Future<List<Prestador>> searchProviders({
    String query = '',
    double? latitude,
    double? longitude,
    double raioKm = 30.0,
    String? categoryId,
    bool onlyOnline = true,
  }) async {
    // 1. Obter candidatos via GeoQuery/Filtros Hard (Firestore)
    final candidates = await PrestadorRepo().buscaPrestadores(
      latitude: latitude,
      longitude: longitude,
      raioKm: raioKm,
      categoriaId: categoryId,
      apenasOnline: onlyOnline,
    );

    // 2. Se não houver texto, retorna ordenado pela distância (padrão do repo/geo)
    if (query.trim().isEmpty) {
      return candidates;
    }

    // 3. Se houver texto, refinamos com o Smart Search (Fuzzy + Keywords)
    return search<Prestador>(
      query: query,
      items: candidates,
      idSelector: (p) => p.uid,
      nameSelector: (p) => p.displayName ?? '',
      keywordsSelector: (p) => [
        ...(p.bio?.split(' ') ?? []),
        ...p.categories,
      ],
    );
  }
}
