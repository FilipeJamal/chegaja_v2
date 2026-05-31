import 'package:chegaja_v2/core/services/public_profile_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PublicProfileLinkService', () {
    test('gera path publico normalizado por handle', () {
      expect(
        PublicProfileLinkService.publicPathForHandle('@Maria_Bolos'),
        '/p/maria_bolos',
      );
      expect(
        PublicProfileLinkService.publicPathForHandle('Joao-Eletricista'),
        '/p/joao-eletricista',
      );
    });

    test('gera URL absoluta com base default ou customizada', () {
      expect(
        PublicProfileLinkService.publicUrlForHandle('maria_bolos'),
        'https://chegaja-ac88d.web.app/p/maria_bolos',
      );
      expect(
        PublicProfileLinkService.publicUrlForHandle(
          'maria_bolos',
          baseUrl: 'https://chegaja.pt/',
        ),
        'https://chegaja.pt/p/maria_bolos',
      );
    });

    test('gera texto de partilha seguro sem dados privados', () {
      final text = PublicProfileLinkService.shareTextForProvider(
        displayName: 'Maria Bolos',
        handle: 'maria_bolos',
      );

      expect(text, contains('Maria Bolos'));
      expect(text, contains('https://chegaja-ac88d.web.app/p/maria_bolos'));
      expect(text, isNot(contains('telefone')));
      expect(text, isNot(contains('email')));
      expect(text, isNot(contains('verificado')));
      expect(text, isNot(contains('certificado')));
      expect(text, isNot(contains('garantido')));
    });

    test('rejeita handle vazio ou invalido', () {
      expect(
        () => PublicProfileLinkService.publicPathForHandle(''),
        throwsArgumentError,
      );
      expect(
        () => PublicProfileLinkService.publicUrlForHandle('ab'),
        throwsArgumentError,
      );
    });

    test('gera URLs de WhatsApp e Facebook', () {
      final url = PublicProfileLinkService.publicUrlForHandle('maria_bolos');
      final text = PublicProfileLinkService.shareTextForProvider(
        displayName: 'Maria Bolos',
        handle: 'maria_bolos',
      );

      expect(
        PublicProfileLinkService.whatsAppShareUri(text).toString(),
        startsWith('https://wa.me/?text='),
      );
      expect(
        PublicProfileLinkService.facebookShareUri(url).toString(),
        startsWith('https://www.facebook.com/sharer/sharer.php?u='),
      );
    });
  });
}
