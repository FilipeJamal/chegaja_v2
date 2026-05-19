# M2.10.2 Design System Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar a fundacao visual reutilizavel da M2.10 para que Home Cliente, Home Prestador, listas e detalhe possam ser redesenhados com consistencia em Web, Windows e Android.

**Architecture:** A foundation fica em `lib/core/theme` e `lib/core/widgets`, sem dependencia de modelos de negocio. Os componentes devem ser pequenos, testaveis e orientados a layout responsivo, usando os tokens existentes em `app_tokens.dart`. A M2.10.2 nao redesenha telas completas, mas cria componentes prontos para uso e documenta como aplica-los.

**Tech Stack:** Flutter/Dart, Material 3, `flutter_test`, componentes locais `AppButton`, `AppCard`, `AppChip`, `AppTheme`, `AppSpacing`, `AppBreakpoints`.

---

## Contexto

Spec aprovada:

```text
docs/superpowers/specs/2026-05-19-m2-10-1-visual-audit-design-direction.md
```

Commit da spec:

```text
47e77bd7c517c672651ba28253ae4f6d672647f7
Iniciar M2.10.1 visual audit design direction
```

Problema a resolver nesta subfase:

```text
evitar remendos visuais por tela
criar componentes reutilizaveis
preparar responsividade desktop/tablet/mobile
reduzir visual de prototipo nas proximas subfases
```

Fora do escopo:

```text
redesign completo da Home Cliente
redesign completo da Home Prestador
redesign completo do detalhe/listas
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos reais
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Estrutura de ficheiros

Criar:

```text
lib/core/widgets/app_content_shell.dart
lib/core/widgets/app_section_header.dart
lib/core/widgets/app_status_pill.dart
lib/core/widgets/app_metric_tile.dart
lib/core/widgets/app_action_panel.dart
lib/core/widgets/app_responsive_grid.dart
test/core/widgets/app_content_shell_test.dart
test/core/widgets/app_visual_foundation_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
docs/DESIGN_SYSTEM_FOUNDATION.md
```

Modificar:

```text
lib/core/theme/app_tokens.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Nao modificar nesta subfase:

```text
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/cliente/pedido_detalhe_screen.dart
firestore.rules
storage.rules
functions/**
```

Excecao aceitavel: se a execucao decidir demonstrar um componente num ponto
pequeno e seguro, isso deve ser limitado a uma area nao critica e com teste.
Por defeito, esta subfase entrega componentes e docs, nao redesign.

---

### Task 1: Pre-check e protecao de escopo

**Files:**
- Read: `docs/superpowers/specs/2026-05-19-m2-10-1-visual-audit-design-direction.md`
- Read: `lib/core/theme/app_tokens.dart`
- Read: `lib/core/widgets/app_button.dart`
- Read: `lib/core/widgets/app_card.dart`
- Read: `lib/core/widgets/app_chip.dart`
- Read: `lib/core/widgets/app_shell_scaffold.dart`

- [ ] **Step 1: Confirmar branch e working tree**

Run:

```powershell
git branch --show-current
git status --short
git log -1 --oneline
```

Expected:

```text
branch main
ultimo commit deve incluir ou suceder 47e77bd
working tree pode mostrar apenas as duas delecoes antigas dos ~$...pptx
```

- [ ] **Step 2: Confirmar componentes base existentes**

Run:

```powershell
rg -n "class AppTheme|class AppPalette|class AppSpacing|class AppBreakpoints|class AppButton|class AppCard|class AppChip|class AppShellScaffold" lib/core
```

Expected:

```text
app_tokens.dart contem AppPalette, AppSpacing, AppRadius, AppBreakpoints
app_button.dart contem AppButton
app_card.dart contem AppCard
app_chip.dart contem AppChip
app_shell_scaffold.dart contem AppShellScaffold
```

- [ ] **Step 3: Confirmar que ficheiros fora do escopo nao serao alterados**

Run:

```powershell
git diff --name-only
```

Expected:

```text
antes de implementar, nao deve haver alteracoes de codigo alem das antigas delecoes de pptx
durante a implementacao, nao tocar em firestore.rules, storage.rules, functions/**
```

