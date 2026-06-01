import 'package:chegaja_v2/core/trust_safety/service_safety_guard.dart';

import 'provider_search_normalizer.dart';
import 'provider_search_profile.dart';

bool matchesProviderSearch(ProviderSearchProfile profile, String query) {
  return scoreProviderSearch(profile, query) > 0;
}

int scoreProviderSearch(ProviderSearchProfile profile, String query) {
  if (ServiceSafetyGuard.isServiceTextBlocked(query)) return 0;

  final normalizedQuery = ProviderSearchNormalizer.normalize(query);
  if (normalizedQuery.length < 2) return 0;

  var score = 0;
  final normalizedName =
      ProviderSearchNormalizer.normalize(profile.displayName);
  final normalizedBio = ProviderSearchNormalizer.normalize(profile.bio);
  final normalizedCity = ProviderSearchNormalizer.normalize(profile.city);
  final normalizedState = ProviderSearchNormalizer.normalize(profile.state);
  final normalizedCountry = ProviderSearchNormalizer.normalize(profile.country);
  final normalizedServices =
      ProviderSearchNormalizer.normalizeTerms(profile.services);
  final normalizedCategories =
      ProviderSearchNormalizer.normalizeTerms(profile.categories);

  score += _scoreText(normalizedName, normalizedQuery,
      exact: 120, prefix: 90, contains: 70);
  score += _scoreList(normalizedServices, normalizedQuery,
      exact: 80, prefix: 65, contains: 55);
  score += _scoreList(normalizedCategories, normalizedQuery,
      exact: 70, prefix: 55, contains: 45);
  score += _scoreText(normalizedCity, normalizedQuery,
      exact: 45, prefix: 35, contains: 28);
  score += _scoreText(normalizedState, normalizedQuery,
      exact: 40, prefix: 30, contains: 24);
  score += _scoreText(normalizedCountry, normalizedQuery,
      exact: 40, prefix: 30, contains: 24);
  score += _scoreText(normalizedBio, normalizedQuery,
      exact: 24, prefix: 18, contains: 12);

  if (score == 0 && profile.searchText.contains(normalizedQuery)) {
    score += 6;
  }

  if (score > 0 && profile.hasValidRating) {
    score += 1;
  }

  return score;
}

int _scoreList(
  Iterable<String> values,
  String query, {
  required int exact,
  required int prefix,
  required int contains,
}) {
  var best = 0;
  for (final value in values) {
    final score = _scoreText(value, query,
        exact: exact, prefix: prefix, contains: contains);
    if (score > best) best = score;
  }
  return best;
}

int _scoreText(
  String value,
  String query, {
  required int exact,
  required int prefix,
  required int contains,
}) {
  if (value.isEmpty) return 0;
  if (value == query) return exact;
  if (value.startsWith(query)) return prefix;
  if (value.contains(query)) return contains;
  return 0;
}
