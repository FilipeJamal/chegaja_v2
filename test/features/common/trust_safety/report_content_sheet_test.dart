import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/features/common/trust_safety/report_content_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required ReportSubmitCallback onSubmit,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ReportContentSheet(
            targetType: ReportTargetType.providerProfile,
            targetId: 'provider1',
            targetOwnerId: 'provider1',
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }

  testWidgets('mostra motivos e exige motivo selecionado', (tester) async {
    var submitted = false;
    await pumpSheet(
      tester,
      onSubmit: ({
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
        submitted = true;
      },
    );

    expect(find.text('Denunciar conteudo'), findsOneWidget);
    expect(find.text('Servico ilegal'), findsOneWidget);
    expect(find.text('Conteudo sexual/obsceno'), findsOneWidget);
    expect(find.text('Fraude/golpe'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
        isFalse);
    expect(submitted, isFalse);
  });

  testWidgets('detalhes acima do limite bloqueiam envio', (tester) async {
    var calls = 0;
    await pumpSheet(
      tester,
      onSubmit: ({
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
        calls++;
      },
    );

    await tester.ensureVisible(find.text('Outro'));
    await tester.tap(find.text('Outro'));
    await tester.enterText(find.byType(TextField), 'x' * 1001);
    await tester.pump();

    await tester.ensureVisible(find.text('1001/1000'));
    expect(find.text('1001/1000'), findsOneWidget);
    expect(find.text('Limite maximo de 1000 caracteres.'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
        isFalse);
    expect(calls, 0);
  });

  testWidgets('enviar chama callback com target e motivo', (tester) async {
    ReportReasonCode? capturedReason;
    String? capturedDetails;
    ReportTargetType? capturedTargetType;
    String? capturedTargetId;
    String? capturedTargetOwnerId;

    await pumpSheet(
      tester,
      onSubmit: ({
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
        capturedReason = reasonCode;
        capturedDetails = details;
        capturedTargetType = targetType;
        capturedTargetId = targetId;
        capturedTargetOwnerId = targetOwnerId;
      },
    );

    await tester.tap(find.text('Fraude/golpe'));
    await tester.enterText(find.byType(TextField), 'Perfil suspeito');
    await tester.ensureVisible(find.text('Enviar denuncia'));
    await tester.tap(find.text('Enviar denuncia'));
    await tester.pumpAndSettle();

    expect(capturedReason, ReportReasonCode.fraud);
    expect(capturedDetails, 'Perfil suspeito');
    expect(capturedTargetType, ReportTargetType.providerProfile);
    expect(capturedTargetId, 'provider1');
    expect(capturedTargetOwnerId, 'provider1');
  });

  testWidgets('mostra erro se callback falhar', (tester) async {
    await pumpSheet(
      tester,
      onSubmit: ({
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
        throw Exception('falhou');
      },
    );

    await tester.tap(find.text('Spam'));
    await tester.pump();
    await tester.ensureVisible(find.text('Enviar denuncia'));
    await tester.tap(find.text('Enviar denuncia'));
    await tester.pumpAndSettle();

    expect(find.text('Nao conseguimos enviar a denuncia.'), findsOneWidget);
  });

  testWidgets('renderiza em dark mode', (tester) async {
    await pumpSheet(
      tester,
      theme: ThemeData.dark(),
      onSubmit: ({
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
      }) async {},
    );

    expect(find.text('Denunciar conteudo'), findsOneWidget);
  });
}
