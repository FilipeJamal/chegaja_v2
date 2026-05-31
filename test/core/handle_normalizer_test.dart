import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/handles/handle_normalizer.dart';

void main() {
  group('HandleNormalizer', () {
    test('remove arroba inicial, trim, lowercase e acentos', () {
      expect(HandleNormalizer.normalize('@Maria_Bolos'), 'maria_bolos');
      expect(HandleNormalizer.normalize('Jo\u00e3o-Eletricista'),
          'joao-eletricista');
      expect(HandleNormalizer.normalize(' studio.arte '), 'studio.arte');
    });

    test('preserva espacos e caracteres invalidos para validacao rejeitar', () {
      expect(HandleNormalizer.normalize('Maria Bolos'), 'maria bolos');
      expect(HandleNormalizer.normalize('maria+bolos'), 'maria+bolos');
    });
  });
}