---

### Task 2: Tokens de layout responsivo

**Files:**
- Modify: `lib/core/theme/app_tokens.dart`
- Test indirectly later through: `test/core/widgets/app_content_shell_test.dart`

- [ ] **Step 1: Atualizar `AppBreakpoints` e adicionar `AppLayout`**

Em `lib/core/theme/app_tokens.dart`, manter os tokens existentes e substituir a classe `AppBreakpoints` por esta versao, adicionando `AppLayout` logo abaixo:

```dart
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 599;
  static const double tabletMin = 600;
  static const double tabletMax = 1023;
  static const double desktopMin = 1024;
  static const double wideDesktopMin = 1280;

  static const double contentMaxSingleColumn = 520;
  static const double contentMaxTwoColumn = 960;
  static const double contentMaxDashboard = 1180;
  static const double contentMaxWide = 1320;
}

class AppLayout {
  AppLayout._();

  static const double mobileHorizontalPadding = AppSpacing.x4;
  static const double tabletHorizontalPadding = AppSpacing.x6;
  static const double desktopHorizontalPadding = AppSpacing.x7;

  static const double desktopSidePanelWidth = 360;
  static const double desktopRailGap = AppSpacing.x6;
  static const double sectionGap = AppSpacing.x5;
  static const double pageGap = AppSpacing.x7;
}
```

- [ ] **Step 2: Verificar analise estatica parcial**

Run:

```powershell
dart analyze lib/core/theme/app_tokens.dart
```

Expected:

```text
No issues found
```

Se o projeto nao permitir analisar apenas esse ficheiro por dependencias externas, continuar e validar com `flutter test` no final.

---

### Task 3: AppStatusPill e AppSectionHeader

**Files:**
- Create: `lib/core/widgets/app_status_pill.dart`
- Create: `lib/core/widgets/app_section_header.dart`
- Test: `test/core/widgets/app_visual_foundation_test.dart`

- [ ] **Step 1: Escrever testes que falham**

Criar `test/core/widgets/app_visual_foundation_test.dart` com:

```dart
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visual foundation components', () {
    testWidgets('AppSectionHeader renders title, subtitle and trailing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Pedidos ativos',
              subtitle: 'Acompanha os trabalhos em curso',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Ver todos'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pedidos ativos'), findsOneWidget);
      expect(find.text('Acompanha os trabalhos em curso'), findsOneWidget);
      expect(find.text('Ver todos'), findsOneWidget);
    });

    testWidgets('AppStatusPill renders icon and label by tone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStatusPill(
              label: 'Em andamento',
              tone: AppStatusTone.success,
              icon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Rodar teste para confirmar falha por ficheiros ausentes**

Run:

```powershell
flutter test test/core/widgets/app_visual_foundation_test.dart
```

Expected:

```text
FAIL
Error: Error when reading 'lib/core/widgets/app_section_header.dart'
```

- [ ] **Step 3: Criar `AppStatusPill`**

Criar `lib/core/widgets/app_status_pill.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppStatusTone { neutral, info, success, warning, danger }

enum AppStatusPillSize { sm, md }

class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.size = AppStatusPillSize.md,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final AppStatusPillSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colorsFor(theme, tone);
    final verticalPadding = size == AppStatusPillSize.sm ? 5.0 : 7.0;
    final iconSize = size == AppStatusPillSize.sm ? 14.0 : 16.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: colors.foreground),
              const SizedBox(width: AppSpacing.x1),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusPillColors _colorsFor(ThemeData theme, AppStatusTone tone) {
    final scheme = theme.colorScheme;
    switch (tone) {
      case AppStatusTone.info:
        return _StatusPillColors(
          background: AppPalette.accentBlue.withValues(alpha: 0.10),
          border: AppPalette.accentBlue.withValues(alpha: 0.28),
          foreground: AppPalette.accentBlue,
        );
      case AppStatusTone.success:
        return _StatusPillColors(
          background: AppPalette.success.withValues(alpha: 0.12),
          border: AppPalette.success.withValues(alpha: 0.30),
          foreground: AppPalette.success,
        );
      case AppStatusTone.warning:
        return _StatusPillColors(
          background: AppPalette.warning.withValues(alpha: 0.12),
          border: AppPalette.warning.withValues(alpha: 0.30),
          foreground: AppPalette.warning,
        );
      case AppStatusTone.danger:
        return _StatusPillColors(
          background: AppPalette.error.withValues(alpha: 0.10),
          border: AppPalette.error.withValues(alpha: 0.28),
          foreground: AppPalette.error,
        );
      case AppStatusTone.neutral:
        return _StatusPillColors(
          background: scheme.surfaceContainerHighest,
          border: scheme.outline,
          foreground: scheme.onSurfaceVariant,
        );
    }
  }
}

