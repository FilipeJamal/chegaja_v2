// lib/core/utils/pedido_state_machine.dart

class PedidoStateMachine {
  PedidoStateMachine._();

  static const String criado = 'criado';
  static const String aguardaRespostaPrestador = 'aguarda_resposta_prestador';
  static const String aguardaRespostaCliente = 'aguarda_resposta_cliente';
  static const String aceito = 'aceito';
  static const String emAndamento = 'em_andamento';
  static const String aguardaConfirmacaoValor = 'aguarda_confirmacao_valor';
  static const String concluido = 'concluido';
  static const String cancelado = 'cancelado';

  static const Set<String> estadosValidos = {
    criado,
    aguardaRespostaPrestador,
    aguardaRespostaCliente,
    aceito,
    emAndamento,
    aguardaConfirmacaoValor,
    concluido,
    cancelado,
  };

  static const Set<String> estadosFinais = {concluido, cancelado};

  static bool isValidEstado(String value) {
    return estadosValidos.contains(value.trim().toLowerCase());
  }

  static bool isFinal(String value) {
    return estadosFinais.contains(value.trim().toLowerCase());
  }

  static String normalizeRole(String role) {
    final r = role.trim().toLowerCase();
    if (r == 'cliente' || r == 'prestador' || r == 'sistema') return r;
    return 'sistema';
  }

  static const Map<String, Set<String>> _allowedTransitions = {
    criado: {aguardaRespostaPrestador, aguardaRespostaCliente, aceito, cancelado},
    aguardaRespostaPrestador: {aceito, criado, cancelado},
    aguardaRespostaCliente: {aceito, criado, cancelado},
    aceito: {emAndamento, aguardaRespostaCliente, criado, cancelado},
    emAndamento: {aguardaConfirmacaoValor, cancelado},
    aguardaConfirmacaoValor: {concluido, emAndamento, cancelado},
    concluido: {},
    cancelado: {},
  };

  static const Map<String, Map<String, Set<String>>> _allowedByRole = {
    'cliente': {
      criado: {aguardaRespostaPrestador, cancelado},
      aguardaRespostaPrestador: {cancelado},
      aguardaRespostaCliente: {aceito, criado, cancelado},
      aceito: {cancelado},
      emAndamento: {cancelado},
      aguardaConfirmacaoValor: {concluido, emAndamento, cancelado},
    },
    'prestador': {
      criado: {aceito, aguardaRespostaCliente},
      aguardaRespostaPrestador: {aceito, criado},
      aguardaRespostaCliente: {criado},
      aceito: {emAndamento, aguardaRespostaCliente, criado},
      emAndamento: {aguardaConfirmacaoValor, cancelado},
      aguardaConfirmacaoValor: {cancelado},
    },
    'sistema': _allowedTransitions,
  };

  static bool canTransition(String from, String to) {
    final f = from.trim().toLowerCase();
    final t = to.trim().toLowerCase();
    if (!estadosValidos.contains(f) || !estadosValidos.contains(t)) {
      return false;
    }
    return _allowedTransitions[f]?.contains(t) ?? false;
  }

  static bool canTransitionForRole({
    required String role,
    required String from,
    required String to,
  }) {
    final r = normalizeRole(role);
    final f = from.trim().toLowerCase();
    final t = to.trim().toLowerCase();
    if (!estadosValidos.contains(f) || !estadosValidos.contains(t)) {
      return false;
    }
    final allowed = _allowedByRole[r] ?? _allowedByRole['sistema']!;
    return allowed[f]?.contains(t) ?? false;
  }

  static void assertTransition({
    required String role,
    required String from,
    required String to,
  }) {
    if (!canTransitionForRole(role: role, from: from, to: to)) {
      throw StateError('Transicao invalida: $from -> $to ($role).');
    }
  }
}
