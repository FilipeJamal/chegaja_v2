import 'package:chegaja_v2/core/models/provider_custom_service.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/trust_safety_classifier.dart';

class ServiceSafetySanitizationResult {
  const ServiceSafetySanitizationResult({
    required this.serviceIds,
    required this.serviceNames,
    required this.customServices,
    required this.customServiceNames,
    required this.customServiceSearchTerms,
    required this.removedAny,
  });

  final Set<String> serviceIds;
  final List<String> serviceNames;
  final List<ProviderCustomService> customServices;
  final List<String> customServiceNames;
  final List<String> customServiceSearchTerms;
  final bool removedAny;
}

class ServiceSafetyGuard {
  const ServiceSafetyGuard._();

  static TrustSafetyClassification classifyServiceText(String text) {
    return TrustSafetyClassifier.classifyText(text);
  }

  static bool isServiceTextBlocked(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    return classifyServiceText(normalized).decision ==
        TrustSafetyDecision.block;
  }

  static List<String> filterAllowedServiceNames(Iterable<String> values) {
    return _uniqueStrings(
      values.where((value) => !isServiceTextBlocked(value)),
    );
  }

  static List<String> filterAllowedSearchTerms(Iterable<String> values) {
    return _uniqueStrings(
      values.where((value) => !isServiceTextBlocked(value)),
    );
  }

  static List<ProviderCustomService> filterAllowedCustomServices(
    Iterable<ProviderCustomService> values,
  ) {
    final byId = <String, ProviderCustomService>{};
    for (final service in values) {
      if (!service.isActive) continue;
      if (_isCustomServiceBlocked(service)) continue;
      byId[service.id] = service;
    }
    return List.unmodifiable(byId.values);
  }

  static ServiceSafetySanitizationResult sanitizeProviderServices({
    Object? servicos,
    Object? servicosNomes,
    Object? customServices,
    Object? customServiceNames,
    Object? customServiceSearchTerms,
  }) {
    final rawServiceIds = _stringList(servicos);
    final rawServiceNames = _stringList(servicosNomes);
    final rawCustomServiceNames = _stringList(customServiceNames);
    final rawCustomServiceSearchTerms = _stringList(customServiceSearchTerms);
    final parsedCustomServices =
        filterAllowedCustomServices(ProviderCustomService.listFrom(
      customServices,
    ));
    final safeCustomIds =
        parsedCustomServices.map((service) => service.id).toSet();

    final safeServiceIds = <String>{};
    for (final id in rawServiceIds) {
      if (id.startsWith(ProviderCustomService.idPrefix)) {
        if (safeCustomIds.contains(id)) safeServiceIds.add(id);
        continue;
      }
      if (!isServiceTextBlocked(id)) safeServiceIds.add(id);
    }

    final safeServiceNames = filterAllowedServiceNames([
      ...rawServiceNames,
      ...parsedCustomServices.map((service) => service.name),
    ]);
    final safeCustomServiceNames = filterAllowedServiceNames([
      ...rawCustomServiceNames,
      ...parsedCustomServices.map((service) => service.name),
    ]);
    final safeCustomServiceSearchTerms = filterAllowedSearchTerms([
      ...rawCustomServiceSearchTerms,
      ...parsedCustomServices
          .expand((service) => service.normalizedSearchTerms),
    ]);

    final removedAny = safeServiceIds.length != rawServiceIds.toSet().length ||
        safeServiceNames.length !=
            _uniqueStrings([
              ...rawServiceNames,
              ...parsedCustomServices.map((service) => service.name),
            ]).length ||
        safeCustomServiceNames.length !=
            _uniqueStrings([
              ...rawCustomServiceNames,
              ...parsedCustomServices.map((service) => service.name),
            ]).length ||
        safeCustomServiceSearchTerms.length !=
            _uniqueStrings([
              ...rawCustomServiceSearchTerms,
              ...parsedCustomServices
                  .expand((service) => service.normalizedSearchTerms),
            ]).length ||
        _rawCustomServiceCount(customServices) != parsedCustomServices.length;

    return ServiceSafetySanitizationResult(
      serviceIds: Set.unmodifiable(safeServiceIds),
      serviceNames: List.unmodifiable(safeServiceNames),
      customServices: parsedCustomServices,
      customServiceNames: List.unmodifiable(safeCustomServiceNames),
      customServiceSearchTerms: List.unmodifiable(safeCustomServiceSearchTerms),
      removedAny: removedAny,
    );
  }

  static bool _isCustomServiceBlocked(ProviderCustomService service) {
    final fields = <String>[
      service.title,
      service.description,
      service.normalizedTitle,
      ...service.aliases,
      ...service.normalizedSearchTerms,
    ];
    return fields.any(isServiceTextBlocked) ||
        service.trustSafetyDecision == TrustSafetyDecision.block.name;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _uniqueStrings(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      result.add(normalized);
    }

    return result;
  }

  static int _rawCustomServiceCount(Object? value) {
    if (value is! Iterable) return 0;
    return value.length;
  }
}