class _StatusPillColors {
  const _StatusPillColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
```

- [ ] **Step 4: Criar `AppSectionHeader`**

Criar `lib/core/widgets/app_section_header.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = dense ? AppSpacing.x1 : AppSpacing.x2;

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? AppSpacing.x3 : AppSpacing.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: dense
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge,
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  SizedBox(height: gap),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.x4),
            trailing!,
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Rodar teste e confirmar passagem**

Run:

```powershell
flutter test test/core/widgets/app_visual_foundation_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 6: Commit parcial**

Run:

```powershell
git add lib/core/theme/app_tokens.dart `
  lib/core/widgets/app_status_pill.dart `
  lib/core/widgets/app_section_header.dart `
  test/core/widgets/app_visual_foundation_test.dart
git commit -m "Avancar M2.10.2 componentes visuais base"
```

---

### Task 4: AppMetricTile e AppActionPanel

**Files:**
- Create: `lib/core/widgets/app_metric_tile.dart`
- Create: `lib/core/widgets/app_action_panel.dart`
- Modify: `test/core/widgets/app_visual_foundation_test.dart`

- [ ] **Step 1: Adicionar testes que falham**

Adicionar ao grupo em `test/core/widgets/app_visual_foundation_test.dart`:

```dart
    testWidgets('AppMetricTile renders value and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppMetricTile(
              label: 'Pedidos ativos',
              value: '3',
              supportingText: 'Hoje',
              icon: Icons.work_outline,
              tone: AppStatusTone.info,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Pedidos ativos'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });

    testWidgets('AppActionPanel renders action buttons', (tester) async {
      var primaryPressed = false;
      var secondaryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppActionPanel(
              title: 'Proxima acao',
              message: 'Envia uma estimativa para o cliente decidir.',
              icon: Icons.payments_outlined,
              tone: AppStatusTone.warning,
              primaryAction: AppActionPanelAction(
                label: 'Enviar estimativa',
                icon: Icons.send_outlined,
                onPressed: () => primaryPressed = true,
              ),
              secondaryAction: AppActionPanelAction(
                label: 'Cancelar',
                onPressed: () => secondaryPressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Proxima acao'), findsOneWidget);
      expect(
        find.text('Envia uma estimativa para o cliente decidir.'),
        findsOneWidget,
      );
      expect(find.text('Enviar estimativa'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Enviar estimativa'));
      await tester.pump();
      expect(primaryPressed, isTrue);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      expect(secondaryPressed, isTrue);
    });
```

Adicionar imports no topo:

```dart
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
```

- [ ] **Step 2: Rodar teste para confirmar falha por imports ausentes**

Run:

```powershell
flutter test test/core/widgets/app_visual_foundation_test.dart
```

Expected:

```text
FAIL
Error when reading app_action_panel.dart ou app_metric_tile.dart
```

- [ ] **Step 3: Criar `AppMetricTile`**

