import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/utils/pedido_state_machine.dart';

void main() {
  group('PedidoStateMachine manual flow', () {
    test('cliente can invite prestador manually', () {
      expect(
        PedidoStateMachine.canTransitionForRole(
          role: 'cliente',
          from: PedidoStateMachine.criado,
          to: PedidoStateMachine.aguardaRespostaPrestador,
        ),
        isTrue,
      );
    });

    test('prestador can accept manual invite', () {
      expect(
        PedidoStateMachine.canTransitionForRole(
          role: 'prestador',
          from: PedidoStateMachine.aguardaRespostaPrestador,
          to: PedidoStateMachine.aceito,
        ),
        isTrue,
      );
    });

    test('prestador can refuse manual invite back to created', () {
      expect(
        PedidoStateMachine.canTransitionForRole(
          role: 'prestador',
          from: PedidoStateMachine.aguardaRespostaPrestador,
          to: PedidoStateMachine.criado,
        ),
        isTrue,
      );
    });
  });

  group('PedidoStateMachine automatic flow', () {
    test('prestador can accept created pedido', () {
      expect(
        PedidoStateMachine.canTransitionForRole(
          role: 'prestador',
          from: PedidoStateMachine.criado,
          to: PedidoStateMachine.aceito,
        ),
        isTrue,
      );
    });

    test('cliente cannot accept directly from created', () {
      expect(
        PedidoStateMachine.canTransitionForRole(
          role: 'cliente',
          from: PedidoStateMachine.criado,
          to: PedidoStateMachine.aceito,
        ),
        isFalse,
      );
    });
  });

  test('isValidEstado accepts known estados', () {
    for (final estado in PedidoStateMachine.estadosValidos) {
      expect(PedidoStateMachine.isValidEstado(estado), isTrue);
    }
  });
}
