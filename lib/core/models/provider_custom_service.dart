import 'package:chegaja_v2/core/catalog/service_taxonomy_normalizer.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/custom_service_safety_validator.dart';

class ProviderCustomService {
  const ProviderCustomService({
    required this.id,
    required this.title,
    this.description = '',
    this.aliases = const [],
    this.normalizedTitle = '',
    this.normalizedSearchTerms = const [],
    this.parentCategoryId = 'other',
    this.taxonomySubcategoryId = 'other_service',
    this.trustSafetyDecision = 'allow',
    this.trustSafetyReasonCodes = const [],
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  static const idPrefix = 'custom_';
  static const maxNameLength = 80;
  static const maxDescriptionLength = 280;
  static const maxAliases = 10;
  static const maxAliasLength = 40;

  final String id;
  final String title;
  final String description;
  final List<String> aliases;
  final String normalizedTitle;
  final List<String> normalizedSearchTerms;
  final String parentCategoryId;
  final String taxonomySubcategoryId;
  final String trustSafetyDecision;
  final List<String> trustSafetyReasonCodes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  String get name => title;

  factory ProviderCustomService.fromInput({
    String? title,
    String? name,
    String description = '',
    String aliasesText = '',
    Iterable<String> aliases = const [],
    String parentCategoryId = 'other',
    String taxonomySubcategoryId = 'other_service',
  }) {
    final normalizedTitle = _cleanText(
      (title ?? name ?? ''),
      maxNameLength,
    );
    final normalizedDescription = _cleanText(description, maxDescriptionLength);
    final aliasList = _cleanAliases([
      ...aliases,
      ..._splitAliases(aliasesText),
    ]);
    final safety = CustomServiceSafetyValidator.validate(
      title: normalizedTitle,
      description: normalizedDescription,
      aliases: aliasList,
    );
    final normalizedTerms = _normalizedTerms([
      normalizedTitle,
      normalizedDescription,
      ...aliasList,
    ]);
    return ProviderCustomService(
      id: idForName(normalizedTitle),
      title: normalizedTitle,
      description: normalizedDescription,
      aliases: aliasList,
      normalizedTitle: ServiceTaxonomyNormalizer.normalize(normalizedTitle),
      normalizedSearchTerms: normalizedTerms,
      parentCategoryId: parentCategoryId,
      taxonomySubcategoryId: taxonomySubcategoryId,
      trustSafetyDecision: safety.decision.name,
      trustSafetyReasonCodes: safety.reasonCodes,
      isActive: true,
    );
  }

  static String idForName(String name) {
    final slug = ServiceTaxonomyNormalizer.normalize(name)
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isEmpty) return '${idPrefix}servico_personalizado';
    return '$idPrefix$slug';
  }

  static ProviderCustomService? fromMap(Object? value) {
    if (value is! Map) return null;
    final title = _cleanText(
      (value['title'] ?? value['name'])?.toString() ?? '',
      maxNameLength,
    );
    if (title.isEmpty) return null;
    final rawId = value['id']?.toString().trim() ?? '';
    final aliases = _cleanAliases(_stringList(value['aliases']));
    final normalizedTerms = _stringList(value['normalizedSearchTerms']);
    return ProviderCustomService(
      id: rawId.startsWith(idPrefix) ? rawId : idForName(title),
      title: title,
      description: _cleanText(
        value['description']?.toString() ?? '',
        maxDescriptionLength,
      ),
      aliases: aliases,
      normalizedTitle:
          (value['normalizedTitle']?.toString().trim().isNotEmpty ?? false)
              ? value['normalizedTitle'].toString().trim()
              : ServiceTaxonomyNormalizer.normalize(title),
      normalizedSearchTerms: normalizedTerms.isNotEmpty
          ? normalizedTerms
          : _normalizedTerms([
              title,
              value['description']?.toString() ?? '',
              ...aliases,
            ]),
      parentCategoryId:
          value['parentCategoryId']?.toString().trim().isNotEmpty == true
              ? value['parentCategoryId'].toString().trim()
              : 'other',
      taxonomySubcategoryId:
          value['taxonomySubcategoryId']?.toString().trim().isNotEmpty == true
              ? value['taxonomySubcategoryId'].toString().trim()
              : 'other_service',
      trustSafetyDecision:
          value['trustSafetyDecision']?.toString().trim().isNotEmpty == true
              ? value['trustSafetyDecision'].toString().trim()
              : TrustSafetyDecision.allow.name,
      trustSafetyReasonCodes: _stringList(value['trustSafetyReasonCodes']),
      createdAt: _dateFrom(value['createdAt']),
      updatedAt: _dateFrom(value['updatedAt']),
      isActive: value['isActive'] != false,
    );
  }

  static List<ProviderCustomService> listFrom(Object? value) {
    if (value is! Iterable) return const [];
    final byId = <String, ProviderCustomService>{};
    for (final item in value) {
      final service = fromMap(item);
      if (service == null) continue;
      if (service.trustSafetyDecision == TrustSafetyDecision.block.name) {
        continue;
      }
      byId[service.id] = service;
    }
    return List.unmodifiable(byId.values);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'description': description,
      'aliases': aliases,
      'normalizedTitle': normalizedTitle,
      'normalizedSearchTerms': normalizedSearchTerms,
      'parentCategoryId': parentCategoryId,
      'taxonomySubcategoryId': taxonomySubcategoryId,
      'trustSafetyDecision': trustSafetyDecision,
      'trustSafetyReasonCodes': trustSafetyReasonCodes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderCustomService &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        _sameList(other.aliases, aliases) &&
        other.normalizedTitle == normalizedTitle &&
        _sameList(other.normalizedSearchTerms, normalizedSearchTerms) &&
        other.parentCategoryId == parentCategoryId &&
        other.taxonomySubcategoryId == taxonomySubcategoryId &&
        other.trustSafetyDecision == trustSafetyDecision &&
        _sameList(other.trustSafetyReasonCodes, trustSafetyReasonCodes) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        Object.hashAll(aliases),
        normalizedTitle,
        Object.hashAll(normalizedSearchTerms),
        parentCategoryId,
        taxonomySubcategoryId,
        trustSafetyDecision,
        Object.hashAll(trustSafetyReasonCodes),
        createdAt,
        updatedAt,
        isActive,
      );

  static String _cleanText(String value, int maxLength) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return normalized.substring(0, maxLength).trim();
  }

  static List<String> _splitAliases(String value) {
    if (value.trim().isEmpty) return const [];
    return value
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _cleanAliases(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final alias = _cleanText(value, maxAliasLength);
      if (alias.isEmpty) continue;
      final key = ServiceTaxonomyNormalizer.normalize(alias);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(alias);
      if (result.length >= maxAliases) break;
    }
    return List.unmodifiable(result);
  }

  static List<String> _normalizedTerms(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];

    void addTerm(String value) {
      final normalized = ServiceTaxonomyNormalizer.normalize(value);
      if (normalized.isEmpty || seen.contains(normalized)) return;
      seen.add(normalized);
      result.add(normalized);
    }

    for (final value in values) {
      addTerm(value);
      for (final fragment in _searchFragments(value)) {
        addTerm(fragment);
      }
    }
    return List.unmodifiable(result);
  }

  static Iterable<String> _searchFragments(String value) {
    final normalized = ServiceTaxonomyNormalizer.normalize(value);
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\s+(?:e|ou)\s+'))
        .map((item) => item.trim())
        .where((item) => item.length >= 3);
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
