import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/legal/legal_documents.dart';
import 'package:chegaja_v2/features/common/legal_documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identifica o promotor real sem apresentar uma empresa inexistente', () {
    final responsibleSection = LegalDocuments.privacy.first.body;

    expect(LegalDocuments.version, 'legal-2026-07-20-pilot-v3');
    expect(AppConfig.legalEntityName, 'Filipe Bento Jamal');
    expect(
      AppConfig.legalEntityRoleLabel,
      'pessoa singular e promotor do projeto',
    );
    expect(responsibleSection, contains('projeto promovido por Filipe'));
    expect(responsibleSection, isNot(contains('empresa constituída')));
    expect(responsibleSection, isNot(contains('NUIT')));
    expect(responsibleSection, isNot(contains('NIF')));
  });

  test('não simula contactos jurídicos que ainda não foram confirmados', () {
    final responsibleSection = LegalDocuments.privacy.first.body;

    expect(AppConfig.legalContactConfigured, isFalse);
    expect(
      responsibleSection,
      contains('Por confirmar antes do piloto externo'),
    );
    expect(
      responsibleSection,
      contains('ainda têm de ser configurados antes do piloto externo'),
    );
  });

  test('bloqueia a versão histórica de Maputo no mercado de Coimbra', () {
    expect(AppConfig.pilotMarket.id, 'pt-coimbra');
    expect(LegalDocuments.marketId, 'mz-maputo');
    expect(LegalDocuments.isAvailableForCurrentMarket, isFalse);
    expect(LegalDocuments.availabilityMessage, contains('Coimbra'));
  });

  testWidgets('não permite aceitar documentos de outro mercado', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalDocumentsScreen(
          requireAcceptance: true,
          action: 'publicar um pedido',
        ),
      ),
    );

    expect(find.byKey(const Key('legal_market_blocker')), findsOneWidget);
    expect(find.text('Revisão jurídica pendente'), findsOneWidget);
    expect(find.textContaining('referência histórica'), findsOneWidget);
    expect(find.text('Aceitar e continuar'), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byKey(const Key('legal_market_blocker_back')), findsOneWidget);
  });
}
