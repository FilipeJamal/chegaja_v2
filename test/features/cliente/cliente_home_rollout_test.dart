import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/cliente/cliente_home_screen.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const services = [
    Servico(
      id: 'quote-service',
      name: 'Pintura',
      mode: 'ORCAMENTO',
      keywords: ['pintura'],
      isActive: true,
    ),
    Servico(
      id: 'now-service',
      name: 'Eletricista',
      mode: 'IMEDIATO',
      keywords: ['eletricista'],
      isActive: true,
    ),
  ];

  Widget app({required bool experienceV2}) {
    return MaterialApp(
      theme: AppTheme.u1LightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: buildClienteServicesCatalogForTest(
            experienceV2: experienceV2,
            servicos: services,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'rollout desligado preserva filtros ChoiceChip e remove superfícies U1',
    (tester) async {
      await tester.pumpWidget(app(experienceV2: false));
      await tester.pump();

      expect(
        find.byKey(const Key('cliente_home_service_search_field')),
        findsOneWidget,
      );
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(
        find.byKey(const Key('cliente_home_mode_selector')),
        findsNothing,
      );
      expect(find.byType(ClienteServiceModeSelector), findsNothing);
      expect(
        find.byKey(const Key('cliente_home_catalog_mode_status')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('cliente_home_quick_services')),
        findsNothing,
      );
    },
  );

  testWidgets('rollout ligado apresenta a composição U1 do catálogo',
      (tester) async {
    await tester.pumpWidget(app(experienceV2: true));
    await tester.pump();

    expect(find.byType(ChoiceChip), findsNothing);
    expect(
      find.byKey(const Key('cliente_home_catalog_mode_status')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('cliente_home_quick_services')),
      findsOneWidget,
    );
  });
}
