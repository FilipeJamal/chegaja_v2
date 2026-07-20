import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/services/servico_search.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_catalog.dart';
import 'package:chegaja_v2/core/config/app_config.dart';

class ClienteServiceCatalogResult {
  const ClienteServiceCatalogResult({
    required this.services,
    required this.totalMatched,
    required this.isSearching,
  });

  final List<Servico> services;
  final int totalMatched;
  final bool isSearching;

  bool get isTruncated => totalMatched > services.length;
}

ClienteServiceCatalogResult visibleClienteCatalogServices({
  required List<Servico> services,
  required String selectedMode,
  required String query,
  int limit = 24,
}) {
  final normalizedMode = _normalizeCatalogMode(selectedMode);
  final modeServices = services
      .where((service) => _normalizeCatalogMode(service.mode) == normalizedMode)
      .toList();

  if (AppConfig.pilotMode) {
    final originalOrder = <String, int>{
      for (var index = 0; index < modeServices.length; index += 1)
        modeServices[index].id: index,
    };
    modeServices.sort((left, right) {
      final leftPromoted = _isPilotPromoted(left);
      final rightPromoted = _isPilotPromoted(right);
      if (leftPromoted == rightPromoted) {
        return (originalOrder[left.id] ?? 0)
            .compareTo(originalOrder[right.id] ?? 0);
      }
      return leftPromoted ? -1 : 1;
    });
  }

  final normalizedQuery = query.trim();
  if (normalizedQuery.length < 2) {
    return ClienteServiceCatalogResult(
      services: modeServices.take(limit).toList(growable: false),
      totalMatched: modeServices.length,
      isSearching: false,
    );
  }

  final index = ServicoSearchIndex<Servico>(
    items: modeServices,
    id: (service) => service.id,
    name: (service) => service.name,
    keywords: (service) => [
      ...service.keywords,
      ...service.nameI18n.values,
      if (service.iconKey != null) service.iconKey!,
    ],
    mode: (service) => service.mode,
  );
  final matches = index.search(normalizedQuery, limit: modeServices.length);

  return ClienteServiceCatalogResult(
    services: matches.take(limit).toList(growable: false),
    totalMatched: matches.length,
    isSearching: true,
  );
}

bool _isPilotPromoted(Servico service) {
  final subcategory = ServiceTaxonomyCatalog.findSubcategoryById(service.id) ??
      ServiceTaxonomyCatalog.mapLegacyServicoToSubcategory(service);
  return subcategory != null &&
      AppConfig.pilotPromotedCategoryIds.contains(
        subcategory.parentCategoryId,
      );
}

String _normalizeCatalogMode(String raw) {
  final value = raw.toUpperCase().trim();
  if (value == 'POR_PROPOSTA' ||
      value == 'POR_ORCAMENTO' ||
      value == 'ORCAMENTO') {
    return 'ORCAMENTO';
  }
  if (value == 'AGENDADO') return 'AGENDADO';
  if (value == 'IMEDIATO') return 'IMEDIATO';
  return value;
}
