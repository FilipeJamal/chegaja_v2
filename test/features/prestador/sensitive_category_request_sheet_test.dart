import 'dart:async';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/category_requirement.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/prestador/widgets/sensitive_category_request_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(
      body: child,
    ),
  );
}

CategoryRequirement _requirement() {
  return const CategoryRequirement(
    categoryId: 'child_care',
    categoryName: 'Cuidados infantis',
    riskLevel: CategoryRiskLevel.sensitive,
    approvalRequired: true,
    evidenceTypes: [
      EvidenceType.workExperience,
      EvidenceType.portfolioReference,
      EvidenceType.externalProfile,
    ],
    userMessage: 'Explica a tua experiencia nesta categoria.',
  );
}

void main() {
  testWidgets('mostra categoria, evidencias, aviso de privacidade e sem upload',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SensitiveCategoryRequestSheet(
          requirement: _requirement(),
          portfolioUrls: const ['https://example.com/obra.jpg'],
          onSubmit: (_) async {},
        ),
      ),
    );

    expect(find.text('Cuidados infantis'), findsOneWidget);
    expect(find.text('Experiencia de trabalho'), findsOneWidget);
    expect(find.text('Portfolio publico'), findsWidgets);
    expect(find.text('Perfil profissional externo'), findsOneWidget);
    expect(
      find.text(
        'Nao envies documentos pessoais neste campo. Se for necessario, o ChegaJa pedira de forma segura.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('ficheiros fica para uma fase posterior'),
        findsOneWidget);
    expect(find.textContaining('Anexar documento'), findsNothing);
  });

  testWidgets('valida dados e envia payload correto', (tester) async {
    final submitted = <SensitiveCategoryRequestInput>[];

    await tester.pumpWidget(
      _wrap(
        SensitiveCategoryRequestSheet(
          requirement: _requirement(),
          portfolioUrls: const ['https://example.com/obra.jpg'],
          onSubmit: (input) async => submitted.add(input),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Enviar pedido'));
    await tester.tap(find.text('Enviar pedido'));
    await tester.pump();

    expect(
      find.text('Seleciona pelo menos um tipo de comprovativo.'),
      findsOneWidget,
    );

    final workExperienceChip =
        find.widgetWithText(FilterChip, 'Experiencia de trabalho');
    await tester.ensureVisible(workExperienceChip);
    await tester.tap(workExperienceChip);
    await tester.enterText(
      find.byKey(const Key('sensitive_category_evidence_text')),
      'Tenho experiencia comprovavel nesta categoria.',
    );
    await tester
        .ensureVisible(find.textContaining('https://example.com/obra.jpg'));
    await tester.tap(find.textContaining('https://example.com/obra.jpg'));
    await tester.ensureVisible(find.text('Enviar pedido'));
    await tester.tap(find.text('Enviar pedido'));
    await tester.pumpAndSettle();

    expect(submitted, hasLength(1));
    expect(submitted.single.evidenceTypes, [EvidenceType.workExperience]);
    expect(
      submitted.single.evidenceText,
      'Tenho experiencia comprovavel nesta categoria.',
    );
    expect(submitted.single.portfolioUrls, ['https://example.com/obra.jpg']);
  });

  testWidgets('loading bloqueia duplo clique', (tester) async {
    final completer = Completer<void>();
    var submitCount = 0;

    await tester.pumpWidget(
      _wrap(
        SensitiveCategoryRequestSheet(
          requirement: _requirement(),
          onSubmit: (_) {
            submitCount++;
            return completer.future;
          },
        ),
      ),
    );

    final workExperienceChip =
        find.widgetWithText(FilterChip, 'Experiencia de trabalho');
    await tester.ensureVisible(workExperienceChip);
    await tester.tap(workExperienceChip);
    await tester.enterText(
      find.byKey(const Key('sensitive_category_evidence_text')),
      'Tenho experiencia comprovavel nesta categoria.',
    );
    await tester.ensureVisible(find.text('Enviar pedido'));
    await tester.tap(find.text('Enviar pedido'));
    await tester.pump();
    await tester.ensureVisible(find.text('A enviar...'));
    await tester.tap(find.text('A enviar...'), warnIfMissed: false);
    await tester.pump();

    expect(submitCount, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('erro de envio mostra feedback seguro', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SensitiveCategoryRequestSheet(
          requirement: _requirement(),
          onSubmit: (_) async => throw Exception('backend detail'),
        ),
      ),
    );

    final retryWorkExperienceChip =
        find.widgetWithText(FilterChip, 'Experiencia de trabalho');
    await tester.ensureVisible(retryWorkExperienceChip);
    await tester.tap(retryWorkExperienceChip);
    await tester.enterText(
      find.byKey(const Key('sensitive_category_evidence_text')),
      'Tenho experiencia comprovavel nesta categoria.',
    );
    await tester.ensureVisible(find.text('Enviar pedido'));
    await tester.tap(find.text('Enviar pedido'));
    await tester.pumpAndSettle();

    expect(
        find.text('Nao conseguimos enviar este pedido agora.'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('dark mode renderiza sem erro', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SensitiveCategoryRequestSheet(
          requirement: _requirement(),
          onSubmit: (_) async {},
        ),
        theme: AppTheme.darkTheme,
      ),
    );

    expect(find.text('Cuidados infantis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
