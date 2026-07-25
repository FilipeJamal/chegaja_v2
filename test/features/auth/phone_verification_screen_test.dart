import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/config/market_config.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/features/auth/phone_verification_screen.dart';

void main() {
  test('phone identity requires a non-anonymous user and a phone', () {
    expect(
      AuthService.isVerifiedPhoneIdentity(
        isAnonymous: true,
        phoneNumber: '+351912345678',
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
        phoneNumber: '+351912345678',
      ),
      isTrue,
    );
  });

  test('changing the active role preserves the verified role history', () {
    expect(
      AuthService.mergeRoleHistory(
        const {'cliente': true},
        activeRole: 'prestador',
      ),
      const {
        'cliente': true,
        'prestador': true,
      },
    );
    expect(
      AuthService.mergeRoleHistory(
        const {
          'cliente': true,
          'prestador': false,
          'admin': true,
        },
        activeRole: 'prestador',
      ),
      const {
        'cliente': true,
        'prestador': true,
      },
      reason: 'Only the two user roles may be persisted by the client.',
    );
  });

  group('market-aware phone policy', () {
    test('normalizes and validates Coimbra mobile numbers', () {
      expect(
        AuthService.normalizePhoneForMarket(
          '912 345 678',
          market: MarketConfig.coimbraPilot,
        ),
        '+351912345678',
      );
      expect(
        AuthService.normalizePhoneForMarket(
          '00351 912 345 678',
          market: MarketConfig.coimbraPilot,
        ),
        '+351912345678',
      );
      expect(
        AuthService.isValidPhoneForMarket(
          '+351 912 345 678',
          market: MarketConfig.coimbraPilot,
        ),
        isTrue,
      );
      expect(
        AuthService.isValidPhoneForMarket(
          '+258 84 000 0000',
          market: MarketConfig.coimbraPilot,
        ),
        isFalse,
      );
      expect(
        AuthService.isValidPhoneForMarket(
          '+351 212 345 678',
          market: MarketConfig.coimbraPilot,
        ),
        isFalse,
        reason: 'Phone Auth requires an SMS-capable mobile number.',
      );
    });

    test('preserves the historical Maputo adaptation', () {
      expect(
        AuthService.normalizePhoneForMarket(
          '84 000 0000',
          market: MarketConfig.maputoAdaptation,
        ),
        '+258840000000',
      );
      expect(
        AuthService.isValidPhoneForMarket(
          '+258840000000',
          market: MarketConfig.maputoAdaptation,
        ),
        isTrue,
      );
      expect(
        AuthService.isValidPhoneForMarket(
          '+351912345678',
          market: MarketConfig.maputoAdaptation,
        ),
        isFalse,
      );
    });
  });

  testWidgets('verification explains private use of the phone', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhoneVerificationScreen(action: 'publicar um pedido'),
      ),
    );
    expect(find.textContaining('publicar um pedido'), findsOneWidget);
    expect(find.textContaining('O número é privado'), findsOneWidget);
    expect(find.textContaining('Portugal'), findsOneWidget);
    expect(
      find.byKey(const Key('phone_verification_phone_field')),
      findsOneWidget,
    );

    final phoneField = tester.widget<TextField>(
      find.byKey(const Key('phone_verification_phone_field')),
    );
    expect(phoneField.controller?.text, '+351');
    expect(phoneField.decoration?.hintText, '+351 912 345 678');
  });

  testWidgets('rejects an incomplete Coimbra number before Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhoneVerificationScreen(action: 'publicar um pedido'),
      ),
    );

    await tester.tap(
      find.byKey(const Key('phone_verification_primary_button')),
    );
    await tester.pump();

    expect(
      find.text(
        'Confirma um número móvel de Portugal no formato '
        '+351 912 345 678.',
      ),
      findsOneWidget,
    );
  });
}
