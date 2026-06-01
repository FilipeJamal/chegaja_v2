import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/catalog/service_taxonomy_normalizer.dart';

void main() {
  group('ServiceTaxonomyNormalizer', () {
    test('remove acentos e normaliza caixa', () {
      expect(
        ServiceTaxonomyNormalizer.normalize('Água a Pingar'),
        'agua a pingar',
      );
      expect(
        ServiceTaxonomyNormalizer.normalize('Bolo de aniversário'),
        'bolo de aniversario',
      );
    });

    test('remove pontuacao irrelevante e normaliza espacos', () {
      expect(
        ServiceTaxonomyNormalizer.normalize('Arranjar luz!!!'),
        'arranjar luz',
      );
      expect(
        ServiceTaxonomyNormalizer.normalize('  PC   lento  '),
        'pc lento',
      );
    });

    test('tokenize preserva termos importantes', () {
      expect(
        ServiceTaxonomyNormalizer.tokenize('senhora para limpar casa'),
        containsAll(['senhora', 'limpar', 'casa']),
      );
    });
  });
}
