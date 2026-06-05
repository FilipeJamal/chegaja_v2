import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/provider_custom_service.dart';

void main() {
  group('ProviderCustomService', () {
    test('cria id estavel a partir do nome escrito pelo prestador', () {
      final service = ProviderCustomService.fromInput(
        title: ' Consultora de Imagem ',
        description: ' Ajuda em estilo pessoal. ',
        aliasesText: ' moda, guarda-roupa, estilo ',
      );

      expect(service.id, 'custom_consultora_de_imagem');
      expect(service.title, 'Consultora de Imagem');
      expect(service.name, 'Consultora de Imagem');
      expect(service.description, 'Ajuda em estilo pessoal.');
      expect(service.aliases, ['moda', 'guarda-roupa', 'estilo']);
      expect(service.normalizedTitle, 'consultora de imagem');
      expect(
        service.normalizedSearchTerms,
        containsAll(['consultora de imagem', 'moda', 'guarda roupa']),
      );
    });

    test('serializa e parseia campos publicos seguros', () {
      const service = ProviderCustomService(
        id: 'custom_consultora_de_imagem',
        title: 'Consultora de imagem',
        description: 'Guarda-roupa, estilo pessoal e eventos.',
        aliases: ['moda', 'roupa'],
        normalizedTitle: 'consultora de imagem',
        normalizedSearchTerms: [
          'consultora de imagem',
          'guarda roupa estilo pessoal e eventos',
          'moda',
          'roupa',
        ],
      );

      expect(service.toMap(), {
        'id': 'custom_consultora_de_imagem',
        'title': 'Consultora de imagem',
        'name': 'Consultora de imagem',
        'description': 'Guarda-roupa, estilo pessoal e eventos.',
        'aliases': ['moda', 'roupa'],
        'normalizedTitle': 'consultora de imagem',
        'normalizedSearchTerms': [
          'consultora de imagem',
          'guarda roupa estilo pessoal e eventos',
          'moda',
          'roupa',
        ],
        'parentCategoryId': 'other',
        'taxonomySubcategoryId': 'other_service',
        'trustSafetyDecision': 'allow',
        'trustSafetyReasonCodes': <String>[],
        'isActive': true,
      });
      expect(ProviderCustomService.fromMap(service.toMap()), service);
    });

    test('ignora entradas invalidas e limita texto/listas', () {
      expect(ProviderCustomService.fromMap({'name': ''}), isNull);

      final service = ProviderCustomService.fromInput(
        title: 'A' * 120,
        description: 'B' * 400,
        aliasesText: List.generate(12, (index) => 'alias$index').join(','),
      );

      expect(service.name.length, 80);
      expect(service.description.length, 280);
      expect(service.aliases, hasLength(10));
    });

    test('filtra custom service proibido antigo mesmo sem decision bloqueada',
        () {
      final services = ProviderCustomService.listFrom([
        {
          'id': 'custom_prostituta',
          'title': 'prostituta',
          'description': 'trabalho com o corpo',
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_consultoria_de_imagem',
          'title': 'Consultoria de imagem',
          'description': 'Guarda-roupa e estilo pessoal.',
        },
      ]);

      expect(services.map((service) => service.id), [
        'custom_consultoria_de_imagem',
      ]);
    });

    test('filtra obscenidade em titulo, alias e termos normalizados antigos',
        () {
      final services = ProviderCustomService.listFrom([
        {
          'id': 'custom_puta',
          'title': 'puta',
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_alias_vadia',
          'title': 'Servico qualquer',
          'aliases': ['vadia'],
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_term_obfuscado',
          'title': 'Servico qualquer',
          'normalizedSearchTerms': ['p.u.t.a'],
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_computador',
          'title': 'Reparacao de computadores',
          'aliases': ['computador'],
        },
      ]);

      expect(services.map((service) => service.id), [
        'custom_computador',
      ]);
    });

    test('filtra servicos ilicitos antigos em titulo, alias e termos', () {
      final services = ProviderCustomService.listFrom([
        {
          'id': 'custom_assassino',
          'title': 'assassino',
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_alias_pedofilia',
          'title': 'Servico qualquer',
          'aliases': ['pedofilia'],
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_term_droga',
          'title': 'Servico qualquer',
          'normalizedSearchTerms': ['vender droga'],
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_documento_falso',
          'title': 'documento falso',
          'trustSafetyDecision': 'allow',
        },
        {
          'id': 'custom_consultoria_imagem',
          'title': 'Consultoria de imagem',
          'aliases': ['moda'],
        },
      ]);

      expect(services.map((service) => service.id), [
        'custom_consultoria_imagem',
      ]);
    });
  });
}
