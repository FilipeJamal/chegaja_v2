import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/custom_service_safety_validator.dart';
import 'package:chegaja_v2/core/trust_safety/service_admission_guard.dart';

void main() {
  group('CustomServiceSafetyValidator', () {
    test('bloqueia termo proibido no titulo sem expor detalhe ao utilizador',
        () {
      final result = CustomServiceSafetyValidator.validate(
        title: 'Servicos sexuais',
        description: 'Atendimento privado',
        aliases: const ['adulto'],
      );

      expect(result.decision, TrustSafetyDecision.block);
      expect(
        result.messageForUser,
        'Este tipo de serviço não é permitido no ChegaJá.',
      );
      expect(result.messageForUser, isNot(contains('sexuais')));
    });

    test('bloqueia termo proibido em descricao e alias', () {
      final byDescription = CustomServiceSafetyValidator.validate(
        title: 'Apoio administrativo',
        description: 'Falsificacao de documentos para viagem',
      );
      final byAlias = CustomServiceSafetyValidator.validate(
        title: 'Entrega especial',
        description: 'Transporte local',
        aliases: const ['drogas ilegais'],
      );

      expect(byDescription.decision, TrustSafetyDecision.block);
      expect(byAlias.decision, TrustSafetyDecision.block);
    });

    test('bloqueia prostituta sem guardar como servico custom', () {
      final result = CustomServiceSafetyValidator.validate(
        title: 'prostituta',
        description: 'trabalho com o corpo',
      );

      expect(result.decision, TrustSafetyDecision.block);
      expect(result.messageForUser, isNot(contains('prostituta')));
    });

    test('bloqueia burla e burlador como fraude', () {
      for (final title in const ['burlas', 'burlador', 'b.u.r.l.a']) {
        final result = CustomServiceSafetyValidator.validate(
          title: title,
          description: 'Texto antigo contaminado',
        );

        expect(result.decision, TrustSafetyDecision.block, reason: title);
        expect(result.admissionDecision, ServiceAdmissionDecision.block);
        expect(result.shouldSave, isFalse);
        expect(result.messageForUser, isNot(contains(title)));
      }
    });

    test('needsReview nao bloqueia servico sensivel legitimo', () {
      final result = CustomServiceSafetyValidator.validate(
        title: 'Cuidados infantis ao domicilio',
        description: 'Apoio pontual a familias',
        aliases: const ['babysitter'],
      );

      expect(result.decision, TrustSafetyDecision.needsReview);
      expect(result.isBlocked, isFalse);
    });

    test('block vence needsReview e warn', () {
      final result = CustomServiceSafetyValidator.validate(
        title: 'Cuidados infantis',
        description: 'Inclui venda de drogas ilegais',
        aliases: const ['companhia discreta'],
      );

      expect(result.decision, TrustSafetyDecision.block);
    });

    test('permite servico limpo e gera termos normalizados', () {
      final result = CustomServiceSafetyValidator.validate(
        title: 'Consultoria de imagem',
        description: 'Estilo pessoal e guarda-roupa',
        aliases: const ['moda', 'roupa'],
      );

      expect(result.decision, TrustSafetyDecision.allow);
      expect(
        result.normalizedSearchTerms,
        containsAll(['consultoria de imagem', 'estilo pessoal', 'moda']),
      );
    });

    test('unknownReview impede publicacao automatica de servico vago', () {
      final result = CustomServiceSafetyValidator.validate(
        title: 'servico especial',
        description: 'qualquer coisa discreta',
      );

      expect(result.decision, TrustSafetyDecision.allow);
      expect(result.admissionDecision, ServiceAdmissionDecision.unknownReview);
      expect(result.shouldSave, isFalse);
      expect(
        result.messageForUser,
        'Este servi\u00e7o precisa de an\u00e1lise antes de ficar dispon\u00edvel.',
      );
    });
  });
}
