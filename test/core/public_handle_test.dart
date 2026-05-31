import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/public_handle.dart';

void main() {
  group('PublicHandle', () {
    test('serializa e parseia status valido', () {
      const handle = PublicHandle(
        handle: 'maria_bolos',
        uid: 'provider1',
        role: 'prestador',
        status: PublicHandleStatus.active,
        source: 'prestador_profile',
      );

      final map = handle.toMap();
      expect(map['handle'], 'maria_bolos');
      expect(map['uid'], 'provider1');
      expect(map['role'], 'prestador');
      expect(map['status'], 'active');

      final parsed = PublicHandle.fromMap(
        id: 'maria_bolos',
        data: map,
      );

      expect(parsed?.handle, 'maria_bolos');
      expect(parsed?.uid, 'provider1');
      expect(parsed?.status, PublicHandleStatus.active);
    });

    test('rejeita mapas invalidos defensivamente', () {
      expect(
        PublicHandle.fromMap(
          id: 'bad',
          data: const {'uid': '', 'role': 'prestador', 'status': 'active'},
        ),
        isNull,
      );
      expect(
        PublicHandle.fromMap(
          id: 'bad',
          data: const {
            'uid': 'provider1',
            'role': 'prestador',
            'status': 'unknown',
          },
        ),
        isNull,
      );
    });
  });
}
