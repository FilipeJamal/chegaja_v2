import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/services/servico_search.dart';

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
      .toList(growable: false);

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
