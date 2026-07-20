import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/legal/legal_documents.dart';
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
}
