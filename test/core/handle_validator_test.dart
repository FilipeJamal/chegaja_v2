import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/handles/handle_validator.dart';

void main() {
  group('HandleValidator', () {
    test('aceita handle limpo com ponto underline e hifen', () {
      for (final raw in ['maria_bolos', 'joao-eletricista', 'studio.arte']) {
        final result = HandleValidator.validate(raw);
        expect(result.isValid, isTrue, reason: raw);
        expect(result.code, HandleValidationCode.valid, reason: raw);
      }
    });

    test('rejeita curto, longo, caracteres invalidos e espacos', () {
      expect(
          HandleValidator.validate('ab').code, HandleValidationCode.tooShort);
      expect(HandleValidator.validate('a' * 31).code,
          HandleValidationCode.tooLong);
      expect(HandleValidator.validate('maria bolos').code,
          HandleValidationCode.invalidCharacters);
      expect(HandleValidator.validate('maria+bolos').code,
          HandleValidationCode.invalidCharacters);
    });

    test('rejeita separador no inicio fim ou repetido', () {
      expect(HandleValidator.validate('-maria').code,
          HandleValidationCode.edgeSeparator);
      expect(HandleValidator.validate('maria_').code,
          HandleValidationCode.edgeSeparator);
      expect(HandleValidator.validate('maria__bolos').code,
          HandleValidationCode.repeatedSeparator);
      expect(HandleValidator.validate('maria.-bolos').code,
          HandleValidationCode.repeatedSeparator);
    });

    test('rejeita handles reservados e bloqueados por Trust Safety', () {
      expect(HandleValidator.validate('admin').code,
          HandleValidationCode.reserved);
      expect(HandleValidator.validate('chegaja').code,
          HandleValidationCode.reserved);
      expect(HandleValidator.validate('servicos-sexuais').code,
          HandleValidationCode.blockedByTrustSafety);
    });

    test('mensagem de bloqueio nao expoe termo interno', () {
      final result = HandleValidator.validate('servicos-sexuais');

      expect(result.messageForUser, 'Este nome de perfil nao pode ser usado.');
      expect(result.messageForUser, isNot(contains('sexuais')));
    });
  });
}
