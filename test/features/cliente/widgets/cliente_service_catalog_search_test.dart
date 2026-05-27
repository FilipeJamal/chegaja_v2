import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_service_catalog_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const services = [
    Servico(
      id: 'portrait-pencil',
      name: 'Retratista a lapis',
      mode: 'ORCAMENTO',
      keywords: ['desenho', 'arte', 'retrato'],
      isActive: true,
    ),
    Servico(
      id: 'bathroom-assembly',
      name: 'Assentamento de casas de banho',
      mode: 'ORCAMENTO',
      keywords: ['obra', 'casa'],
      isActive: true,
    ),
    Servico(
      id: 'cleaning-now',
      name: 'Limpeza urgente',
      mode: 'IMEDIATO',
      keywords: ['faxina'],
      isActive: true,
    ),
  ];

  test('filters catalog services by selected mode before search', () {
    final result = visibleClienteCatalogServices(
      services: services,
      selectedMode: 'ORCAMENTO',
      query: '',
    );

    expect(result.services.map((service) => service.id), [
      'portrait-pencil',
      'bathroom-assembly',
    ]);
    expect(result.totalMatched, 2);
    expect(result.isSearching, isFalse);
  });

  test('searches visible service cards instead of only suggestions', () {
    final result = visibleClienteCatalogServices(
      services: services,
      selectedMode: 'ORCAMENTO',
      query: 'retrato',
    );

    expect(result.services.map((service) => service.id), ['portrait-pencil']);
    expect(result.totalMatched, 1);
    expect(result.isSearching, isTrue);
  });

  test('limits initial rendering to keep the catalog responsive', () {
    final many = List.generate(
      40,
      (index) => Servico(
        id: 'quote-$index',
        name: 'Servico $index',
        mode: 'ORCAMENTO',
        keywords: const [],
        isActive: true,
      ),
    );

    final result = visibleClienteCatalogServices(
      services: many,
      selectedMode: 'ORCAMENTO',
      query: '',
      limit: 12,
    );

    expect(result.services, hasLength(12));
    expect(result.totalMatched, 40);
    expect(result.isTruncated, isTrue);
  });
}
