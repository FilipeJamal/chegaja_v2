import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/trust_safety_classifier.dart';

import 'handle_normalizer.dart';
import 'reserved_handles.dart';

enum HandleValidationCode {
  valid,
  empty,
  tooShort,
  tooLong,
  invalidCharacters,
  edgeSeparator,
  repeatedSeparator,
  reserved,
  blockedByTrustSafety,
}

class HandleValidationResult {
  const HandleValidationResult({
    required this.normalizedHandle,
    required this.code,
    required this.messageForUser,
  });

  final String normalizedHandle;
  final HandleValidationCode code;
  final String messageForUser;

  bool get isValid => code == HandleValidationCode.valid;
}

class HandleValidator {
  const HandleValidator._();

  static const int minLength = 3;
  static const int maxLength = 30;

  static HandleValidationResult validate(String rawHandle) {
    final normalized = HandleNormalizer.normalize(rawHandle);

    if (normalized.isEmpty) {
      return _result(normalized, HandleValidationCode.empty);
    }
    if (normalized.length < minLength) {
      return _result(normalized, HandleValidationCode.tooShort);
    }
    if (normalized.length > maxLength) {
      return _result(normalized, HandleValidationCode.tooLong);
    }
    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(normalized)) {
      return _result(normalized, HandleValidationCode.invalidCharacters);
    }
    if (RegExp(r'^[._-]|[._-]$').hasMatch(normalized)) {
      return _result(normalized, HandleValidationCode.edgeSeparator);
    }
    if (RegExp(r'[._-]{2,}').hasMatch(normalized)) {
      return _result(normalized, HandleValidationCode.repeatedSeparator);
    }
    if (ReservedHandles.contains(normalized)) {
      return _result(normalized, HandleValidationCode.reserved);
    }

    final safetyText = normalized.replaceAll(RegExp(r'[._-]+'), ' ');
    final safety = TrustSafetyClassifier.classifyText(safetyText);
    if (safety.decision == TrustSafetyDecision.block) {
      return _result(normalized, HandleValidationCode.blockedByTrustSafety);
    }

    return _result(normalized, HandleValidationCode.valid);
  }

  static HandleValidationResult _result(
    String normalized,
    HandleValidationCode code,
  ) {
    return HandleValidationResult(
      normalizedHandle: normalized,
      code: code,
      messageForUser: _messageFor(code),
    );
  }

  static String _messageFor(HandleValidationCode code) {
    return switch (code) {
      HandleValidationCode.valid => '',
      HandleValidationCode.empty => 'Escolhe um @handle.',
      HandleValidationCode.tooShort =>
        'O @handle deve ter pelo menos 3 caracteres.',
      HandleValidationCode.tooLong =>
        'O @handle deve ter no maximo 30 caracteres.',
      HandleValidationCode.invalidCharacters =>
        'Usa apenas letras, numeros, ponto, underline ou hifen.',
      HandleValidationCode.edgeSeparator =>
        'O @handle nao pode comecar ou terminar com separador.',
      HandleValidationCode.repeatedSeparator =>
        'O @handle nao pode ter separadores repetidos.',
      HandleValidationCode.reserved =>
        'Este nome de perfil nao pode ser usado.',
      HandleValidationCode.blockedByTrustSafety =>
        'Este nome de perfil nao pode ser usado.',
    };
  }
}
