import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:chegaja_v2/features/common/widgets/role_mode_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('cliente mostra acao para mudar para prestador', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoleModeSwitchTile(currentRole: 'cliente'),
        ),
      ),
    );

    expect(find.byKey(const Key('cliente_switch_to_prestador_button')),
        findsOneWidget);
    expect(find.text('Mudar para modo prestador'), findsOneWidget);
    expect(find.text('Comeca a receber pedidos e gerir servicos.'),
        findsOneWidget);
  });

  testWidgets('prestador mostra acao para mudar para cliente', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoleModeSwitchTile(currentRole: 'prestador'),
        ),
      ),
    );

    expect(find.byKey(const Key('prestador_switch_to_cliente_button')),
        findsOneWidget);
    expect(find.text('Mudar para modo cliente'), findsOneWidget);
    expect(find.text('Pede servicos como cliente.'), findsOneWidget);
  });

  testWidgets('toque atualiza modo no RoleModeService', (tester) async {
    final service = RoleModeService.forTesting();
    await service.load(defaultRole: 'cliente');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoleModeSwitchTile(
            currentRole: 'cliente',
            roleModeService: service,
          ),
        ),
      ),
    );

    await tester
        .tap(find.byKey(const Key('cliente_switch_to_prestador_button')));
    await tester.pump();

    expect(service.currentRole, 'prestador');
  });
}
