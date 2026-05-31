import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/services/handle_service.dart';

void main() {
  group('HandleService', () {
    test('checkAvailability chama callable e parseia resposta', () async {
      final calls = <Map<String, dynamic>>[];
      final service = HandleService(
        callFunction: (name, payload) async {
          calls.add(<String, dynamic>{'__name': name, ...payload});
          return {
            'normalizedHandle': 'maria_bolos',
            'available': true,
            'reason': 'available',
            'message': '',
          };
        },
      );

      final result = await service.checkAvailability('@Maria_Bolos');

      expect(calls.single['__name'], 'handle_checkAvailability');
      expect(calls.single['handle'], '@Maria_Bolos');
      expect(result.normalizedHandle, 'maria_bolos');
      expect(result.available, isTrue);
    });

    test('reserveProviderHandle chama callable e parseia handle reservado',
        () async {
      final service = HandleService(
        callFunction: (name, payload) async {
          expect(name, 'handle_reserveProviderHandle');
          expect(payload['handle'], 'maria_bolos');
          return {
            'handle': 'maria_bolos',
            'handleDisplay': '@maria_bolos',
            'uid': 'provider1',
            'status': 'active',
          };
        },
      );

      final result = await service.reserveProviderHandle('maria_bolos');

      expect(result.handle, 'maria_bolos');
      expect(result.uid, 'provider1');
      expect(result.status.name, 'active');
    });
  });
}
