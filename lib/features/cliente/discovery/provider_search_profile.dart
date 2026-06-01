import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/catalog/provider_custom_service.dart';
import 'package:chegaja_v2/core/trust_safety/custom_service_safety_validator.dart';

import 'provider_search_normalizer.dart';

class ProviderSearchProfile {
  const ProviderSearchProfile({
    required this.id,
    required this.displayName,
    required this.photoUrl,
    required this.bio,
    required this.city,
    required this.state,
    required this.country,
    required this.services,
    required this.categories,
    required this.portfolioPreviewUrls,
    required this.ratingAvg,
    required this.ratingCount,
    required this.searchTerms,
    required this.latitude,
    required this.longitude,
    this.handle,
    this.approvedSensitiveCategoryIds = const <String>[],
    this.approvedSensitiveCategoryNames = const <String>[],
  });

  final String id;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final String city;
  final String state;
  final String country;
  final List<String> services;
  final List<String> categories;
  final List<String> portfolioPreviewUrls;
  final double? ratingAvg;
  final int? ratingCount;
  final List<String> searchTerms;
  final double? latitude;
  final double? longitude;
  final String? handle;
  final List<String> approvedSensitiveCategoryIds;
  final List<String> approvedSensitiveCategoryNames;

  factory ProviderSearchProfile.fromPrestadorDoc({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final displayName = _firstNonEmpty([
      data['nome'],
      data['displayName'],
      data['name'],
    ]);
    final photoUrl = _firstValidUrl([
      data['photoUrl'],
      data['fotoUrl'],
      data['avatarUrl'],
      data['photoURL'],
    ]);
    final bio = _firstNonEmpty([data['bio'], data['descricao']]);
    final city = _firstNonEmpty([data['city'], data['cidade']]);
    final state = _firstNonEmpty([
      data['state'],
      data['province'],
      data['region'],
      data['estado'],
    ]);
    final country = _firstNonEmpty([data['country'], data['pais']]);
    final customServices = ProviderCustomService.listFrom(
      data['customServices'],
    );
    final customServiceNames = _safeServiceTexts(
      _stringList(data['customServiceNames']),
    );
    final customServiceSearchTerms =
        _safeServiceTexts(_stringList(data['customServiceSearchTerms']));
    final services = _uniqueStrings([
      ..._safeServiceTexts(_stringList(data['servicosNomes'])),
      ...customServiceNames,
      ...customServices.map((service) => service.name),
    ]);
    final categories = _uniqueStrings([
      ..._stringList(data['categories']),
      ..._safeServiceIds(_stringList(data['servicos']), customServices),
    ]);
    final portfolioPreviewUrls = _uniqueValidUrls([
      ..._stringList(data['portfolioUrls']),
      ..._stringList(data['portfolioImages']),
    ]);
    final ratingAvg = _numToDouble(data['ratingAvg']);
    final ratingCount = _numToInt(data['ratingCount']);
    final coords = _extractLatLng(data);
    final handle = _emptyToNull(data['handle']?.toString());
    final approvedSensitiveCategoryIds =
        _stringList(data['approvedSensitiveCategoryIds']);
    final approvedSensitiveCategoryNames =
        _stringList(data['approvedSensitiveCategoryNames']);

    final searchTerms = ProviderSearchNormalizer.normalizeTerms([
      displayName,
      handle,
      bio,
      city,
      state,
      country,
      ...services,
      ...categories,
      ...customServices.map((service) => service.description),
      ...customServices.expand((service) => service.aliases),
      ...customServices.expand((service) => service.normalizedSearchTerms),
      ...customServiceSearchTerms,
      ...approvedSensitiveCategoryNames,
    ]);

    return ProviderSearchProfile(
      id: id.trim(),
      displayName: displayName,
      photoUrl: photoUrl,
      bio: bio,
      city: city,
      state: state,
      country: country,
      services: services,
      categories: categories,
      portfolioPreviewUrls: portfolioPreviewUrls,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      searchTerms: searchTerms,
      latitude: coords?.lat,
      longitude: coords?.lng,
      handle: handle,
      approvedSensitiveCategoryIds: approvedSensitiveCategoryIds,
      approvedSensitiveCategoryNames: approvedSensitiveCategoryNames,
    );
  }

  bool get hasValidRating {
    final avg = ratingAvg;
    final count = ratingCount;
    return avg != null && count != null && count > 0 && avg >= 1 && avg <= 5;
  }

  bool get hasApprovedSensitiveCategories =>
      approvedSensitiveCategoryNames.isNotEmpty ||
      approvedSensitiveCategoryIds.isNotEmpty;

  bool get isSearchableLocal {
    if (id.trim().isEmpty || displayName.trim().isEmpty) return false;
    return services.isNotEmpty ||
        categories.isNotEmpty ||
        bio.trim().isNotEmpty ||
        city.trim().isNotEmpty ||
        state.trim().isNotEmpty ||
        country.trim().isNotEmpty ||
        portfolioPreviewUrls.isNotEmpty ||
        photoUrl != null;
  }

  String get searchText => searchTerms.join(' ');
}

String _firstNonEmpty(Iterable<Object?> values) {
  for (final value in values) {
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  }
  return '';
}

String? _emptyToNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _firstValidUrl(Iterable<Object?> values) {
  for (final value in values) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) continue;
    final uri = Uri.tryParse(normalized);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return normalized;
    }
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return _uniqueStrings(value.map((item) => item?.toString() ?? ''));
  }
  return const <String>[];
}

