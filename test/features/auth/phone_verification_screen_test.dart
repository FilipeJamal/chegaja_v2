import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/features/auth/phone_verification_screen.dart';

void main() {
  test('phone identity requires a non-anonymous user and a phone', () {
    expect(
      AuthService.isVerifiedPhoneIdentity(
        isAnonymous: true,
        phoneNumber: '+258840000000',
      ),
      isFalse,
    );
    expect(
      AuthService.isVerifiedPhoneIdentity(
        isAnonymous: false,
        phoneNumber: null,
      ),
      isFalse,
    );
    expect(
      AuthService.isVerifiedPhoneIdentity(
        isAnonymous: false,
        phoneNumber: '+258840000000',
      ),
      isTrue,
    );
  });

  testWidgets('verification explains private use of the phone', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhoneVerificationScreen(action: 'publicar um pedido'),
      ),
    );
    expect(find.textContaining('publicar um pedido'), findsOneWidget);
    expect(find.textContaining('O numero e privado'), findsOneWidget);
    expect(find.byKey(const Key('phone_verification_phone_field')),
        findsOneWidget);
  });
}
