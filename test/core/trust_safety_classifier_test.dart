import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/trust_safety_classifier.dart';

void main() {
  group('TrustSafetyClassifier', () {
    test('texto limpo e permitido', () {
      final result = TrustSafetyClassifier.classifyText(
        'Limpeza residencial e organizacao de roupeiros',
      );

      expect(result.decision, TrustSafetyDecision.allow);
      expect(result.matchedTerms, isEmpty);
      expect(result.matchedCategories, isEmpty);
      expect(result.reasonCodes, isEmpty);
      expect(result.severity, ReportSeverity.low);
    });

    test('servico sexual claro e bloqueado sem expor termo no user message',
        () {
      final result = TrustSafetyClassifier.classifyText(
        'Procuro prostituição e serviços sexuais',
      );

      expect(result.decision, TrustSafetyDecision.block);
      expect(result.reasonCodes, contains(ReportReasonCode.sexualContent));
      expect(result.severity, ReportSeverity.high);
      expect(result.matchedTerms, contains('prostituicao'));
      expect(result.messageForUser,
          'Este tipo de servico nao e permitido no ChegaJa.');
      expect(result.messageForUser, isNot(contains('prostituicao')));
    });

    test('prostituta e bloqueado como servico sexual proibido', () {
      final result = TrustSafetyClassifier.classifyText(
        'prostituta para atendimento privado',
      );

      expect(result.decision, TrustSafetyDecision.block);
      expect(result.reasonCodes, contains(ReportReasonCode.sexualContent));
      expect(result.messageForUser,
          'Este tipo de servico nao e permitido no ChegaJa.');
      expect(result.messageForUser, isNot(contains('prostituta')));
    });

    test('drogas ilegais, trafico humano e armas ilegais sao criticos', () {
      for (final text in const [
        'Venda de drogas ilegais',
        'Trafico humano',
        'Armas ilegais',
      ]) {
        final result = TrustSafetyClassifier.classifyText(text);

        expect(result.decision, TrustSafetyDecision.block, reason: text);
        expect(result.severity, ReportSeverity.critical, reason: text);
      }
    });

    test('falsificacao de documentos e fraude sao bloqueadas', () {
      final forged = TrustSafetyClassifier.classifyText(
        'Falsificacao de documentos e passaporte falso',
      );
      final fraud = TrustSafetyClassifier.classifyText('Golpe e fraude online');

      expect(forged.decision, TrustSafetyDecision.block);
      expect(forged.reasonCodes, contains(ReportReasonCode.fraud));
      expect(fraud.decision, TrustSafetyDecision.block);
      expect(fraud.reasonCodes, contains(ReportReasonCode.fraud));
    });

    test('categorias sensiveis precisam de analise, nao bloqueio automatico',
        () {
      final result = TrustSafetyClassifier.classifyText(
        'Servicos de saude, treino e nutricao',
      );

      expect(result.decision, TrustSafetyDecision.needsReview);
      expect(result.matchedCategories, contains('health'));
      expect(result.matchedCategories, contains('training_nutrition'));
      expect(result.severity, ReportSeverity.medium);
      expect(
        result.messageForUser,
        'Este servico pode precisar de analise antes de ficar disponivel.',
      );
    });

    test('termo ambiguo gera aviso ou analise sem bloqueio automatico', () {
      final result = TrustSafetyClassifier.classifyText(
        'Companhia discreta para eventos privados',
      );

      expect(
        result.decision,
        anyOf(TrustSafetyDecision.warn, TrustSafetyDecision.needsReview),
      );
      expect(result.decision, isNot(TrustSafetyDecision.block));
    });

    test('classifica multiplos campos em conjunto', () {
      final result = TrustSafetyClassifier.classifyFields([
        'Perfil profissional',
        'Cuidados infantis',
        'Lisboa',
      ]);

      expect(result.decision, TrustSafetyDecision.needsReview);
      expect(result.matchedCategories, contains('child_care'));
    });
  });
}
