import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/trust_safety/trust_safety_text_normalizer.dart';

void main() {
  group('TrustSafetyTextNormalizer', () {
    test('remove acentos e normaliza maiusculas', () {
      expect(
        TrustSafetyTextNormalizer.normalize('Prostituição'),
        'prostituicao',
      );
      expect(
        TrustSafetyTextNormalizer.normalize('TRÁFICO de Drogas'),
        'trafico de drogas',
      );
    });

    test('normaliza espacos e pontuacao irrelevante', () {
      expect(
        TrustSafetyTextNormalizer.normalize('  Armas   ilegais!!! '),
        'armas ilegais',
      );
      expect(
        TrustSafetyTextNormalizer.normalize('servicos-sexuais / adultos'),
        'servicos sexuais adultos',
      );
    });

    test('preserva palavras importantes para classificacao', () {
      expect(
        TrustSafetyTextNormalizer.normalize('Falsificação de documentos'),
        contains('falsificacao de documentos'),
      );
      expect(
        TrustSafetyTextNormalizer.normalize('Cuidados infantis em casa'),
        contains('cuidados infantis'),
      );
    });
  });
}