Criar `lib/core/widgets/app_metric_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_status_pill.dart';

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.supportingText,
    this.icon,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final String value;
  final String? supportingText;
  final IconData? icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(tone, theme);

    return AppCard(
      variant: AppCardVariant.outlined,
      size: AppCardSize.compact,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  label,
                  style: theme.textTheme.labelLarge,
                ),
                if (supportingText != null &&
                    supportingText!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    supportingText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentFor(AppStatusTone tone, ThemeData theme) {
    switch (tone) {
      case AppStatusTone.info:
        return AppPalette.accentBlue;
      case AppStatusTone.success:
        return AppPalette.success;
      case AppStatusTone.warning:
        return AppPalette.warning;
      case AppStatusTone.danger:
        return AppPalette.error;
      case AppStatusTone.neutral:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
```

- [ ] **Step 4: Criar `AppActionPanel`**

Criar `lib/core/widgets/app_action_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_status_pill.dart';

class AppActionPanelAction {
  const AppActionPanelAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
}

class AppActionPanel extends StatelessWidget {
  const AppActionPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.tone = AppStatusTone.info,
    this.primaryAction,
    this.secondaryAction,
    this.trailing,
  });

  final String title;
  final String message;
  final IconData? icon;
  final AppStatusTone tone;
  final AppActionPanelAction? primaryAction;
  final AppActionPanelAction? secondaryAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(tone, theme);

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.x3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.x3),
                trailing!,
              ],
            ],
          ),
          if (primaryAction != null || secondaryAction != null) ...[
            const SizedBox(height: AppSpacing.x4),
            _ActionPanelButtons(
              primaryAction: primaryAction,
              secondaryAction: secondaryAction,
            ),
          ],
        ],
      ),
    );
  }

  Color _accentFor(AppStatusTone tone, ThemeData theme) {
    switch (tone) {
      case AppStatusTone.info:
        return AppPalette.accentBlue;
      case AppStatusTone.success:
        return AppPalette.success;
      case AppStatusTone.warning:
        return AppPalette.warning;
      case AppStatusTone.danger:
        return AppPalette.error;
      case AppStatusTone.neutral:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

class _ActionPanelButtons extends StatelessWidget {
  const _ActionPanelButtons({
    required this.primaryAction,
    required this.secondaryAction,
  });

  final AppActionPanelAction? primaryAction;
  final AppActionPanelAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (primaryAction != null)
        AppButton(
          label: primaryAction!.label,
          onPressed: primaryAction!.onPressed,
          leadingIcon: primaryAction!.icon,
          variant: primaryAction!.variant,
          expanded: true,
        ),
      if (secondaryAction != null)
        AppButton(
          label: secondaryAction!.label,
          onPressed: secondaryAction!.onPressed,
          leadingIcon: secondaryAction!.icon,
          variant: secondaryAction!.variant,
          expanded: true,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 520 && actions.length > 1;
        if (!useRow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < actions.length; index += 1) ...[
                if (index > 0) const SizedBox(height: AppSpacing.x2),
                actions[index],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < actions.length; index += 1) ...[
              if (index > 0) const SizedBox(width: AppSpacing.x3),
              Expanded(child: actions[index]),
            ],
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5: Rodar testes**

Run:

```powershell
flutter test test/core/widgets/app_visual_foundation_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 6: Commit parcial**

Run:

```powershell
git add lib/core/widgets/app_metric_tile.dart `
  lib/core/widgets/app_action_panel.dart `
  test/core/widgets/app_visual_foundation_test.dart
git commit -m "Avancar M2.10.2 paineis e metricas visuais"
```

---

### Task 5: AppContentShell e AppPageScaffold

**Files:**
- Create: `lib/core/widgets/app_content_shell.dart`
- Test: `test/core/widgets/app_content_shell_test.dart`

- [ ] **Step 1: Escrever testes que falham**

Criar `test/core/widgets/app_content_shell_test.dart`:

```dart
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppContentShell constrains compact content width',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppContentShell(
            width: AppContentWidth.compact,
            child: SizedBox(
              key: Key('content'),
              height: 80,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('content')));
    expect(size.width, lessThanOrEqualTo(520));
  });

  testWidgets('AppPageScaffold renders header and scrollable body',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppPageScaffold(
          title: 'Inicio',
          subtitle: 'Organiza os teus servicos',
          child: Text('Conteudo principal'),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Organiza os teus servicos'), findsOneWidget);
    expect(find.text('Conteudo principal'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar teste para confirmar falha por ficheiro ausente**

Run:

```powershell
flutter test test/core/widgets/app_content_shell_test.dart
```

Expected:

```text
FAIL
Error when reading app_content_shell.dart
```

- [ ] **Step 3: Criar `AppContentShell` e `AppPageScaffold`**

Criar `lib/core/widgets/app_content_shell.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_section_header.dart';

