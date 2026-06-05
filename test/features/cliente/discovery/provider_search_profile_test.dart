import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderSearchProfile.fromPrestadorDoc', () {
    test('mapeia campos atuais e legados de perfil publico', () {
      final profile = ProviderSearchProfile.fromPrestadorDoc(
        id: ' prestador_1 ',
        data: {
          'nome': 'Jo\u00e3o Silva',
          'displayName': 'Nome secundario',
          'photoUrl': 'https://example.com/foto.jpg',
          'bio': 'Canalizador experiente',
          'city': 'Coimbra',
          'country': 'Portugal',
          'servicosNomes': ['Canaliza\u00e7\u00e3o', 'Instala\u00e7\u00e3o'],
          'categories': ['Casa', 'Canalizacao'],
          'servicos': ['svc_canalizacao'],
          'approvedSensitiveCategoryIds': ['electricity'],
          'approvedSensitiveCategoryNames': ['Eletricidade'],
          'portfolioUrls': [
            'https://example.com/obra-1.jpg',
            '',
            'https://example.com/obra-1.jpg',
            'https://example.com/obra-2.jpg',
          ],
          'ratingAvg': 4.8,
          'ratingCount': 12,
          'geo': {
            'geopoint': const GeoPoint(40.2, -8.4),
          },
        },
      );

      expect(profile.id, 'prestador_1');
      expect(profile.displayName, 'Jo\u00e3o Silva');
      expect(profile.photoUrl, 'https://example.com/foto.jpg');
      expect(profile.bio, 'Canalizador experiente');
      expect(profile.city, 'Coimbra');
      expect(profile.country, 'Portugal');
      expect(
          profile.services, ['Canaliza\u00e7\u00e3o', 'Instala\u00e7\u00e3o']);
      expect(profile.categories, ['Casa', 'Canalizacao', 'svc_canalizacao']);
      expect(profile.approvedSensitiveCategoryIds, ['electricity']);
      expect(profile.approvedSensitiveCategoryNames, ['Eletricidade']);
      expect(profile.hasApprovedSensitiveCategories, isTrue);
      expect(profile.portfolioPreviewUrls, [
        'https://example.com/obra-1.jpg',
        'https://example.com/obra-2.jpg',
      ]);
      expect(profile.ratingAvg, 4.8);
      expect(profile.ratingCount, 12);
      expect(profile.hasValidRating, isTrue);
      expect(profile.latitude, 40.2);
      expect(profile.longitude, -8.4);
      expect(profile.isSearchableLocal, isTrue);
    });

    test('usa fallbacks de nome foto bio localizacao e portfolio', () {
      final profile = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_2',
        data: {
          'name': 'Maria Bolos',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'descricao': 'Bolos personalizados',
          'cidade': 'Lisboa',
          'pais': 'Portugal',
          'portfolioImages': ['https://example.com/bolo.jpg'],
          'lastLocation': {'lat': 38.7, 'lng': -9.1},
        },
      );

      expect(profile.displayName, 'Maria Bolos');
      expect(profile.photoUrl, 'https://example.com/avatar.jpg');
      expect(profile.bio, 'Bolos personalizados');
      expect(profile.city, 'Lisboa');
      expect(profile.country, 'Portugal');
      expect(profile.portfolioPreviewUrls, ['https://example.com/bolo.jpg']);
      expect(profile.latitude, 38.7);
      expect(profile.longitude, -9.1);
    });

    test('ignora campos privados e ratingSum', () {
      final profile = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_3',
        data: {
          'nome': 'Ana Reparacoes',
          'city': 'Porto',
          'phone': '+351900000000',
          'phoneRaw': '900000000',
          'email': 'ana@example.com',
          'address': 'Rua Privada',
          'privateContacts': {'phone': 'secret'},
          'fcmTokens': ['token'],
          'kyc': {'status': 'approved'},
          'payment': {'iban': 'secret'},
          'admin': {'note': 'internal'},
          'ratingAvg': 4.2,
          'ratingCount': 3,
          'ratingSum': 99,
        },
      );

      final searchable = profile.searchText;
      expect(searchable, contains('ana reparacoes'));
      expect(searchable, contains('porto'));
      expect(searchable, isNot(contains('900000000')));
      expect(searchable, isNot(contains('ana example com')));
      expect(searchable, isNot(contains('rua privada')));
      expect(searchable, isNot(contains('secret')));
      expect(searchable, isNot(contains('99')));
    });

    test('mapeia handle e inclui nos termos pesquisaveis', () {
      final profile = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_handle',
        data: {
          'nome': 'Maria Bolos',
          'city': 'Lisboa',
          'handle': 'maria_bolos',
        },
      );

      expect(profile.handle, 'maria_bolos');
      expect(profile.searchText, contains('maria bolos'));
    });

    test('mapeia aprovacoes de categoria e inclui nos termos pesquisaveis', () {
      final profile = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_aprovado',
        data: {
          'nome': 'Ema Eletrica',
          'city': 'Porto',
          'approvedSensitiveCategoryIds': ['electricity', 'gas'],
          'approvedSensitiveCategoryNames': ['Eletricidade', 'Gas'],
        },
      );

      expect(profile.approvedSensitiveCategoryIds, ['electricity', 'gas']);
      expect(profile.approvedSensitiveCategoryNames, ['Eletricidade', 'Gas']);
      expect(profile.hasApprovedSensitiveCategories, isTrue);
      expect(profile.searchText, contains('eletricidade'));
      expect(profile.searchText, contains('gas'));
    });

    test('inclui servicos personalizados e detalhes nos termos pesquisaveis',
        () {
      final profile = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_custom',
        data: {
          'nome': 'Lia Estilo',
          'city': 'Lisboa',
          'servicosNomes': ['Consultora de imagem'],
          'customServices': [
            {
              'id': 'custom_consultora_de_imagem',
              'title': 'Consultora de imagem',
              'description':
                  'Consultoria de imagem pessoal, guarda-roupa e eventos.',
              'aliases': ['moda', 'roupa'],
              'normalizedSearchTerms': [
                'consultora de imagem',
                'moda',
                'roupa',
              ],
            },
          ],
        },
      );

      expect(profile.services, contains('Consultora de imagem'));
      expect(profile.searchText, contains('consultora de imagem'));
      expect(profile.searchText, contains('guarda roupa'));
      expect(profile.searchText, contains('eventos'));
      expect(profile.searchText, contains('moda'));
    });

    test('filtra servicos personalizados proibidos vindos de dados antigos',
        () {
      final profile = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_custom_bloqueado',
        data: {
          'nome': 'Perfil antigo',
          'city': 'Lisboa',
          'servicos': [
            'custom_prostituta',
            'custom_puta',
            'custom_assassino',
            'plumbing',
          ],
          'servicosNomes': [
            'prostituta',
            'puta',
            'vadia',
            'burlador',
            'burlas',
            'servico especial',
            'assassino',
            'pedofilia',
            'vender droga',
            'documento falso',
            'Canalizacao',
          ],
          'categories': ['puta', 'burlador', 'assassino', 'Casa'],
          'customServiceNames': [
            'prostituta',
            'p.u.t.a',
            'burlador',
            'documento falso',
            'contactos especiais',
          ],
          'customServiceSearchTerms': [
            'prostituta',
            'vadia',
            'b u r l a',
            'vender droga',
            'trabalho secreto',
          ],
          'customServices': [
            {
              'id': 'custom_prostituta',
              'title': 'prostituta',
              'description': 'trabalho com o corpo',
              'trustSafetyDecision': 'allow',
            },
            {
              'id': 'custom_puta',
              'title': 'p-u-t-a',
              'trustSafetyDecision': 'allow',
            },
            {
              'id': 'custom_assassino',
              'title': 'assassino',
              'trustSafetyDecision': 'allow',
            },
            {
              'id': 'custom_burlador',
              'title': 'burlador',
              'trustSafetyDecision': 'allow',
            },
            {
              'id': 'custom_unknown',
              'title': 'servico especial',
              'description': 'coisa discreta',
              'trustSafetyDecision': 'allow',
            },
          ],
        },
      );

      expect(profile.services, ['Canalizacao']);
      expect(profile.categories, ['Casa', 'plumbing']);
      expect(profile.searchText, isNot(contains('prostituta')));
      expect(profile.searchText, isNot(contains('puta')));
      expect(profile.searchText, isNot(contains('vadia')));
      expect(profile.searchText, isNot(contains('burlador')));
      expect(profile.searchText, isNot(contains('burlas')));
      expect(profile.searchText, isNot(contains('servico especial')));
      expect(profile.searchText, isNot(contains('assassino')));
      expect(profile.searchText, isNot(contains('pedofilia')));
      expect(profile.searchText, isNot(contains('vender droga')));
      expect(profile.searchText, isNot(contains('documento falso')));
    });

    test('valida rating apenas com ratingAvg e ratingCount seguros', () {
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'valid',
          data: {
            'nome': 'Valid',
            'city': 'Lisboa',
            'ratingAvg': 5,
            'ratingCount': 1,
          },
        ).hasValidRating,
        isTrue,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'zero_count',
          data: {
            'nome': 'Zero',
            'city': 'Lisboa',
            'ratingAvg': 5,
            'ratingCount': 0,
          },
        ).hasValidRating,
        isFalse,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'missing_avg',
          data: {'nome': 'Missing', 'city': 'Lisboa', 'ratingCount': 2},
        ).hasValidRating,
        isFalse,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'low',
          data: {
            'nome': 'Low',
            'city': 'Lisboa',
            'ratingAvg': 0.5,
            'ratingCount': 2
          },
        ).hasValidRating,
        isFalse,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'high',
          data: {
            'nome': 'High',
            'city': 'Lisboa',
            'ratingAvg': 5.5,
            'ratingCount': 2
          },
        ).hasValidRating,
        isFalse,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'string',
          data: {
            'nome': 'String',
            'city': 'Lisboa',
            'ratingAvg': '5',
            'ratingCount': 2
          },
        ).hasValidRating,
        isFalse,
      );
    });

    test('calcula pesquisavel local com nome e dado complementar', () {
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'service',
          data: {
            'nome': 'Joao',
            'servicosNomes': ['Canalizacao']
          },
        ).isSearchableLocal,
        isTrue,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'city',
          data: {'nome': 'Joao', 'city': 'Coimbra'},
        ).isSearchableLocal,
        isTrue,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'portfolio',
          data: {
            'nome': 'Joao',
            'portfolioUrls': ['https://example.com/obra.jpg'],
          },
        ).isSearchableLocal,
        isTrue,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'no_name',
          data: {
            'city': 'Coimbra',
            'servicosNomes': ['Canalizacao']
          },
        ).isSearchableLocal,
        isFalse,
      );
      expect(
        ProviderSearchProfile.fromPrestadorDoc(
          id: 'only_name',
          data: {'nome': 'Joao'},
        ).isSearchableLocal,
        isFalse,
      );
    });
  });
}