List<String> _uniqueStrings(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];

  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || seen.contains(normalized)) continue;
    seen.add(normalized);
    result.add(normalized);
  }

  return List.unmodifiable(result);
}

List<String> _safeServiceTexts(Iterable<String> values) {
  return _uniqueStrings(
    values.where((value) {
      return !CustomServiceSafetyValidator.validate(title: value).isBlocked;
    }),
  );
}

List<String> _safeServiceIds(
  Iterable<String> values,
  List<ProviderCustomService> customServices,
) {
  final safeCustomIds = customServices.map((service) => service.id).toSet();
  return _uniqueStrings(
    values.where((value) {
      if (!value.startsWith(ProviderCustomService.idPrefix)) return true;
      return safeCustomIds.contains(value);
    }),
  );
}

List<String> _uniqueValidUrls(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];

  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || seen.contains(normalized)) continue;
    final uri = Uri.tryParse(normalized);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      continue;
    }
    seen.add(normalized);
    result.add(normalized);
  }

  return List.unmodifiable(result);
}

double? _numToDouble(Object? value) {
  return value is num ? value.toDouble() : null;
}

int? _numToInt(Object? value) {
  return value is num ? value.toInt() : null;
}

({double lat, double lng})? _extractLatLng(Map<String, dynamic> data) {
  final geo = data['geo'];
  if (geo is Map) {
    final geopoint = geo['geopoint'];
    if (geopoint is GeoPoint) {
      return (lat: geopoint.latitude, lng: geopoint.longitude);
    }
  }

  final lastLocation = data['lastLocation'];
  if (lastLocation is GeoPoint) {
    return (lat: lastLocation.latitude, lng: lastLocation.longitude);
  }
  if (lastLocation is Map) {
    final lat = lastLocation['lat'] ?? lastLocation['latitude'];
    final lng = lastLocation['lng'] ?? lastLocation['longitude'];
    if (lat is num && lng is num) {
      return (lat: lat.toDouble(), lng: lng.toDouble());
    }
  }

  final lat = data['latitude'] ?? data['lat'];
  final lng = data['longitude'] ?? data['lng'];
  if (lat is num && lng is num) {
    return (lat: lat.toDouble(), lng: lng.toDouble());
  }

  return null;
}
