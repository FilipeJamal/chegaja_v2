import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/category_requirement.dart';
import 'package:chegaja_v2/core/models/provider_category_approval.dart';
import 'package:chegaja_v2/core/models/sensitive_category_request.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_sensitive_categories_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    ),
  );
}

CategoryRequirement _requirement({
  String id = 'electricity',
  String name = 'Eletricidade',
}) {
  return CategoryRequirement(
    categoryId: id,
    categoryName: name,
    riskLevel: CategoryRiskLevel.sensitive,
    approvalRequired: true,
    evidenceTypes: const [
      EvidenceType.workExperience,
      EvidenceType.portfolioReference,
    ],
    userMessage: 'Esta categoria precisa de analise antes de ficar aprovada.',
  );
}

void main() {
  testWidgets('mostra categoria sensivel e pedido em analise', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorSensitiveCategoriesSection(
          requirements: [_requirement()],
          requests: const [
            SensitiveCategoryRequest(
              id: 'request1',
              providerId: 'provider1',
              categoryId: 'electricity',
              categoryName: 'Eletricidade',
              status: SensitiveCategoryRequestStatus.pendingReview,
            ),
          ],
          approvals: const [],
          onRequestApproval: (_, __) {},
        ),
      ),
    );

    expect(find.text('Categorias sensiveis e comprovativos'), findsOneWidget);
    expect(find.text('Eletricidade'), findsOneWidget);
    expect(find.text('Em analise'), findsOneWidget);
    expect(find.text('Pedir aprovacao'), findsNothing);
  });

  testWidgets('mostra aprovacao ativa quando existe approval atual',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorSensitiveCategoriesSection(
          requirements: [_requirement(id: 'gas', name: 'Gas')],
          requests: const [],
          approvals: const [
            ProviderCategoryApproval(
              providerId: 'provider1',
              categoryId: 'gas',
              categoryName: 'Gas',
              status: ProviderCategoryApprovalStatus.approved,
            ),
          ],
          onRequestApproval: (_, __) {},
        ),
      ),
    );

    expect(find.text('Gas'), findsOneWidget);
    expect(find.text('Aprovacao ativa'), findsOneWidget);
    expect(find.text('Pedir aprovacao'), findsNothing);
  });

  testWidgets('estado vazio, erro e callback de pedido funcionam',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorSensitiveCategoriesSection(
          requirements: const [],
          requests: const [],
          approvals: const [],
          onRequestApproval: (_, __) {},
        ),
      ),
    );

    expect(find.text('Sem categorias sensiveis selecionadas.'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        PrestadorSensitiveCategoriesSection(
          requirements: [_requirement()],
          requests: const [],
          approvals: const [],
          error: 'Nao foi possivel carregar categorias.',
          onRequestApproval: (_, __) {},
        ),
      ),
    );

    expect(find.text('Nao foi possivel carregar categorias.'), findsOneWidget);

    final tapped = <String>[];
    await tester.pumpWidget(
      _wrap(
        PrestadorSensitiveCategoriesSection(
          requirements: [_requirement()],
          requests: const [],
          approvals: const [],
          onRequestApproval: (requirement, request) {
            tapped.add('${requirement.categoryId}:${request?.id ?? '-'}');
          },
        ),
      ),
    );

    await tester.tap(find.text('Pedir aprovacao'));
    await tester.pump();

    expect(tapped, ['electricity:-']);
  });

  testWidgets('permite atualizar quando pedido precisa de mais informacao',
      (tester) async {
    final tapped = <String>[];

    await tester.pumpWidget(
      _wrap(
        PrestadorSensitiveCategoriesSection(
          requirements: [_requirement()],
          requests: const [
            SensitiveCategoryRequest(
              id: 'request2',
              providerId: 'provider1',
              categoryId: 'electricity',
              categoryName: 'Eletricidade',
              status: SensitiveCategoryRequestStatus.needsMoreInfo,
            ),
          ],
          approvals: const [],
          onRequestApproval: (requirement, request) {
            tapped.add(request?.id ?? '-');
          },
        ),
      ),
    );

    expect(find.text('Precisa de mais informacao'), findsOneWidget);
    await tester.tap(find.text('Atualizar informacao'));
    await tester.pump();

    expect(tapped, ['request2']);
  });

  testWidgets('dark mode renderiza e nao usa textos proibidos', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorSensitiveCategoriesSection(
          requirements: [_requirement()],
          requests: const [],
          approvals: const [],
          onRequestApproval: (_, __) {},
        ),
        theme: AppTheme.darkTheme,
      ),
    );

    expect(find.text('Categorias sensiveis e comprovativos'), findsOneWidget);
    expect(find.textContaining('Prestador certificado'), findsNothing);
    expect(find.textContaining('verificado'), findsNothing);
    expect(find.textContaining('garantido'), findsNothing);
    expect(find.textContaining('pagamento seguro'), findsNothing);
    expect(find.textContaining('aprovado oficialmente'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
