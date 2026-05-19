import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido buildPedido() {
  return Pedido(
    id: 'pedido_dashboard',
    clienteId: 'cliente_1',
    prestadorId: 'prestador_1',
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Montar candeeiro',
    descricao: 'Instalar candeeiro na sala',
    modo: 'IMEDIATO',
    status: 'aceito',
    tipoPreco: 'a_combinar',
    tipoPagamento: 'dinheiro',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: 'nenhum',
    createdAt: DateTime(2026, 5, 19),
  );
}

void main() {
  testWidgets('blocos principais da Home Prestador renderizam em mobile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              PrestadorAvailabilityPanel(
                online: true,
                onChanged: (_) {},
              ),
              const PrestadorMetricStrip(
                liquidoHoje: 'EUR 0.00',
                brutoHoje: 'EUR 0.00',
                taxaHoje: 'EUR 0.00',
                servicosMes: '0',
              ),
              PrestadorNextWorkPanel(
                pedido: buildPedido(),
                actionText: 'Tens um trabalho aceite, pronto para iniciar.',
                onOpen: () {},
              ),
              PrestadorCategoriesPanel(
                categories: const ['Eletricista'],
                loading: false,
                onEdit: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('prestador_home_availability_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prestador_home_metric_strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prestador_home_next_work_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prestador_home_categories_panel')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
