import 'package:chegaja_v2/core/catalog/service_taxonomy.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_catalog.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_normalizer.dart';

enum ServiceTaxonomyMatchConfidence {
  high,
  medium,
  low,
  none,
}

enum ServiceTaxonomyMatchedBy {
  label,
  alias,
  phrase,
  example,
  legacyName,
  partial,
  none,
}

class ServiceTaxonomyMatch {
  const ServiceTaxonomyMatch({
    required this.rawQuery,
    required this.normalizedQuery,
    required this.confidence,
    required this.matchedBy,
    this.bestMatch,
    this.suggestions = const [],
  });

  final String rawQuery;
  final String normalizedQuery;
  final ServiceTaxonomySubcategory? bestMatch;
  final List<ServiceTaxonomySubcategory> suggestions;
  final ServiceTaxonomyMatchConfidence confidence;
  final ServiceTaxonomyMatchedBy matchedBy;

  bool get hasMatch => bestMatch != null;
}

class ServiceTaxonomyMatcher {
  const ServiceTaxonomyMatcher._();

  static ServiceTaxonomyMatch matchServiceQuery(
    String query, {
    int suggestionLimit = 4,
  }) {
    final normalized = ServiceTaxonomyNormalizer.normalize(query);
    if (normalized.isEmpty) {
      return ServiceTaxonomyMatch(
        rawQuery: query,
        normalizedQuery: normalized,
        confidence: ServiceTaxonomyMatchConfidence.none,
        matchedBy: ServiceTaxonomyMatchedBy.none,
      );
    }

    final scored = <_ScoredSubcategory>[];
    for (final subcategory in ServiceTaxonomyCatalog.subcategories) {
      final score = _scoreSubcategory(normalized, subcategory);
      if (score.score > 0) scored.add(score);
    }

    if (scored.isEmpty) {
      return ServiceTaxonomyMatch(
        rawQuery: query,
        normalizedQuery: normalized,
        confidence: ServiceTaxonomyMatchConfidence.none,
        matchedBy: ServiceTaxonomyMatchedBy.none,
      );
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.subcategory.sortOrder.compareTo(b.subcategory.sortOrder);
    });

    final top = scored.first;
    final closeSuggestions = scored
        .where((entry) => top.score - entry.score <= 18)
        .map((entry) => entry.subcategory)
        .take(suggestionLimit)
        .toList(growable: false);

    final queryTokenCount =
        ServiceTaxonomyNormalizer.tokenize(normalized).length;
    if ((top.score < 70 || queryTokenCount == 1) &&
        closeSuggestions.length > 1) {
      return ServiceTaxonomyMatch(
        rawQuery: query,
        normalizedQuery: normalized,
        confidence: ServiceTaxonomyMatchConfidence.low,
        matchedBy: ServiceTaxonomyMatchedBy.partial,
        suggestions: closeSuggestions,
      );
    }

    final confidence = top.score >= 70
        ? ServiceTaxonomyMatchConfidence.high
        : top.score >= 45
            ? ServiceTaxonomyMatchConfidence.medium
            : ServiceTaxonomyMatchConfidence.low;

    return ServiceTaxonomyMatch(
      rawQuery: query,
      normalizedQuery: normalized,
      bestMatch: top.subcategory,
      confidence: confidence,
      matchedBy: top.matchedBy,
      suggestions: scored
          .map((entry) => entry.subcategory)
          .take(suggestionLimit)
          .toList(growable: false),
    );
  }

  static _ScoredSubcategory _scoreSubcategory(
    String normalizedQuery,
    ServiceTaxonomySubcategory subcategory,
  ) {
    var bestScore = 0;
    var bestBy = ServiceTaxonomyMatchedBy.none;

    void scoreTerms(
      Iterable<String> rawTerms,
      ServiceTaxonomyMatchedBy matchedBy,
      int exactScore,
      int partialScore,
    ) {
      for (final rawTerm in rawTerms) {
        final normalizedTerm = ServiceTaxonomyNormalizer.normalize(rawTerm);
        if (normalizedTerm.isEmpty) continue;

        var score = 0;
        if (normalizedTerm == normalizedQuery) {
          score = exactScore;
        } else if (normalizedQuery.contains(normalizedTerm) ||
            normalizedTerm.contains(normalizedQuery)) {
          score = partialScore;
        } else {
          score = _tokenScore(normalizedQuery, normalizedTerm);
        }

        if (score > bestScore) {
          bestScore = score;
          bestBy = score == exactScore
              ? matchedBy
              : ServiceTaxonomyMatchedBy.partial;
        }
      }
    }

    scoreTerms(
      [subcategory.label],
      ServiceTaxonomyMatchedBy.label,
      110,
      60,
    );
    scoreTerms(
      subcategory.commonPhrases,
      ServiceTaxonomyMatchedBy.phrase,
      105,
      55,
    );
    scoreTerms(
      subcategory.aliases,
      ServiceTaxonomyMatchedBy.alias,
      95,
      48,
    );
    scoreTerms(
      subcategory.examples,
      ServiceTaxonomyMatchedBy.example,
      85,
      42,
    );
    scoreTerms(
      subcategory.legacyNames,
      ServiceTaxonomyMatchedBy.legacyName,
      80,
      38,
    );

    return _ScoredSubcategory(
      subcategory: subcategory,
      score: bestScore,
      matchedBy: bestBy,
    );
  }

  static int _tokenScore(String normalizedQuery, String normalizedTerm) {
    final queryTokens = ServiceTaxonomyNormalizer.tokenize(normalizedQuery);
    final termTokens = ServiceTaxonomyNormalizer.tokenize(normalizedTerm);
    if (queryTokens.isEmpty || termTokens.isEmpty) return 0;

    final querySet = queryTokens.toSet();
    final termSet = termTokens.toSet();
    final overlap = querySet.intersection(termSet).length;
    if (overlap == 0) return 0;

    final coverage = overlap / querySet.length;
    return (coverage * 42).round();
  }
}

class _ScoredSubcategory {
  const _ScoredSubcategory({
    required this.subcategory,
    required this.score,
    required this.matchedBy,
  });

  final ServiceTaxonomySubcategory subcategory;
  final int score;
  final ServiceTaxonomyMatchedBy matchedBy;
}
