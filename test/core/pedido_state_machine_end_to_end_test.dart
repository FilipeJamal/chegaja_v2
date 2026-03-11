import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/utils/pedido_state_machine.dart';

void main() {
  void expectTransition({
    required String role,
    required String from,
    required String to,
  }) {
    expect(
      () => PedidoStateMachine.assertTransition(role: role, from: from, to: to),
      returnsNormally,
    );
  }

  test('manual flow can reach concluido', () {
    expectTransition(
      role: 'cliente',
      from: PedidoStateMachine.criado,
      to: PedidoStateMachine.aguardaRespostaPrestador,
    );
    expectTransition(
      role: 'prestador',
      from: PedidoStateMachine.aguardaRespostaPrestador,
      to: PedidoStateMachine.aceito,
    );
    expectTransition(
      role: 'prestador',
      from: PedidoStateMachine.aceito,
      to: PedidoStateMachine.emAndamento,
    );
    expectTransition(
      role: 'prestador',
      from: PedidoStateMachine.emAndamento,
      to: PedidoStateMachine.aguardaConfirmacaoValor,
    );
    expectTransition(
      role: 'cliente',
      from: PedidoStateMachine.aguardaConfirmacaoValor,
      to: PedidoStateMachine.concluido,
    );
  });

  test('automatic flow can reach concluido', () {
    expectTransition(
      role: 'prestador',
      from: PedidoStateMachine.criado,
      to: PedidoStateMachine.aceito,
    );
    expectTransition(
      role: 'prestador',
      from: PedidoStateMachine.aceito,
      to: PedidoStateMachine.emAndamento,
    );
    expectTransition(
      role: 'prestador',
      from: PedidoStateMachine.emAndamento,
      to: PedidoStateMachine.aguardaConfirmacaoValor,
    );
    expectTransition(
      role: 'cliente',
      from: PedidoStateMachine.aguardaConfirmacaoValor,
      to: PedidoStateMachine.concluido,
    );
  });

  test('final states do not allow extra transitions', () {
    expect(
      PedidoStateMachine.canTransition(
        PedidoStateMachine.concluido,
        PedidoStateMachine.cancelado,
      ),
      isFalse,
    );
    expect(
      PedidoStateMachine.canTransition(
        PedidoStateMachine.cancelado,
        PedidoStateMachine.concluido,
      ),
      isFalse,
    );
  });
}
