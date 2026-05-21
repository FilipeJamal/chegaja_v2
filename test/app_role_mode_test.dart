import 'package:chegaja_v2/app.dart';
import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('sem role mostra seletor inicial', (tester) async {
    final service = RoleModeService.forTesting();
    await service.load();

    await tester.pumpWidget(
      ChegaJaApp(
        roleModeService: service,
        roleSelectorBuilder: (_) => const Text('seletor de modo'),
        clienteHomeBuilder: (_) => const Text('home cliente'),
        prestadorHomeBuilder: (_) => const Text('home prestador'),
      ),
    );
    await tester.pump();

    expect(find.text('seletor de modo'), findsOneWidget);
    expect(find.text('home cliente'), findsNothing);
    expect(find.text('home prestador'), findsNothing);
  });

  testWidgets('role cliente mostra home cliente', (tester) async {
    final service = RoleModeService.forTesting();
    await service.load(defaultRole: 'cliente');

    await tester.pumpWidget(
      ChegaJaApp(
        roleModeService: service,
        roleSelectorBuilder: (_) => const Text('seletor de modo'),
        clienteHomeBuilder: (_) => const Text('home cliente'),
        prestadorHomeBuilder: (_) => const Text('home prestador'),
      ),
    );
    await tester.pump();

    expect(find.text('home cliente'), findsOneWidget);
  });

  testWidgets('role prestador mostra home prestador', (tester) async {
    final service = RoleModeService.forTesting();
    await service.load(defaultRole: 'prestador');

    await tester.pumpWidget(
      ChegaJaApp(
        roleModeService: service,
        roleSelectorBuilder: (_) => const Text('seletor de modo'),
        clienteHomeBuilder: (_) => const Text('home cliente'),
        prestadorHomeBuilder: (_) => const Text('home prestador'),
      ),
    );
    await tester.pump();

    expect(find.text('home prestador'), findsOneWidget);
  });

  testWidgets('troca de modo atualiza home renderizada', (tester) async {
    final service = RoleModeService.forTesting();
    await service.load(defaultRole: 'cliente');

    await tester.pumpWidget(
      ChegaJaApp(
        roleModeService: service,
        roleSelectorBuilder: (_) => const Text('seletor de modo'),
        clienteHomeBuilder: (_) => const Text('home cliente'),
        prestadorHomeBuilder: (_) => const Text('home prestador'),
      ),
    );
    await tester.pump();
    expect(find.text('home cliente'), findsOneWidget);

    await service.setMode('prestador');
    await tester.pump();

    expect(find.text('home prestador'), findsOneWidget);
  });
}
