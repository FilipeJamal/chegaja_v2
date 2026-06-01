import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/provider_custom_service.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/service_safety_guard.dart';

void main() {
  group('ServiceSafetyGuard', () {
    test('bloqueia termos proibidos e obfuscacoes simples', () {
      const blockedTexts = [
        'puta',
        'p.u.t.a',
        'p-u-t-a',
        'p u t a',
        'p*uta',
        'prostituta',
        'pr0stituta',
        'prostitui\u00e7\u00e3o',
        'prostituicao',
        'garota de programa',
        'programa sexual',
        'servi\u00e7os sexuais',
        'vadia',
        'drogas',
        'tr\u00e1fico',
        'trafico',
        'armas ilegais',
        'falsifica\u00e7\u00e3o de documentos',
      ];

      for (final text in blockedTexts) {
        final result = ServiceSafetyGuard.classifyServiceText(text);
        expect(
          result.decision,
          TrustSafetyDecision.block,
          reason: text,
        );
        expect(result.messageForUser, isNot(contains(text)));
      }
    });

    test('nao bloqueia palavras legitimas por substring', () {
      const allowedTexts = [
        'computador',
        'repara\u00e7\u00e3o de computadores',
        'reputa\u00e7\u00e3o online',
        'disputa contratual',
        'consultoria de imagem',
        'repara\u00e7\u00e3o de m\u00e1quina',
      ];

      for (final text in allowedTexts) {
        expect(
          ServiceSafetyGuard.isServiceTextBlocked(text),
          isFalse,
          reason: text,
        );
      }
    });

    test('filtra nomes e termos pesquisaveis contaminados', () {
      expect(
        ServiceSafetyGuard.filterAllowedServiceNames([
          'Canalizador',
          'puta',
          'prostituta',
          'Consultoria de imagem',
          'vadia',
        ]),
        ['Canalizador', 'Consultoria de imagem'],
      );

      expect(
        ServiceSafetyGuard.filterAllowedSearchTerms([
          'canalizacao',
          'p.u.t.a',
          'moda',
          'pr0stituta',
        ]),
        ['canalizacao', 'moda'],
      );
    });

    test('filtra custom services contaminados antes de renderizar ou pesquisar',
        () {
      const clean = ProviderCustomService(
        id: 'custom_consultoria_de_imagem',
        title: 'Consultoria de imagem',
        description: 'Guarda-roupa e estilo pessoal.',
        aliases: ['moda'],
      );
      const blockedTitle = ProviderCustomService(
        id: 'custom_puta',
        title: 'puta',
        description: 'conteudo antigo',
      );
      const blockedAlias = ProviderCustomService(
        id: 'custom_alias',
        title: 'Servico qualquer',
        aliases: ['p-u-t-a'],
      );

      expect(
        ServiceSafetyGuard.filterAllowedCustomServices([
          clean,
          blockedTitle,
          blockedAlias,
        ]),
        [clean],
      );
    });

    test('sanitizeProviderServices remove dados persistidos proibidos', () {
      final result = ServiceSafetyGuard.sanitizeProviderServices(
        servicos: ['custom_puta', 'plumbing'],
        servicosNomes: ['puta', 'Canalizador', 'vadia'],
        customServiceNames: ['p.u.t.a', 'Consultoria de imagem'],
        customServiceSearchTerms: ['canalizacao', 'prostituta', 'moda'],
        customServices: const [
          {
            'id': 'custom_puta',
            'title': 'puta',
            'trustSafetyDecision': 'allow',
          },
          {
            'id': 'custom_consultoria_de_imagem',
            'title': 'Consultoria de imagem',
            'description': 'Guarda-roupa.',
            'aliases': ['moda'],
          },
        ],
      );

      expect(result.removedAny, isTrue);
      expect(result.serviceIds, {'plumbing'});
      expect(result.serviceNames, ['Canalizador', 'Consultoria de imagem']);
      expect(result.customServiceNames, ['Consultoria de imagem']);
      expect(
        result.customServiceSearchTerms,
        containsAll(['canalizacao', 'moda', 'consultoria de imagem']),
      );
      expect(result.customServiceSearchTerms, isNot(contains('prostituta')));
      expect(result.customServices.map((service) => service.id), [
        'custom_consultoria_de_imagem',
      ]);
    });
  });
}
