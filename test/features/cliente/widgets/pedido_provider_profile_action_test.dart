import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_contato_section.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PedidoProviderProfileAction', () {
    testWidgets('mostra acao Ver perfil quando existe prestador', (
      tester,
    ) async {
      var opened = false;

      await tester.pumpWidget(
        _wrap(
          PedidoProviderProfileAction(
            prestadorId: 'prestador_1',
            onPressed: () => opened = true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('pedido_provider_profile_action')),
        findsOneWidget,
      );
      expect(find.text('Ver perfil'), findsOneWidget);

      await tester.tap(find.text('Ver perfil'));
      expect(opened, isTrue);
    });

    testWidgets('nao mostra acao quando nao existe prestador', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PedidoProviderProfileAction(
            prestadorId: ' ',
            onPressed: () {},
          ),
        ),
      );

      expect(
        find.byKey(const Key('pedido_provider_profile_action')),
        findsNothing,
      );
      expect(find.text('Ver perfil'), findsNothing);
    });
  });

  group('ContatoSection', () {
    testWidgets('fica oculta mesmo com prestador ate existir endpoint seguro', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ContatoSection(
            pedido: _buildPedido(prestadorId: 'prestador_1'),
            isCliente: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Contacto'), findsNothing);
      expect(find.text('Ver perfil'), findsNothing);
      expect(
        find.byKey(const Key('pedido_provider_profile_action')),
        findsNothing,
      );
    });

    testWidgets('nao mostra Ver perfil quando pedido nao tem prestador', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ContatoSection(
            pedido: _buildPedido(prestadorId: null),
            isCliente: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Contacto'), findsNothing);
      expect(find.text('Ver perfil'), findsNothing);
    });
  });
}

Pedido _buildPedido({required String? prestadorId}) {
  return Pedido(
    id: 'pedido_42',
    clienteId: 'cliente_1',
    prestadorId: prestadorId,
    servicoId: 'servico_1',
    servicoNome: 'Reparacoes',
    titulo: 'Arranjar torneira',
    descricao: 'Torneira a pingar',
    modo: 'IMEDIATO',
    status: 'aceito',
    tipoPreco: 'a_combinar',
    tipoPagamento: 'dinheiro',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: 'nenhum',
    createdAt: DateTime(2026, 5, 28),
  );
}
