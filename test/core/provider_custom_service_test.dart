import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/catalog/provider_custom_service.dart';

void main() {
  group('ProviderCustomService', () {
    test('cria id estavel a partir do nome escrito pelo prestador', () {
      final service = ProviderCustomService.fromInput(
        name: ' Consultora de Imagem ',
        description: ' Ajuda em estilo pessoal. ',
      );

      expect(service.id, 'custom_consultora_de_imagem');
      expect(service.name, 'Consultora de Imagem');
      expect(service.description, 'Ajuda em estilo pessoal.');
    });

    test('serializa e parseia campos publicos seguros', () {
      const service = ProviderCustomService(
        id: 'custom_consultora_de_imagem',
        name: 'Consultora de imagem',
        description: 'Guarda-roupa, estilo pessoal e eventos.',
      );

      expect(service.toMap(), {
        'id': 'custom_consultora_de_imagem',
        'name': 'Consultora de imagem',
        'description': 'Guarda-roupa, estilo pessoal e eventos.',
      });
      expect(ProviderCustomService.fromMap(service.toMap()), service);
    });

    test('ignora entradas invalidas e texto demasiado longo', () {
      expect(ProviderCustomService.fromMap({'name': ''}), isNull);

      final service = ProviderCustomService.fromInput(
        name: 'A' * 120,
        description: 'B' * 400,
      );

      expect(service.name.length, 80);
      expect(service.description.length, 280);
    });
  });
}
