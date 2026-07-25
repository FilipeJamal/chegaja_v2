import 'dart:async';

import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/core/widgets/app_brand_wordmark.dart';
import 'package:chegaja_v2/features/auth/role_selector_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('seleciona papel local sem esperar pela autenticacao remota', () async {
    final service = RoleModeService.forTesting();
    await service.load();
    final authBlocker = Completer<void>();
    var remoteRole = '';

    await selectRoleForApp(
      role: 'cliente',
      roleModeService: service,
      ensureSignedIn: () => authBlocker.future,
      syncActiveRole: (role) async => remoteRole = role,
    ).timeout(const Duration(milliseconds: 200));

    expect(service.currentRole, 'cliente');
    expect(remoteRole, isEmpty);

    authBlocker.complete();
    await Future<void>.delayed(Duration.zero);
    expect(remoteRole, 'cliente');
  });

  testWidgets('mantem a experiencia anterior quando a flag U1 esta desligada',
      (tester) async {
    await _pumpRoleSelector(
      tester,
      size: const Size(390, 844),
      u1ExperienceV2: false,
    );

    expect(find.byKey(const Key('role-selector-legacy')), findsOneWidget);
    expect(find.byType(AppBrandWordmark), findsNothing);
    expect(find.byKey(const Key('legacy-role-card-cliente')), findsOneWidget);
    expect(find.byKey(const Key('legacy-role-card-prestador')), findsOneWidget);
    expect(find.byKey(const Key('role-card-cliente')), findsNothing);
    expect(find.byKey(const Key('role-card-prestador')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('apresenta a identidade U1 e escolhas empilhadas no telemovel',
      (tester) async {
    await _pumpRoleSelector(
      tester,
      size: const Size(390, 844),
    );

    expect(find.byType(AppBrandWordmark), findsOneWidget);
    expect(find.text('Bem-vindo ao ChegaJá'), findsOneWidget);
    expect(find.text('Escolhe como queres usar o app:'), findsOneWidget);
    expect(find.text('Sou cliente'), findsNWidgets(2));
    expect(find.text('Sou prestador'), findsNWidgets(2));

    final customer = tester.getRect(find.byKey(const Key('role-card-cliente')));
    final provider =
        tester.getRect(find.byKey(const Key('role-card-prestador')));
    expect(provider.top, greaterThan(customer.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('apresenta escolhas lado a lado em ecras largos', (tester) async {
    await _pumpRoleSelector(
      tester,
      size: const Size(900, 760),
    );

    final customer = tester.getRect(find.byKey(const Key('role-card-cliente')));
    final provider =
        tester.getRect(find.byKey(const Key('role-card-prestador')));

    expect((customer.top - provider.top).abs(), lessThan(1));
    expect(provider.left, greaterThan(customer.right));
    expect((customer.height - provider.height).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantem conteudo acessivel com texto ampliado', (tester) async {
    await _pumpRoleSelector(
      tester,
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.byKey(const Key('role-button-cliente')), findsOneWidget);
    expect(find.byKey(const Key('role-button-prestador')), findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const Key('role-selector-scroll')),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('expõe cabeçalho e ações com semântica adequada', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpRoleSelector(
        tester,
        size: const Size(390, 844),
      );

      final header = tester.getSemantics(find.text('Bem-vindo ao ChegaJá'));
      expect(header.flagsCollection.isHeader, isTrue);
      final customerButton = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Sou cliente',
        ),
      );
      final providerButton = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Sou prestador',
        ),
      );
      expect(customerButton.label, 'Sou cliente');
      expect(customerButton.flagsCollection.isButton, isTrue);
      expect(providerButton.label, 'Sou prestador');
      expect(providerButton.flagsCollection.isButton, isTrue);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _pumpRoleSelector(
  WidgetTester tester, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
  bool u1ExperienceV2 = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        );
      },
      home: RoleSelectorScreen(
        u1ExperienceOverride: u1ExperienceV2,
      ),
    ),
  );
  await tester.pump();
}
