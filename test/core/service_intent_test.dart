import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/catalog/service_intent.dart';

void main() {
  group('ServiceIntent', () {
    test('tem labels seguros para a UI futura', () {
      expect(ServiceIntent.now.label, 'Preciso agora');
      expect(ServiceIntent.scheduled.label, 'Quero agendar');
      expect(ServiceIntent.quote.label, 'Quero receber orcamento');
    });

    test('converte modos antigos para intencoes novas', () {
      expect(ServiceIntentX.fromLegacyMode('IMEDIATO'), ServiceIntent.now);
      expect(
          ServiceIntentX.fromLegacyMode('AGENDADO'), ServiceIntent.scheduled);
      expect(
          ServiceIntentX.fromLegacyMode('POR_PROPOSTA'), ServiceIntent.quote);
      expect(ServiceIntentX.fromLegacyMode('ORCAMENTO'), ServiceIntent.quote);
      expect(
          ServiceIntentX.fromLegacyMode('POR_ORCAMENTO'), ServiceIntent.quote);
    });

    test('legacy invalido cai em now sem quebrar fluxo atual', () {
      expect(ServiceIntentX.fromLegacyMode('desconhecido'), ServiceIntent.now);
      expect(ServiceIntentX.fromLegacyMode(null), ServiceIntent.now);
    });

    test('converte intencoes novas para modo antigo compativel', () {
      expect(ServiceIntent.now.legacyMode, 'IMEDIATO');
      expect(ServiceIntent.scheduled.legacyMode, 'AGENDADO');
      expect(ServiceIntent.quote.legacyMode, 'POR_PROPOSTA');
    });
  });
}
