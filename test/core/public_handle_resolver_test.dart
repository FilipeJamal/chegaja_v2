import 'package:chegaja_v2/core/handles/public_handle_resolver.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PublicHandleResolver', () {
    test('handle active/prestador retorna uid e handle', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('handles').doc('maria_bolos').set({
        'handle': 'maria_bolos',
        'handleDisplay': '@maria_bolos',
        'uid': 'prestador1',
        'role': 'prestador',
        'status': 'active',
      });

      final result =
          await PublicHandleResolver(firestore: db).resolve('@Maria_Bolos');

      expect(result.status, PublicHandleResolveStatus.resolved);
      expect(result.uid, 'prestador1');
      expect(result.handle, 'maria_bolos');
      expect(result.handleDisplay, '@maria_bolos');
    });

    test('handle inexistente retorna notFound', () async {
      final db = FakeFirebaseFirestore();

      final result =
          await PublicHandleResolver(firestore: db).resolve('maria_bolos');

      expect(result.status, PublicHandleResolveStatus.notFound);
      expect(result.uid, isNull);
    });

    test('status released ou blocked nao resolve perfil publico', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('handles').doc('old_name').set({
        'handle': 'old_name',
        'uid': 'prestador1',
        'role': 'prestador',
        'status': 'released',
      });
      await db.collection('handles').doc('blocked_name').set({
        'handle': 'blocked_name',
        'uid': 'prestador2',
        'role': 'prestador',
        'status': 'blocked',
      });

      final released =
          await PublicHandleResolver(firestore: db).resolve('old_name');
      final blocked =
          await PublicHandleResolver(firestore: db).resolve('blocked_name');

      expect(released.status, PublicHandleResolveStatus.inactive);
      expect(blocked.status, PublicHandleResolveStatus.inactive);
    });

    test('role diferente de prestador retorna invalidRole', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('handles').doc('cliente_maria').set({
        'handle': 'cliente_maria',
        'uid': 'cliente1',
        'role': 'cliente',
        'status': 'active',
      });

      final result =
          await PublicHandleResolver(firestore: db).resolve('cliente_maria');

      expect(result.status, PublicHandleResolveStatus.invalidRole);
    });

    test('uid ausente retorna invalidData', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('handles').doc('sem_uid').set({
        'handle': 'sem_uid',
        'role': 'prestador',
        'status': 'active',
      });

      final result =
          await PublicHandleResolver(firestore: db).resolve('sem_uid');

      expect(result.status, PublicHandleResolveStatus.invalidData);
    });

    test('handle invalido retorna invalidHandle', () async {
      final db = FakeFirebaseFirestore();

      final result = await PublicHandleResolver(firestore: db).resolve('ab');

      expect(result.status, PublicHandleResolveStatus.invalidHandle);
    });
  });
}
