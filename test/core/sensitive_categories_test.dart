import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/trust_safety/sensitive_categories.dart';

void main() {
  group('SensitiveCategories', () {
    test('identifica categorias que precisam de analise humana', () {
      final matches = SensitiveCategories.match('Eletricidade e gas');

      expect(matches.map((item) => item.id), contains('electricity'));
      expect(matches.map((item) => item.id), contains('gas'));
      expect(matches.every((item) => item.severity == ReportSeverity.medium),
          isTrue);
    });

    test('inclui saude, cuidados infantis e alimentacao profissional', () {
      final matches = SensitiveCategories.match(
        'Saude, cuidados infantis e catering profissional',
      );
      final ids = matches.map((item) => item.id).toSet();

      expect(ids, contains('health'));
      expect(ids, contains('child_care'));
      expect(ids, contains('professional_food'));
    });

    test('texto comum nao gera categoria sensivel', () {
      expect(SensitiveCategories.match('Limpeza pos obra'), isEmpty);
    });
  });
}
