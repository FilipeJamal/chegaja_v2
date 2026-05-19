import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClienteHomeHero', () {
    testWidgets('mostra promessa operacional e CTA principal', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeHero(
              greeting: 'Ola, Filipe',
              title: 'Que servico precisas?',
              subtitle: 'Escolhe um servico e acompanha tudo num unico lugar.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () => tapped = true,
              onSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cliente_home_hero')), findsOneWidget);
      expect(find.text('Que servico precisas?'), findsOneWidget);
      expect(find.byKey(const Key('cliente_home_primary_cta')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cliente_home_primary_cta')));
      expect(tapped, isTrue);
    });

    testWidgets('mantem CTA visivel em largura mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeHero(
              greeting: 'Ola',
              title: 'Que servico precisas?',
              subtitle: 'Escolhe um servico e acompanha tudo num unico lugar.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cliente_home_primary_cta')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ClienteServiceTile', () {
    testWidgets('mostra nome, modo e key estavel por servico', (tester) async {
      var tapped = false;
      const servico = Servico(
        id: 'canalizador-1',
        name: 'Canalizador',
        mode: 'IMEDIATO',
        keywords: ['agua', 'cano'],
        iconKey: 'canalizador',
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteServiceTile(
              servico: servico,
              localeCode: 'pt',
              modeLabel: 'Imediato',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_service_tile_canalizador-1')),
        findsOneWidget,
      );
      expect(find.text('Canalizador'), findsOneWidget);
      expect(find.text('Imediato'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('cliente_home_service_tile_canalizador-1')),
      );
      expect(tapped, isTrue);
    });
  });

  group('ClienteHomeOperationsPanel', () {
    testWidgets('mostra acao pendente com CTA', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeOperationsPanel(
              title: 'Tens algo para decidir',
              message: 'Uma proposta aguarda a tua resposta.',
              actionLabel: 'Ver pedido',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_operations_panel')),
        findsOneWidget,
      );
      expect(find.text('Tens algo para decidir'), findsOneWidget);

      await tester.tap(find.text('Ver pedido'));
      expect(tapped, isTrue);
    });
  });

  group('ClienteHomeEmptyServices', () {
    testWidgets('orienta primeira acao sem parecer erro tecnico',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClienteHomeEmptyServices(),
          ),
        ),
      );

      expect(
        find.text('Ainda estamos a preparar servicos para ti.'),
        findsOneWidget,
      );
      expect(
        find.text('Tenta novamente daqui a pouco ou ajusta a pesquisa.'),
        findsOneWidget,
      );
    });
  });
}
