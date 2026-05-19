import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Cliente foundation compoe hero, operacoes e servicos',
      (tester) async {
    const servicos = [
      Servico(
        id: 'limpeza_1',
        name: 'Limpeza',
        mode: 'IMEDIATO',
        keywords: ['casa'],
        isActive: true,
      ),
      Servico(
        id: 'eletricista_1',
        name: 'Eletricista',
        mode: 'ORCAMENTO',
        keywords: ['luz'],
        isActive: true,
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ClienteHomeHero(
                  greeting: 'Ola',
                  title: 'Que servico precisas?',
                  subtitle: 'Escolhe e acompanha tudo num unico lugar.',
                  primaryActionLabel: 'Escolher servico',
                  onPrimaryAction: () {},
                  onSearch: () {},
                ),
                ClienteHomeOperationsPanel(
                  title: 'Tens algo para decidir',
                  message: 'Uma proposta aguarda resposta.',
                  actionLabel: 'Ver pedido',
                  onAction: () {},
                ),
                ClienteServicesSection(
                  title: 'Servicos disponiveis',
                  subtitle: 'Escolhe uma categoria.',
                  search: const SizedBox.shrink(),
                  children: [
                    for (final servico in servicos)
                      ClienteServiceTile(
                        servico: servico,
                        localeCode: 'pt',
                        modeLabel: servico.mode,
                        onTap: () {},
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('cliente_home_hero')), findsOneWidget);
    expect(
      find.byKey(const Key('cliente_home_operations_panel')),
      findsOneWidget,
    );
    expect(
        find.byKey(const Key('cliente_home_services_section')), findsOneWidget);
    expect(find.text('Limpeza'), findsOneWidget);
    expect(find.text('Eletricista'), findsOneWidget);
  });
}
