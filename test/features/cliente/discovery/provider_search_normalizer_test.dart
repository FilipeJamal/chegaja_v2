import 'package:chegaja_v2/features/cliente/discovery/provider_search_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderSearchNormalizer', () {
    test('remove acentos e normaliza maiusculas', () {
      expect(
        ProviderSearchNormalizer.normalize(
          'Confeiteira de Anivers\u00e1rio',
        ),
        'confeiteira de aniversario',
      );
    });

    test('remove pontuacao e espacos duplicados', () {
      expect(
        ProviderSearchNormalizer.normalize('  Jo\u00e3o---Silva!!  '),
        'joao silva',
      );
    });

    test('normaliza handle futuro sem expor simbolos', () {
      expect(
        ProviderSearchNormalizer.normalize('@Meu-Perfil'),
        'meu perfil',
      );
    });

    test('normaliza listas removendo vazios e duplicados', () {
      expect(
        ProviderSearchNormalizer.normalizeTerms([
          'Canaliza\u00e7\u00e3o',
          ' canalizacao ',
          '',
          'Coimbra!',
        ]),
        ['canalizacao', 'coimbra'],
      );
    });
  });
}
