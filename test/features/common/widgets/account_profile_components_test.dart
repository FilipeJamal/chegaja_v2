import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/common/widgets/account_profile_summary.dart';
import 'package:chegaja_v2/features/common/widgets/settings_list_tile.dart';

void main() {
  testWidgets('AccountProfileSummary renderiza nome e papel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccountProfileSummary(
            name: 'Joao Silva',
            roleLabel: 'Cliente',
          ),
        ),
      ),
    );

    expect(find.text('Joao Silva'), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
  });

  testWidgets('AccountProfileSummary chama editar perfil', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountProfileSummary(
            name: 'Marta Santos',
            roleLabel: 'Prestadora',
            onEditPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Editar perfil'));
    expect(tapped, isTrue);
  });

  testWidgets('AccountProfileSummary mostra metrica quando fornecida',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccountProfileSummary(
            name: 'Carlos Almeida',
            roleLabel: 'Canalizador',
            metrics: [
              AccountProfileMetric(
                label: 'Pedidos concluidos',
                value: '128',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pedidos concluidos'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
  });

  testWidgets('SettingsListTile renderiza titulo e subtitulo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsListTile(
            icon: Icons.person_outline,
            title: 'Perfil',
            subtitle: 'Informacoes pessoais',
          ),
        ),
      ),
    );

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Informacoes pessoais'), findsOneWidget);
  });

  testWidgets('SettingsListTile chama onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsListTile(
            icon: Icons.help_outline,
            title: 'Ajuda',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ajuda'));
    expect(tapped, isTrue);
  });

  testWidgets('SettingsListTile suporta tom destrutivo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsListTile(
            icon: Icons.logout_rounded,
            title: 'Terminar sessao',
            tone: SettingsListTileTone.danger,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.logout_rounded));
    expect(icon.color, isNotNull);
    expect(find.text('Terminar sessao'), findsOneWidget);
  });
}
