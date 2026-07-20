import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';
import 'package:chegaja_v2/features/common/trust_safety/block_user_dialog.dart';
import 'package:chegaja_v2/features/common/trust_safety/report_content_sheet.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

Future<void> _pumpProfile(
  WidgetTester tester, {
  required FakeFirebaseFirestore db,
  ReportSubmitCallback? onReportSubmit,
  BlockUserCallback? onBlockUser,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PublicProfileScreen(
        userId: 'prestador1',
        role: 'prestador',
        firestore: db,
        onReportSubmit: onReportSubmit,
        onBlockUser: onBlockUser,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _seedPrestador(FakeFirebaseFirestore db) async {
  await db.collection('provider_public').doc('prestador1').set({
    'nome': 'Joao Silva',
    'bio': 'Canalizador com experiencia.',
    'servicosNomes': ['Canalizacao'],
  });
}

void main() {
  testWidgets('perfil publico mostra acoes denunciar e bloquear',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);

    await tester.tap(find.byKey(const Key('trust_safety_actions_menu')));
    await tester.pumpAndSettle();

    expect(find.text('Denunciar perfil'), findsOneWidget);
    expect(find.text('Bloquear utilizador'), findsOneWidget);
    expect(find.text('Prestador verificado'), findsNothing);
    expect(find.text('Garantido pelo ChegaJa'), findsNothing);
  });

  testWidgets('denunciar perfil abre sheet e chama callback', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    ReportTargetType? capturedTargetType;
    String? capturedTargetId;
    ReportReasonCode? capturedReason;

    await _pumpProfile(
      tester,
      db: db,
      onReportSubmit: ({
        required targetType,
        required targetId,
        required reasonCode,
        required severity,
        details,
        targetOwnerId,
        sourceContext,
        pedidoId,
        chatId,
        messageId,
        mediaUrl,
        mediaPath,
      }) async {
        capturedTargetType = targetType;
        capturedTargetId = targetId;
        capturedReason = reasonCode;
      },
    );

    await tester.tap(find.byKey(const Key('trust_safety_actions_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Denunciar perfil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Fraude/golpe'));
    await tester.tap(find.text('Fraude/golpe'));
    await tester.pump();
    await tester.ensureVisible(find.text('Enviar denuncia'));
    await tester.tap(find.text('Enviar denuncia'));
    await tester.pumpAndSettle();

    expect(capturedTargetType, ReportTargetType.providerProfile);
    expect(capturedTargetId, 'prestador1');
    expect(capturedReason, ReportReasonCode.fraud);
  });

  testWidgets('bloquear perfil abre dialog e chama callback', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    String? blockedUid;
    await _pumpProfile(
      tester,
      db: db,
      onBlockUser: (uid) async {
        blockedUid = uid;
      },
    );

    await tester.tap(find.byKey(const Key('trust_safety_actions_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear utilizador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear'));
    await tester.pumpAndSettle();

    expect(blockedUid, 'prestador1');
  });
}
