import 'package:chegaja_v2/features/cliente/discovery/provider_search_matcher.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderSearchMatcher', () {
    final profile = ProviderSearchProfile.fromPrestadorDoc(
      id: 'prestador_1',
      data: {
        'nome': 'Jo\u00e3o Silva',
        'bio': 'Especialista em reparos urgentes',
        'city': 'Coimbra',
        'country': 'Portugal',
        'servicosNomes': ['Canaliza\u00e7\u00e3o'],
        'categories': ['Casa'],
        'ratingAvg': 4.7,
        'ratingCount': 8,
      },
    );

    test('encontra por nome, servico, categoria e cidade', () {
      expect(matchesProviderSearch(profile, 'joao'), isTrue);
      expect(matchesProviderSearch(profile, 'canalizacao'), isTrue);
      expect(matchesProviderSearch(profile, 'casa'), isTrue);
      expect(matchesProviderSearch(profile, 'coimbra'), isTrue);
    });

    test('busca ignora acentos e caixa', () {
      expect(matchesProviderSearch(profile, 'JO\u00c3O'), isTrue);
      expect(matchesProviderSearch(profile, 'canaliza\u00e7\u00e3o'), isTrue);
    });

    test('query vazia ou curta nao retorna match', () {
      expect(matchesProviderSearch(profile, ''), isFalse);
      expect(matchesProviderSearch(profile, 'j'), isFalse);
    });

    test('nao depende de rating para match textual', () {
      final noRating = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_2',
        data: {
          'nome': 'Maria Bolos',
          'city': 'Lisboa',
          'servicosNomes': ['Bolos personalizados'],
        },
      );

      expect(noRating.hasValidRating, isFalse);
      expect(matchesProviderSearch(noRating, 'bolos'), isTrue);
    });

    test('encontra prestador por servico personalizado salvo pelo prestador',
        () {
      final custom = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_consultora_imagem',
        data: {
          'nome': 'Lia Estilo',
          'city': 'Lisboa',
          'servicos': ['custom_consultora_de_imagem'],
          'servicosNomes': ['Consultora de imagem'],
          'customServices': [
            {
              'id': 'custom_consultora_de_imagem',
              'title': 'Consultora de imagem',
              'description':
                  'Consultoria de imagem pessoal, guarda-roupa e eventos.',
              'aliases': ['moda', 'roupa'],
            },
          ],
        },
      );

      expect(matchesProviderSearch(custom, 'consultora de imagem'), isTrue);
      expect(matchesProviderSearch(custom, 'guarda roupa'), isTrue);
      expect(matchesProviderSearch(custom, 'moda'), isTrue);
      expect(matchesProviderSearch(custom, 'outro'), isFalse);
    });

    test('pontua nome acima de bio e servico acima de bio', () {
      final byName = scoreProviderSearch(profile, 'joao');
      final byService = scoreProviderSearch(profile, 'canalizacao');
      final byBio = scoreProviderSearch(profile, 'urgentes');

      expect(byName, greaterThan(byBio));
      expect(byService, greaterThan(byBio));
    });

    test('rating nao supera match textual principal', () {
      final weakTextHighRating = ProviderSearchProfile.fromPrestadorDoc(
        id: 'prestador_3',
        data: {
          'nome': 'Outro Profissional',
          'bio': 'Reparos gerais',
          'city': 'Lisboa',
          'ratingAvg': 5,
          'ratingCount': 100,
        },
      );

      expect(
        scoreProviderSearch(profile, 'joao'),
        greaterThan(scoreProviderSearch(weakTextHighRating, 'reparos')),
      );
    });
  });
}