enum AppContentWidth { compact, medium, dashboard, wide, full }

class AppContentShell extends StatelessWidget {
  const AppContentShell({
    super.key,
    required this.child,
    this.width = AppContentWidth.dashboard,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AppContentWidth width;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = padding ?? _paddingFor(constraints.maxWidth);
        final maxWidth = _maxWidthFor(width);

        Widget content = Padding(
          padding: resolvedPadding,
          child: child,
        );

        if (maxWidth != null) {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          );
        }

        return Align(
          alignment: alignment,
          child: content,
        );
      },
    );
  }

  EdgeInsetsGeometry _paddingFor(double availableWidth) {
    final horizontal = switch (availableWidth) {
      >= AppBreakpoints.desktopMin => AppLayout.desktopHorizontalPadding,
      >= AppBreakpoints.tabletMin => AppLayout.tabletHorizontalPadding,
      _ => AppLayout.mobileHorizontalPadding,
    };

    return EdgeInsets.fromLTRB(
      horizontal,
      AppSpacing.x5,
      horizontal,
      AppSpacing.x6,
    );
  }

  double? _maxWidthFor(AppContentWidth width) {
    switch (width) {
      case AppContentWidth.compact:
        return AppBreakpoints.contentMaxSingleColumn;
      case AppContentWidth.medium:
        return AppBreakpoints.contentMaxTwoColumn;
      case AppContentWidth.dashboard:
        return AppBreakpoints.contentMaxDashboard;
      case AppContentWidth.wide:
        return AppBreakpoints.contentMaxWide;
      case AppContentWidth.full:
        return null;
    }
  }
}

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.width = AppContentWidth.dashboard,
    this.scrollable = true,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final AppContentWidth width;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final page = AppContentShell(
      width: width,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.trim().isNotEmpty)
            AppSectionHeader(
              title: title!,
              subtitle: subtitle,
              trailing: actions == null || actions!.isEmpty
                  ? null
                  : Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x2,
                      children: actions!,
                    ),
            ),
          child,
        ],
      ),
    );

    final background = Theme.of(context).scaffoldBackgroundColor;

    return ColoredBox(
      color: background,
      child: SafeArea(
        child: scrollable
            ? SingleChildScrollView(child: page)
            : SizedBox.expand(child: page),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar testes**

Run:

```powershell
flutter test test/core/widgets/app_content_shell_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 5: Commit parcial**

Run:

```powershell
git add lib/core/widgets/app_content_shell.dart test/core/widgets/app_content_shell_test.dart
git commit -m "Avancar M2.10.2 shell responsivo"
```

---

### Task 6: AppResponsiveGrid

**Files:**
- Create: `lib/core/widgets/app_responsive_grid.dart`
- Modify: `test/core/widgets/app_content_shell_test.dart`

- [ ] **Step 1: Adicionar teste que falha para grid responsivo**

Adicionar import em `test/core/widgets/app_content_shell_test.dart`:

```dart
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
```

Adicionar teste:

```dart
  testWidgets('AppResponsiveGrid uses multiple columns on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: AppResponsiveGrid(
              minItemWidth: 260,
              children: List.generate(
                4,
                (index) => SizedBox(
                  key: Key('tile-$index'),
                  height: 80,
                  child: Text('Tile $index'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final first = tester.getTopLeft(find.byKey(const Key('tile-0')));
    final second = tester.getTopLeft(find.byKey(const Key('tile-1')));
    expect(second.dx, greaterThan(first.dx));
    expect(second.dy, equals(first.dy));
  });
```

- [ ] **Step 2: Rodar teste para confirmar falha por ficheiro ausente**

Run:

```powershell
flutter test test/core/widgets/app_content_shell_test.dart
```

Expected:

```text
FAIL
Error when reading app_responsive_grid.dart
```

- [ ] **Step 3: Criar `AppResponsiveGrid`**

Criar `lib/core/widgets/app_responsive_grid.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 260,
    this.spacing = AppSpacing.x4,
    this.runSpacing = AppSpacing.x4,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minItemWidth;
        final columns = math.max(
          1,
          ((availableWidth + spacing) / (minItemWidth + spacing)).floor(),
        );
        final itemWidth =
            (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Rodar testes**

Run:

```powershell
flutter test test/core/widgets/app_content_shell_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 5: Commit parcial**

Run:

```powershell
git add lib/core/widgets/app_responsive_grid.dart test/core/widgets/app_content_shell_test.dart
git commit -m "Avancar M2.10.2 grid responsivo"
```

---

### Task 7: Documentacao de uso e status M2.10

**Files:**
- Create: `docs/DESIGN_SYSTEM_FOUNDATION.md`
- Create: `docs/M2_10_VISUAL_PRODUCT_STATUS.md`

- [ ] **Step 1: Criar documentacao da foundation**

Criar `docs/DESIGN_SYSTEM_FOUNDATION.md`:

```markdown
# Design System Foundation

Data: 2026-05-19

## Objetivo

Esta foundation existe para dar consistencia visual ao redesign M2.10 do
ChegaJa em Web, Windows e Android.

## Componentes

### AppContentShell

Centraliza e limita a largura do conteudo conforme o contexto.

Uso recomendado:

```dart
AppContentShell(
  width: AppContentWidth.dashboard,
  child: MinhaTela(),
)
```

### AppPageScaffold

Cria uma estrutura de pagina com titulo, subtitulo, acoes opcionais e padding
responsivo. Deve ser usado dentro de `AppShellScaffold` ou como corpo de uma
tela operacional.

### AppSectionHeader

Padroniza titulos de secoes, subtitulos e acao lateral.

### AppStatusPill

Padroniza estados curtos como `Aberto`, `Em andamento`, `Concluido`,
`Pendente` e `Cancelado`.

### AppMetricTile

Mostra metricas operacionais, como pedidos ativos, ganhos estimados ou trabalhos
concluidos.

### AppActionPanel

Agrupa uma proxima acao com contexto e botoes. Deve ser usado para reduzir
botoes soltos em paginas de pedido, home e fluxo.

### AppResponsiveGrid

Organiza cards em uma ou mais colunas sem transformar desktop em mobile
esticado.

## Regras de uso

```text
nao criar estilos locais se um componente core resolver o caso
nao colocar cards dentro de cards
nao usar grids em mobile quando uma coluna for mais clara
preservar keys existentes de E2E/Android
manter regra de negocio fora dos widgets visuais
```

## Proximas fases

```text
M2.10.3: Home Cliente redesign
M2.10.4: Home Prestador redesign
M2.10.5: Pedido/listas/detalhe polish
M2.10.6: Responsividade Web/Windows/Android
M2.10.7: QA visual e fecho
```
```

- [ ] **Step 2: Criar status da M2.10**

Criar `docs/M2_10_VISUAL_PRODUCT_STATUS.md`:

```markdown
# M2.10 Visual Product System Status

Data: 2026-05-19

## Estado

```text
M2.9: fechado
M2.10: iniciado
M2.10.1: spec visual audit e design direction
M2.10.2: design system foundation em implementacao
```

## Objetivo da M2.10

Tirar o ChegaJa do aspeto de prototipo e criar uma experiencia visual mais
profissional, organizada e responsiva para Web, Windows e Android.

## M2.10.2

Escopo:

```text
tokens responsivos
AppContentShell
AppPageScaffold
AppSectionHeader
AppStatusPill
AppMetricTile
AppActionPanel
AppResponsiveGrid
testes de componentes
documentacao de uso
```

Fora do escopo:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia

| Comando | Resultado |
| --- | --- |
| `flutter test` | pendente ate a validacao final da M2.10.2 |
| `npm.cmd run test:scripts` | pendente ate a validacao final da M2.10.2 |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | pendente ate a validacao final da M2.10.2 |
```

- [ ] **Step 3: Commit parcial**

Run:

```powershell
git add docs/DESIGN_SYSTEM_FOUNDATION.md docs/M2_10_VISUAL_PRODUCT_STATUS.md
git commit -m "Documentar M2.10.2 design system foundation"
```

---

### Task 8: Validacao final da M2.10.2

**Files:**
- All files touched in previous tasks

- [ ] **Step 1: Formatar ficheiros Dart tocados**

Run:

```powershell
dart format `
  lib/core/theme/app_tokens.dart `
  lib/core/widgets/app_status_pill.dart `
  lib/core/widgets/app_section_header.dart `
  lib/core/widgets/app_metric_tile.dart `
  lib/core/widgets/app_action_panel.dart `
  lib/core/widgets/app_content_shell.dart `
  lib/core/widgets/app_responsive_grid.dart `
  test/core/widgets/app_visual_foundation_test.dart `
  test/core/widgets/app_content_shell_test.dart
```

Expected:

```text
Formatted ...
```

- [ ] **Step 2: Rodar testes Flutter**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed
```

- [ ] **Step 3: Rodar testes de scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```text
run_android_integration_test args ok
cleanup_smoke_data safeguards ok
firebase_production_health parsing ok
```

- [ ] **Step 4: Rodar testes Firebase Emulator Suite**

Run:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
37 passing
Script exited successfully (code 0)
```

- [ ] **Step 5: Verificar escopo Git**

Run:

```powershell
git status --short
git diff --name-only HEAD
```

Expected:

```text
alteracoes apenas em lib/core/theme, lib/core/widgets, test/core/widgets e docs
as duas delecoes antigas dos ~$...pptx continuam fora de commits
sem firestore.rules
sem storage.rules
sem functions/**
```

- [ ] **Step 6: Atualizar evidencia no status**

Modificar `docs/M2_10_VISUAL_PRODUCT_STATUS.md`, substituindo o bloco de evidencia por:

```markdown
## Evidencia

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
```

- [ ] **Step 7: Commit final da subfase**

Run:

```powershell
git add docs/M2_10_VISUAL_PRODUCT_STATUS.md
git commit -m "Avancar M2.10.2 design system foundation"
```

- [ ] **Step 8: Push**

Run:

```powershell
git push origin main
```

Expected:

```text
main -> main
```

---

## Criterios de aceite

```text
tokens responsivos adicionados
AppContentShell criado e testado
AppPageScaffold criado e testado
AppSectionHeader criado e testado
AppActionPanel criado e testado
AppStatusPill criado e testado
AppMetricTile criado e testado
AppResponsiveGrid criado e testado
docs de uso criadas
status M2.10 criado/atualizado
flutter test passou
test:scripts passou
Firebase Emulator Suite tests passaram
nenhuma regra/backend/function/deploy alterado
duas delecoes antigas dos ~$...pptx nao foram commitadas
```

## Riscos e mitigacoes

```text
Risco: foundation teorica que ninguem usa.
Mitigacao: componentes devem ter testes e docs com exemplos. M2.10.3 deve usar
AppContentShell, AppSectionHeader, AppActionPanel e AppResponsiveGrid na Home
Cliente.

Risco: quebrar visual existente por mudar tema global demais.
Mitigacao: M2.10.2 deve adicionar tokens e componentes, nao redesenhar tema
inteiro nem alterar telas de produto.

Risco: nomes duplicarem widgets ja existentes.
Mitigacao: usar prefixo App e manter responsabilidade clara em core/widgets.

Risco: desktop continuar com canvas vazio.
Mitigacao: AppContentShell e AppResponsiveGrid devem suportar dashboard/wide e
ser usados nas proximas subfases.
```

## Proxima fase recomendada

Depois da M2.10.2:

```text
M2.10.3 - Home Cliente redesign
```

Essa fase deve aplicar a foundation em uma tela real de alto impacto, sem
introduzir backend novo.
