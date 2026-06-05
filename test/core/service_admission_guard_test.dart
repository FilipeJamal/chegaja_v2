import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/trust_safety/service_admission_guard.dart';

void main() {
  group('ServiceAdmissionGuard', () {
    test('bloqueia fraude burla e ilicitos claros', () {
      const blocked = [
        'burlas',
        'burlador',
        'burl\u00e3o',
        'fraudador',
        'golpista',
        'scammer',
        'cart\u00e3o clonado',
        'hackear conta',
        'assassino',
        'documento falso',
      ];

      for (final title in blocked) {
        final result = ServiceAdmissionGuard.classify(title: title);
        expect(result.decision, ServiceAdmissionDecision.block, reason: title);
        expect(result.shouldSave, isFalse, reason: title);
        expect(result.shouldRenderPublicly, isFalse, reason: title);
        expect(result.shouldIndexForSearch, isFalse, reason: title);
        expect(result.shouldMatch, isFalse, reason: title);
        expect(result.userMessage, isNot(contains(title)));
      }
    });

    test('bloqueia obfuscacao simples de burla e ilicitos', () {
      const blocked = [
        'b.u.r.l.a',
        'b-u-r-l-a',
        'b u r l a',
        'bur1a',
        'assass1no',
        'ped0filia',
        'd0cumento falso',
        's i c a r i o',
      ];

      for (final title in blocked) {
        expect(
          ServiceAdmissionGuard.classify(title: title).decision,
          ServiceAdmissionDecision.block,
          reason: title,
        );
      }
    });

    test('permite servicos legitimos e evita falsos positivos', () {
      const allowed = [
        'computador',
        'repara\u00e7\u00e3o de computadores',
        'reputa\u00e7\u00e3o online',
        'disputa contratual',
        'consultoria de imagem',
        'tr\u00e1fego pago',
        'matem\u00e1tica',
        'exterminador de pragas',
        'matar baratas',
        'bolo de anivers\u00e1rio',
        'fotografia de eventos',
        'seguran\u00e7a inform\u00e1tica',
      ];

      for (final title in allowed) {
        final result = ServiceAdmissionGuard.classify(
          title: title,
          description: 'Servico profissional descrito de forma clara.',
        );
        expect(result.decision, ServiceAdmissionDecision.allow, reason: title);
        expect(result.shouldSave, isTrue, reason: title);
        expect(result.shouldRenderPublicly, isTrue, reason: title);
      }
    });

    test('classifica servicos sensiveis legitimos como sensitiveReview', () {
      final result = ServiceAdmissionGuard.classify(
        title: 'Cuidados infantis ao domicilio',
        description: 'Apoio pontual a familias.',
        aliases: const ['babysitter'],
      );

      expect(result.decision, ServiceAdmissionDecision.sensitiveReview);
      expect(result.shouldSave, isTrue);
      expect(result.shouldRenderPublicly, isTrue);
      expect(result.userMessage, isNot(contains('Cuidados infantis')));
    });

    test('servicos legitimos de saude nao sao bloqueados', () {
      const admissible = [
        'farm\u00e1cia',
        'fisioterapia',
        'enfermagem ao domic\u00edlio',
        'apoio psicol\u00f3gico',
      ];

      for (final title in admissible) {
        final result = ServiceAdmissionGuard.classify(
          title: title,
          description: 'Servico profissional descrito de forma clara.',
        );
        expect(
          result.decision,
          anyOf(
            ServiceAdmissionDecision.allow,
            ServiceAdmissionDecision.sensitiveReview,
          ),
          reason: title,
        );
        expect(result.shouldSave, isTrue, reason: title);
        expect(result.shouldRenderPublicly, isTrue, reason: title);
      }
    });

    test('classifica servicos vagos como unknownReview', () {
      const unknown = [
        'servi\u00e7o especial',
        'trabalho secreto',
        'fa\u00e7o de tudo',
        'qualquer coisa',
        'servi\u00e7o privado',
        'coisa discreta',
        'contactos especiais',
        'ajuda confidencial',
      ];

      for (final title in unknown) {
        final result = ServiceAdmissionGuard.classify(title: title);
        expect(
          result.decision,
          ServiceAdmissionDecision.unknownReview,
          reason: title,
        );
        expect(result.shouldSave, isFalse, reason: title);
        expect(result.shouldRenderPublicly, isFalse, reason: title);
        expect(result.shouldIndexForSearch, isFalse, reason: title);
        expect(result.shouldMatch, isFalse, reason: title);
      }
    });
  });
}
