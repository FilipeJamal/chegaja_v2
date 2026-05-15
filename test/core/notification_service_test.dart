import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/services/notification_service.dart';

void main() {
  test('saveTokenRecordForTesting writes token where Functions read it',
      () async {
    final firestore = FakeFirebaseFirestore();

    await NotificationService.saveTokenRecordForTesting(
      firestore: firestore,
      uid: 'user_1',
      token: 'token_abc_123',
    );

    final userDoc = await firestore.collection('users').doc('user_1').get();
    expect(userDoc.exists, isTrue);
    expect(userDoc.data()?['fcmToken'], 'token_abc_123');
    expect(userDoc.data()?['fcmTokenPlatform'], isNotEmpty);

    final tokenDoc = await firestore
        .collection('users')
        .doc('user_1')
        .collection('fcmTokens')
        .doc('token_abc_123')
        .get();
    expect(tokenDoc.exists, isTrue);
    expect(tokenDoc.data()?['token'], 'token_abc_123');
    expect(tokenDoc.data()?['platform'], userDoc.data()?['fcmTokenPlatform']);
  });

  test('saveTokenRecordForTesting ignores blank token', () async {
    final firestore = FakeFirebaseFirestore();

    await NotificationService.saveTokenRecordForTesting(
      firestore: firestore,
      uid: 'user_1',
      token: '   ',
    );

    final userDoc = await firestore.collection('users').doc('user_1').get();
    expect(userDoc.exists, isFalse);
  });
}
