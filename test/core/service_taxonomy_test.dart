import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/catalog/service_intent.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_catalog.dart';
import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/servico.dart';

void main() {
  group('ServiceTaxonomyCatalog', () {
    test('inclui categorias principais profissionais', () {
      final ids = ServiceTaxonomyCatalog.categories.map((c) => c.id).toSet();

      expect(ids, contains('home_repairs'));
      expect(ids, contains('cleaning_maintenance'));
      expect(ids, contains('food_catering'));
      expect(ids, contains('technology'));
      expect(ids, contains('education'));
      expect(ids, contains('care'));
      expect(ids, contains('other'));
    });

    test('ids de categorias e subcategorias sao unicos e estaveis', () {
      final categoryIds = ServiceTaxonomyCatalog.categories.map((c) => c.id);
      final subcategoryIds =
          ServiceTaxonomyCatalog.subcategories.map((s) => s.id);

      expect(categoryIds.toSet().length, categoryIds.length);
      expect(subcategoryIds.toSet().length, subcategoryIds.length);
      expect(
        ServiceTaxonomyCatalog.findSubcategoryById('plumbing')?.label,
        'Canalizacao',
      );
    });

    test('subcategorias apontam para categorias validas e intents coerentes',
        () {
      final categoryIds =
          ServiceTaxonomyCatalog.categories.map((c) => c.id).toSet();

      for (final subcategory in ServiceTaxonomyCatalog.subcategories) {
        expect(categoryIds, contains(subcategory.parentCategoryId));
        expect(subcategory.allowedIntents, isNotEmpty);
        expect(subcategory.allowedIntents, contains(subcategory.defaultIntent));
        expect(subcategory.aliases, isNotEmpty);
      }
    });

    test('categorias sensiveis preservam requisitos da M2.20', () {
      final electricity =
          ServiceTaxonomyCatalog.findSubcategoryById('electricity')!;
      final childCare =
          ServiceTaxonomyCatalog.findSubcategoryById('child_care')!;
      final catering = ServiceTaxonomyCatalog.findSubcategoryById('catering')!;

      expect(electricity.requiresApproval, isTrue);
      expect(electricity.sensitiveRequirementId, 'electricity');
      expect(electricity.riskLevel, CategoryRiskLevel.sensitive);
      expect(childCare.sensitiveRequirementId, 'child_care');
      expect(catering.sensitiveRequirementId, 'professional_food');
    });

    test('mapeia servicos antigos conhecidos para subcategoria canonica', () {
      const canalizador = Servico(
        id: 'canalizador',
        name: 'Canalizador',
        mode: 'IMEDIATO',
        keywords: ['agua', 'cano'],
        isActive: true,
      );
      const bolo = Servico(
        id: 'bolos_personalizados',
        name: 'Bolos personalizados',
        mode: 'POR_PROPOSTA',
        keywords: ['bolo'],
        isActive: true,
      );

      expect(
        ServiceTaxonomyCatalog.mapLegacyServicoToSubcategory(canalizador)?.id,
        'plumbing',
      );
      expect(
        ServiceTaxonomyCatalog.mapLegacyServicoToSubcategory(bolo)?.id,
        'cakes_confectionery',
      );
      expect(ServiceIntentX.fromLegacyMode(bolo.mode), ServiceIntent.quote);
    });
  });
}
