import 'package:chegaja_v2/core/catalog/service_taxonomy_normalizer.dart';

class ProviderCustomService {
  const ProviderCustomService({
    required this.id,
    required this.name,
    this.description = '',
  });

  static const idPrefix = 'custom_';
  static const maxNameLength = 80;
  static const maxDescriptionLength = 280;

  final String id;
  final String name;
  final String description;

  factory ProviderCustomService.fromInput({
    required String name,
    String description = '',
  }) {
    final normalizedName = _cleanText(name, maxNameLength);
    final normalizedDescription = _cleanText(description, maxDescriptionLength);
    return ProviderCustomService(
      id: idForName(normalizedName),
      name: normalizedName,
      description: normalizedDescription,
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
    final name = _cleanText(value['name']?.toString() ?? '', maxNameLength);
    if (name.isEmpty) return null;
    final rawId = value['id']?.toString().trim() ?? '';
    final id = rawId.startsWith(idPrefix) ? rawId : idForName(name);
    return ProviderCustomService(
      id: id,
      name: name,
      description: _cleanText(
        value['description']?.toString() ?? '',
        maxDescriptionLength,
      ),
    );
  }

  static List<ProviderCustomService> listFrom(Object? value) {
    if (value is! Iterable) return const [];
    final byId = <String, ProviderCustomService>{};
    for (final item in value) {
      final service = fromMap(item);
      if (service == null) continue;
      byId[service.id] = service;
    }
    return List.unmodifiable(byId.values);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderCustomService &&
        other.id == id &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(id, name, description);

  static String _cleanText(String value, int maxLength) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return normalized.substring(0, maxLength).trim();
  }
}
