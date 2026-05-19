# M2.10.5 Pedido Listas Detalhe Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplicar a qualidade visual da M2.10 ao sistema de pedidos como conjunto: listas, cards, detalhe, timeline, paineis de acao e estados finais.

**Architecture:** A implementacao mantem os presenters, services, repositorios, callbacks e rules existentes, e adiciona uma camada visual focada em `lib/features/cliente/widgets/pedido_detail_components.dart`. O detalhe passa a usar layout responsivo com coluna principal e rail lateral em desktop, uma coluna em mobile, e os widgets existentes de lista/acoes/timeline sao polidos com a foundation M2.10.2 sem mover regra de negocio para UI.

**Tech Stack:** Flutter/Dart, Material 3, `flutter_test`, `AppTokens`, `AppPageScaffold`, `AppContentShell`, `AppActionPanel`, `AppStatusPill`, `AppMetricTile`, `AppCard`, `PedidoStatusPresenter`, `PedidoListPresenter`, Firebase streams existentes.

---

## Contexto

Spec aprovada:

```txt
docs/superpowers/specs/2026-05-19-m2-10-5-pedido-listas-detalhe-polish-design.md
```

Commit da spec:

```txt
a63f3449c9c43d4cc7be3c2eb0a3358a75322bb3
Iniciar M2.10.5 pedido listas detalhe polish
```

Estado visual anterior:

```txt
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
M2.10.4: avancado com Home Prestador redesign
```

## Fora do escopo

```txt
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

Nao tocar:

```txt
firestore.rules
storage.rules
functions/**
lib/core/repositories/pedido_repo.dart
lib/core/services/pedido_service.dart
lib/core/services/location_service.dart
lib/core/services/chat_service.dart
android/key.properties
keystore
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
```

## Estrutura de ficheiros

Criar:

```txt
lib/features/cliente/widgets/pedido_detail_components.dart
test/features/cliente/widgets/pedido_detail_components_test.dart
test/features/cliente/widgets/pedido_detail_responsive_test.dart
```

Modificar:

```txt
lib/features/cliente/pedido_detalhe_screen.dart
lib/features/cliente/widgets/pedido_status_summary.dart
lib/features/cliente/widgets/pedido_next_action_card.dart
lib/features/cliente/widgets/pedido_timeline.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
test/features/cliente/widgets/pedido_list_card_test.dart
test/features/cliente/widgets/pedido_final_state_panel_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Nao modificar:

```txt
lib/core/repositories/pedido_repo.dart
lib/core/services/pedido_service.dart
lib/core/services/location_service.dart
lib/core/services/chat_service.dart
firestore.rules
storage.rules
functions/**
```

## Keys e comportamentos que devem permanecer

Preservar exatamente:

```txt
cliente_rejeitar_proposta_button
cliente_aceitar_proposta_button
cliente_duvida_valor_button
confirmar_valor_button
prestador_enviar_orcamento_button
prestador_iniciar_servico_button
valor_final_field
prestador_enviar_valor_final_button
prestador_lancar_valor_final_button
prestador_orcamento_dialog_later_button
prestador_orcamento_dialog_now_button
orcamento_min_field
orcamento_max_field
orcamento_msg_field
orcamento_enviar_button
prestador_pedido_card_<pedidoId>
prestador_aceitar_pedido_<pedidoId>
prestador_ignorar_pedido_<pedidoId>
```

Adicionar keys novas para cobertura visual:

```dart
const Key('pedido_detail_layout')
const Key('pedido_detail_main_column')
const Key('pedido_detail_side_panel')
const Key('pedido_value_summary')
const Key('pedido_action_panel_section')
```

---

### Task 1: Testes dos componentes puros de pedido

**Files:**
- Create: `test/features/cliente/widgets/pedido_detail_components_test.dart`
- Create later: `lib/features/cliente/widgets/pedido_detail_components.dart`

- [ ] **Step 1: Criar teste falhando para layout, side panel e value summary**

Criar `test/features/cliente/widgets/pedido_detail_components_test.dart`:

```dart
import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_detail_components.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido buildPedido({
  String estado = 'aceito',
  String statusConfirmacaoValor = 'nenhum',
  double? precoPropostoPrestador,
  double? precoFinal,
  double? valorMinEstimadoPrestador,
  double? valorMaxEstimadoPrestador,
}) {
  return Pedido(
    id: 'pedido_42',
    clienteId: 'cliente_1',
    prestadorId: 'prestador_1',
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    categoria: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida perto da cozinha',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: 'por_orcamento',
    tipoPagamento: 'dinheiro',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: statusConfirmacaoValor,
    precoPropostoPrestador: precoPropostoPrestador,
    precoFinal: precoFinal,
    valorMinEstimadoPrestador: valorMinEstimadoPrestador,
    valorMaxEstimadoPrestador: valorMaxEstimadoPrestador,
    createdAt: DateTime(2026, 5, 19),
  );
}

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PedidoDetailLayout', () {
    testWidgets('usa uma coluna em mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          PedidoDetailLayout(
            mainColumn: const SizedBox(
              key: Key('main-content'),
              height: 80,
              child: Text('Main'),
            ),
            sidePanel: const SizedBox(
              key: Key('side-content'),
              height: 80,
              child: Text('Side'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pedido_detail_layout')), findsOneWidget);
      final mainTop = tester.getTopLeft(find.byKey(const Key('main-content')));
      final sideTop = tester.getTopLeft(find.byKey(const Key('side-content')));
      expect(sideTop.dy, greaterThan(mainTop.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('usa duas colunas em desktop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          PedidoDetailLayout(
            mainColumn: const SizedBox(
              key: Key('main-content'),
              height: 80,
              child: Text('Main'),
            ),
            sidePanel: const SizedBox(
              key: Key('side-content'),
              height: 80,
              child: Text('Side'),
            ),
          ),
        ),
      );

      final mainTop = tester.getTopLeft(find.byKey(const Key('main-content')));
      final sideTop = tester.getTopLeft(find.byKey(const Key('side-content')));
      expect(sideTop.dx, greaterThan(mainTop.dx));
      expect((sideTop.dy - mainTop.dy).abs(), lessThan(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('PedidoValueSummary', () {
    testWidgets('mostra faixa estimada como valor nao final', (tester) async {
      await tester.pumpWidget(
        wrap(
          PedidoValueSummary(
            pedido: buildPedido(
              valorMinEstimadoPrestador: 20,
              valorMaxEstimadoPrestador: 35,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pedido_value_summary')), findsOneWidget);
      expect(find.text('Faixa estimada'), findsOneWidget);
      expect(find.textContaining('Nao e o valor final'), findsOneWidget);
    });

    testWidgets('mostra valor final pendente', (tester) async {
      await tester.pumpWidget(
        wrap(
          PedidoValueSummary(
            pedido: buildPedido(
              estado: 'aguarda_confirmacao_valor',
              statusConfirmacaoValor: 'pendente_cliente',
              precoPropostoPrestador: 85,
            ),
          ),
        ),
      );

      expect(find.text('Valor final pendente'), findsOneWidget);
      expect(find.textContaining('85'), findsOneWidget);
    });
  });

  group('PedidoDetailSidePanel', () {
    testWidgets('mostra status, proxima acao e valor', (tester) async {
      final pedido = buildPedido(precoPropostoPrestador: 80);
      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      await tester.pumpWidget(
        wrap(
          PedidoDetailSidePanel(
            pedido: pedido,
            summary: summary,
            nextAction: nextAction,
            actions: const SizedBox(
              key: Key('actions-slot'),
              child: Text('Acoes'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pedido_detail_side_panel')), findsOneWidget);
      expect(find.byKey(const Key('pedido_value_summary')), findsOneWidget);
      expect(find.byKey(const Key('actions-slot')), findsOneWidget);
      expect(find.text('Acoes'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Rodar teste para confirmar falha por componente ausente**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_detail_components_test.dart
```

Expected:

```txt
FAIL: Target of URI doesn't exist: package:chegaja_v2/features/cliente/widgets/pedido_detail_components.dart
```

---

### Task 2: Criar componentes visuais de detalhe

**Files:**
- Create: `lib/features/cliente/widgets/pedido_detail_components.dart`
- Test: `test/features/cliente/widgets/pedido_detail_components_test.dart`

- [ ] **Step 1: Criar `pedido_detail_components.dart` com layout, side panel e resumo de valor**

Criar `lib/features/cliente/widgets/pedido_detail_components.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/utils/currency_utils.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_next_action_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_summary.dart';

class PedidoDetailLayout extends StatelessWidget {
  const PedidoDetailLayout({
    super.key,
    required this.mainColumn,
    required this.sidePanel,
  });

  final Widget mainColumn;
  final Widget sidePanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const Key('pedido_detail_layout'),
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 980;

        if (!useTwoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(
                key: const Key('pedido_detail_side_panel'),
                child: sidePanel,
              ),
              const SizedBox(height: AppSpacing.x4),
              KeyedSubtree(
                key: const Key('pedido_detail_main_column'),
                child: mainColumn,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: KeyedSubtree(
                key: const Key('pedido_detail_main_column'),
                child: mainColumn,
              ),
            ),
            const SizedBox(width: AppSpacing.x5),
            SizedBox(
              width: 360,
              child: KeyedSubtree(
                key: const Key('pedido_detail_side_panel'),
                child: sidePanel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class PedidoDetailSidePanel extends StatelessWidget {
  const PedidoDetailSidePanel({
    super.key,
    required this.pedido,
    required this.summary,
    required this.nextAction,
    this.actions,
  });

  final Pedido pedido;
  final PedidoStatusSummaryData summary;
  final PedidoNextActionData nextAction;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PedidoStatusSummary(data: summary),
        const SizedBox(height: AppSpacing.x3),
        PedidoNextActionCard(data: nextAction),
        const SizedBox(height: AppSpacing.x3),
        PedidoValueSummary(pedido: pedido),
        if (actions != null) ...[
          const SizedBox(height: AppSpacing.x3),
          actions!,
        ],
      ],
    );
  }
}

class PedidoValueSummary extends StatelessWidget {
  const PedidoValueSummary({
    super.key,
    required this.pedido,
  });

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final data = _PedidoValueSummaryData.fromPedido(pedido);

    return AppCard(
      key: const Key('pedido_value_summary'),
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusPill(
            label: data.title,
            tone: data.tone,
            icon: data.icon,
          ),
          const SizedBox(height: AppSpacing.x3),
          AppMetricTile(
            label: data.label,
            value: data.value,
            supportingText: data.supportingText,
            icon: data.icon,
            tone: data.tone,
          ),
        ],
      ),
    );
  }
}

class PedidoActionPanelSection extends StatelessWidget {
  const PedidoActionPanelSection({
    super.key,
    required this.title,
    required this.message,
    required this.child,
    this.icon = Icons.touch_app_rounded,
    this.tone = AppStatusTone.info,
  });

  final String title;
  final String message;
  final Widget child;
  final IconData icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('pedido_action_panel_section'),
      title: title,
      message: message,
      icon: icon,
      tone: tone,
      trailing: const Icon(Icons.more_horiz_rounded),
      primaryAction: null,
      secondaryAction: null,
    ).withChildBelow(child);
  }
}

class _PedidoValueSummaryData {
  const _PedidoValueSummaryData({
    required this.title,
    required this.label,
    required this.value,
    required this.supportingText,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String label;
  final String value;
  final String supportingText;
  final IconData icon;
  final AppStatusTone tone;

  static _PedidoValueSummaryData fromPedido(Pedido pedido) {
    String money(double value) => CurrencyUtils.format(value);

    if (pedido.precoFinal != null &&
        pedido.statusConfirmacaoValor == 'confirmado_cliente') {
      return _PedidoValueSummaryData(
        title: 'Valor confirmado',
        label: 'Valor final',
        value: money(pedido.precoFinal!),
        supportingText: 'Backend calcula comissao e ganhos do prestador.',
        icon: Icons.verified_rounded,
        tone: AppStatusTone.success,
      );
    }

    if (pedido.precoPropostoPrestador != null &&
        (pedido.statusConfirmacaoValor == 'pendente_cliente' ||
            pedido.estado == 'aguarda_confirmacao_valor')) {
      return _PedidoValueSummaryData(
        title: 'Valor final pendente',
        label: 'A confirmar',
        value: money(pedido.precoPropostoPrestador!),
        supportingText: 'O cliente precisa confirmar antes de concluir.',
        icon: Icons.price_check_rounded,
        tone: AppStatusTone.warning,
      );
    }

    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;
    if (min != null && max != null) {
      return _PedidoValueSummaryData(
        title: 'Faixa estimada',
        label: 'Estimativa',
        value: '${money(min)} - ${money(max)}',
        supportingText: 'Nao e o valor final. O valor final vem depois.',
        icon: Icons.request_quote_rounded,
        tone: AppStatusTone.info,
      );
    }

    if (min != null || max != null) {
      final value = min != null ? 'Desde ${money(min)}' : 'Ate ${money(max!)}';
      return _PedidoValueSummaryData(
        title: 'Faixa estimada',
        label: 'Estimativa',
        value: value,
        supportingText: 'Nao e o valor final. O valor final vem depois.',
        icon: Icons.request_quote_rounded,
        tone: AppStatusTone.info,
      );
    }

    if (pedido.precoFinal != null) {
      return _PedidoValueSummaryData(
        title: 'Valor final',
        label: 'Valor registado',
        value: money(pedido.precoFinal!),
        supportingText: 'Consulta o estado para saber se ja foi confirmado.',
        icon: Icons.euro_rounded,
        tone: AppStatusTone.info,
      );
    }

    return const _PedidoValueSummaryData(
      title: 'Valor a combinar',
      label: 'Preco',
      value: 'A combinar',
      supportingText: 'O valor final sera definido no fluxo do pedido.',
      icon: Icons.euro_rounded,
      tone: AppStatusTone.neutral,
    );
  }
}

extension _AppActionPanelChild on AppActionPanel {
  Widget withChildBelow(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        this,
        const SizedBox(height: AppSpacing.x3),
        child,
      ],
    );
  }
}
```

- [ ] **Step 2: Corrigir `PedidoActionPanelSection` para nao depender de extensao em widget se o analyzer reclamar**

Se o analyzer apontar problema na extensao privada por estilo/localizacao, substituir `PedidoActionPanelSection.build` por esta implementacao equivalente:

```dart
@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppActionPanel(
        key: const Key('pedido_action_panel_section'),
        title: title,
        message: message,
        icon: icon,
        tone: tone,
      ),
      const SizedBox(height: AppSpacing.x3),
      child,
    ],
  );
}
```

- [ ] **Step 3: Rodar teste dos componentes**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_detail_components_test.dart
```

Expected:

```txt
All tests passed.
```

- [ ] **Step 4: Rodar analyze incremental**

Run:

```powershell
dart analyze lib/features/cliente/widgets/pedido_detail_components.dart
```

Expected:

```txt
No issues found!
```

---

### Task 3: Polir status, proxima acao e timeline

**Files:**
- Modify: `lib/features/cliente/widgets/pedido_status_summary.dart`
- Modify: `lib/features/cliente/widgets/pedido_next_action_card.dart`
- Modify: `lib/features/cliente/widgets/pedido_timeline.dart`
- Test: `test/features/cliente/widgets/pedido_detail_components_test.dart`

- [ ] **Step 1: Atualizar `PedidoStatusSummary` para usar `AppActionPanel`**

Substituir a implementacao visual de `PedidoStatusSummary.build` por uma versao baseada na foundation:

```dart
@override
Widget build(BuildContext context) {
  return AppActionPanel(
    title: data.title,
    message: '${data.description}\n${data.actor}',
    icon: data.icon,
    tone: _toneFor(data.tone),
  );
}

AppStatusTone _toneFor(PedidoStatusTone tone) {
  return switch (tone) {
    PedidoStatusTone.success => AppStatusTone.success,
    PedidoStatusTone.warning => AppStatusTone.warning,
    PedidoStatusTone.danger => AppStatusTone.danger,
    PedidoStatusTone.neutral => AppStatusTone.neutral,
    PedidoStatusTone.info => AppStatusTone.info,
  };
}
```

Adicionar imports:

```dart
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
```

- [ ] **Step 2: Atualizar `PedidoNextActionCard` para usar `AppActionPanel`**

Substituir a implementacao visual de `PedidoNextActionCard.build` por:

```dart
@override
Widget build(BuildContext context) {
  return AppActionPanel(
    title: data.title,
    message: '${data.description}\n${data.nextStep}',
    icon: data.hasUserAction
        ? Icons.touch_app_rounded
        : Icons.hourglass_empty_rounded,
    tone: data.hasUserAction ? AppStatusTone.info : AppStatusTone.neutral,
  );
}
```

Adicionar imports:

```dart
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
```

- [ ] **Step 3: Atualizar `PedidoTimeline` para visual compacto**

Substituir o desenho com circulos grandes por `AppCard` compacto e `AppStatusPill`.

Use esta estrutura:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final current = _stepIndex();
  final steps = [
    _TimelineStep(l10n.timelineCreated, current >= 0),
    _TimelineStep(l10n.timelineAccepted, current >= 1),
    _TimelineStep(l10n.timelineInProgress, current >= 2),
    _TimelineStep(
      estado == 'cancelado' ? l10n.timelineCancelled : l10n.timelineCompleted,
      current >= 3,
    ),
  ];

  return AppCard(
    variant: AppCardVariant.outlined,
    size: AppCardSize.compact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Progresso do pedido',
          subtitle: 'Acompanha as etapas principais.',
        ),
        const SizedBox(height: AppSpacing.x3),
        LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 520;
            if (mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i += 1)
                    _TimelineStepRow(
                      label: steps[i].label,
                      active: steps[i].active,
                      isLast: i == steps.length - 1,
                    ),
                ],
              );
            }

            return Row(
              children: [
                for (var i = 0; i < steps.length; i += 1) ...[
                  Expanded(
                    child: AppStatusPill(
                      label: steps[i].label,
                      tone: steps[i].active
                          ? AppStatusTone.success
                          : AppStatusTone.neutral,
                      size: AppStatusPillSize.sm,
                      icon: steps[i].active
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                    ),
                  ),
                  if (i < steps.length - 1) const SizedBox(width: AppSpacing.x2),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}
```

Adicionar abaixo da classe:

```dart
class _TimelineStep {
  const _TimelineStep(this.label, this.active);

  final String label;
  final bool active;
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.label,
    required this.active,
    required this.isLast,
  });

  final String label;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.x2),
      child: AppStatusPill(
        label: label,
        tone: active ? AppStatusTone.success : AppStatusTone.neutral,
        size: AppStatusPillSize.sm,
        icon: active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      ),
    );
  }
}
```

Adicionar imports:

```dart
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
```

- [ ] **Step 4: Rodar teste existente de presenter/status**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_status_presenter_test.dart test/features/cliente/widgets/pedido_final_state_panel_test.dart
```

Expected:

```txt
All tests passed.
```

---

### Task 4: Agrupar acoes Cliente e Prestador em `AppActionPanel`

**Files:**
- Modify: `lib/features/cliente/widgets/cliente_pedido_acoes.dart`
- Modify: `lib/features/prestador/widgets/prestador_pedido_acoes.dart`

- [ ] **Step 1: Atualizar `_PropostaPrestadorCard` para `AppActionPanel` preservando keys**

No ficheiro `lib/features/cliente/widgets/cliente_pedido_acoes.dart`, adicionar imports:

```dart
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
```

Substituir o `Container` retornado por `_PropostaPrestadorCard.build` por:

```dart
return AppActionPanel(
  title: copy.title,
  message: [
    copy.body,
    faixaTexto,
    if (expiresTxt.isNotEmpty) expiresTxt,
    if (mensagem != null && mensagem.isNotEmpty) mensagem,
  ].join('\n'),
  icon: Icons.request_quote_rounded,
  tone: AppStatusTone.warning,
  trailing: const Icon(Icons.payments_outlined),
  primaryAction: null,
  secondaryAction: null,
).withActions(
  Row(
    children: [
      Expanded(
        child: OutlinedButton(
          key: const Key('cliente_rejeitar_proposta_button'),
          onPressed: () => _recusarPrestador(context),
          child: Text(copy.secondaryActionLabel!),
        ),
      ),
      const SizedBox(width: AppSpacing.x2),
      Expanded(
        child: ElevatedButton(
          key: const Key('cliente_aceitar_proposta_button'),
          onPressed: () => _aceitarPrestador(context),
          child: Text(copy.primaryActionLabel),
        ),
      ),
    ],
  ),
);
```

Adicionar uma extension privada no fim do ficheiro:

```dart
extension _PedidoActionPanelActions on AppActionPanel {
  Widget withActions(Widget actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        this,
        const SizedBox(height: AppSpacing.x3),
        actions,
      ],
    );
  }
}
```

- [ ] **Step 2: Atualizar `_ValorFinalPendenteCard` para `AppActionPanel` preservando keys**

Substituir o `Container` retornado por `_ValorFinalPendenteCard.build` por:

```dart
final warningText = acimaFaixa
    ? '\nAtencao: este valor esta acima da faixa estimada pelo prestador.'
    : '';

return AppActionPanel(
  title: copy.title,
  message: [
    'Valor final enviado pelo prestador: ${CurrencyUtils.format(valor)}',
    if (faixaTexto != null) faixaTexto,
    if (warningText.isNotEmpty) warningText,
    copy.nextStep!,
  ].join('\n'),
  icon: Icons.price_check_rounded,
  tone: acimaFaixa ? AppStatusTone.warning : AppStatusTone.info,
).withActions(
  Row(
    children: [
      Expanded(
        child: OutlinedButton(
          key: const Key('cliente_duvida_valor_button'),
          onPressed: () => _rejeitarValor(context),
          child: Text(copy.secondaryActionLabel!),
        ),
      ),
      const SizedBox(width: AppSpacing.x2),
      Expanded(
        child: ElevatedButton(
          key: const Key('confirmar_valor_button'),
          onPressed: () => _confirmarValor(context),
          child: Text(copy.primaryActionLabel),
        ),
      ),
    ],
  ),
);
```

- [ ] **Step 3: Atualizar acoes principais do Prestador para `AppActionPanel` sem mexer em services**

No ficheiro `lib/features/prestador/widgets/prestador_pedido_acoes.dart`, adicionar imports:

```dart
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
```

Envolver os retornos principais destes widgets privados com `AppActionPanel`, mantendo os botoes e keys internos:

```txt
_AcaoEnviarOrcamento
_AcaoIniciarServico
_AcaoLancarValorFinal
_AcaoAguardandoConfirmacao
_AcaoConcluido
```

Exemplo para `_AcaoEnviarOrcamento.build`:

```dart
return AppActionPanel(
  title: 'Enviar estimativa',
  message: 'O cliente precisa de uma faixa antes de decidir. A faixa nao e o valor final.',
  icon: Icons.request_quote_rounded,
  tone: AppStatusTone.warning,
).withActions(
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      key: const Key('prestador_enviar_orcamento_button'),
      icon: const Icon(Icons.request_quote_rounded),
      label: const Text('Enviar estimativa ao cliente'),
      onPressed: () => _abrirDialogOrcamento(context),
    ),
  ),
);
```

Se o metodo de dialog tiver outro nome no ficheiro atual, usar o nome existente. Nao alterar a logica interna do dialog nem as keys:

```txt
orcamento_min_field
orcamento_max_field
orcamento_msg_field
orcamento_enviar_button
```

- [ ] **Step 4: Rodar grep para confirmar keys preservadas**

Run:

```powershell
rg -n "cliente_rejeitar_proposta_button|cliente_aceitar_proposta_button|cliente_duvida_valor_button|confirmar_valor_button|prestador_enviar_orcamento_button|prestador_iniciar_servico_button|valor_final_field|prestador_enviar_valor_final_button|prestador_lancar_valor_final_button|orcamento_min_field|orcamento_max_field|orcamento_msg_field|orcamento_enviar_button" lib/features/cliente/widgets/cliente_pedido_acoes.dart lib/features/prestador/widgets/prestador_pedido_acoes.dart
```

Expected:

```txt
todas as keys listadas aparecem pelo menos uma vez
```

---

### Task 5: Integrar layout responsivo no detalhe do pedido

**Files:**
- Modify: `lib/features/cliente/pedido_detalhe_screen.dart`
- Test: `test/features/cliente/widgets/pedido_detail_responsive_test.dart`

- [ ] **Step 1: Adicionar imports da foundation e componentes novos**

Adicionar em `lib/features/cliente/pedido_detalhe_screen.dart`:

```dart
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_detail_components.dart';
```

- [ ] **Step 2: Criar widgets locais para cabecalho e metadados do detalhe**

Adicionar abaixo de `PedidoDetalheScreen` ou perto dos widgets privados existentes:

```dart
class _PedidoDetailHeader extends StatelessWidget {
  const _PedidoDetailHeader({
    required this.pedido,
    required this.categoria,
    required this.subtituloModo,
    required this.estadoLabel,
  });

  final Pedido pedido;
  final String categoria;
  final String subtituloModo;
  final String estadoLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      variant: AppCardVariant.elevated,
      size: AppCardSize.large,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pedido.titulo,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  categoria,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  subtituloModo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          AppStatusPill(label: estadoLabel, tone: AppStatusTone.info),
        ],
      ),
    );
  }
}
```

Adicionar helper para espacamento:

```dart
List<Widget> _spacedPedidoSections(List<Widget> children) {
  final result = <Widget>[];
  for (final child in children) {
    if (child is SizedBox && child.height == 0) continue;
    if (result.isNotEmpty) {
      result.add(const SizedBox(height: AppSpacing.x4));
    }
    result.add(child);
  }
  return result;
}
```

- [ ] **Step 3: Substituir o `SingleChildScrollView` por `AppPageScaffold` + `PedidoDetailLayout`**

Trocar o retorno atual:

```dart
return SingleChildScrollView(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...
    ],
  ),
);
```

por:

```dart
final actionWidgets = <Widget>[
  if (isCliente) ClientePedidoAcoes(pedido: pedido),
  if (!isCliente && AuthService.currentUser?.uid == pedido.prestadorId)
    PrestadorPedidoAcoes(pedido: pedido),
];

return AppPageScaffold(
  title: l10n.orderDetailsTitle,
  subtitle: isCliente ? 'Acompanha o pedido como cliente.' : 'Gere o trabalho como prestador.',
  width: AppContentWidth.wide,
  child: PedidoDetailLayout(
    sidePanel: PedidoDetailSidePanel(
      pedido: pedido,
      summary: statusSummary,
      nextAction: nextAction,
      actions: actionWidgets.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _spacedPedidoSections(actionWidgets),
            ),
    ),
    mainColumn: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spacedPedidoSections([
        _PedidoDetailHeader(
          pedido: pedido,
          categoria: categoria,
          subtituloModo: subtituloModo,
          estadoLabel: estadoLabel,
        ),
        PedidoTimeline(estado: pedido.estado),
        if (pedido.estado == 'concluido' || pedido.estado == 'cancelado')
          PedidoFinalStatePanel(
            data: PedidoFlowPresenter.finalStateFor(pedido),
          ),
        if (aguardandoRespostaPrestador)
          BannerAcaoPrestador(
            icon: Icons.mark_chat_unread,
            texto: 'Convite enviado ao prestador. Aguardando resposta.',
            botao: 'Trocar',
            onPressed: () => _trocarPrestadorManual(context, pedido),
          ),
        if (podeEscolherManual)
          BannerAcaoPrestador(
            icon: Icons.search,
            texto: 'Queres escolher um prestador manualmente?',
            botao: 'Selecionar',
            onPressed: () => _trocarPrestadorManual(context, pedido),
          ),
        if (estaProcurandoPrestador)
          BannerAguardandoPrestador(pedidoId: pedido.id),
        // manter aqui as secoes de descricao, contato, mapa, chat, anexos,
        // no-show, avaliacao e metadados existentes, apenas removendo
        // duplicacao das acoes ja movidas para sidePanel.
      ]),
    ),
  ),
);
```

Ao aplicar, mover para dentro da lista `mainColumn` todos os blocos que ja existem abaixo das acoes hoje:

```txt
AvaliacaoPedidoCard
no-show reportado
reportar no-show
descricao
observacoes/proposta
info rows
contato
mapa
chat
anexos
banners existentes
```

Remover do corpo principal as duplicacoes:

```txt
PedidoStatusSummary
PedidoNextActionCard
ClientePedidoAcoes
PrestadorPedidoAcoes
```

Eles passam para `PedidoDetailSidePanel`.

- [ ] **Step 4: Manter cancelamento/no-show de Prestador fora do actionWidgets se depender de contexto especial**

Se o bloco de cancelamento/no-show do prestador estiver acoplado a metodos privados da tela e ficar mais claro mantelo no main column, criar um widget local:

```dart
Widget _buildPrestadorSecondaryActions(BuildContext context, Pedido pedido) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (pedido.estado != 'aguarda_resposta_prestador')
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
          onPressed: () => _cancelarTrabalhoPorPrestador(context, pedido),
          child: Text(AppLocalizations.of(context)!.cancelJobTitle),
        ),
    ],
  );
}
```

Nao perder comportamento atual. Esta fase pode manter acoes secundarias no main column se isso reduzir risco.

- [ ] **Step 5: Criar teste responsivo simples para `PedidoDetailLayout`**

Criar `test/features/cliente/widgets/pedido_detail_responsive_test.dart`:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_detail_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('PedidoDetailLayout nao cria overflow em mobile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        PedidoDetailLayout(
          mainColumn: const Text('Main content'),
          sidePanel: const Text('Side content'),
        ),
      ),
    );

    expect(find.byKey(const Key('pedido_detail_layout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 6: Rodar analyze do detalhe**

Run:

```powershell
dart analyze lib/features/cliente/pedido_detalhe_screen.dart lib/features/cliente/widgets/pedido_detail_components.dart
```

Expected:

```txt
No issues found!
```

---

### Task 6: Polir `PedidoListCard` para alinhar com as Homes

**Files:**
- Modify: `lib/features/cliente/widgets/pedido_list_card.dart`
- Modify: `test/features/cliente/widgets/pedido_list_card_test.dart`

- [ ] **Step 1: Atualizar teste para status pill e acao resumida**

Adicionar a `test/features/cliente/widgets/pedido_list_card_test.dart`:

```dart
testWidgets('PedidoListCard mostra status e proxima acao com hierarquia visual',
    (tester) async {
  final data = PedidoListCardData(
    title: 'Trocar tomada',
    category: 'Eletricista',
    statusLabel: 'Servico em andamento',
    valueLabel: 'Valor a combinar',
    actionLabel: 'Enviar valor final',
    tone: PedidoStatusTone.info,
    icon: Icons.build_circle_outlined,
    hasUserAction: true,
    bucket: PedidoListBucket.ativo,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PedidoListCard(data: data, onTap: () {}),
      ),
    ),
  );

  expect(find.text('Trocar tomada'), findsOneWidget);
  expect(find.text('Servico em andamento'), findsOneWidget);
  expect(find.text('Enviar valor final'), findsOneWidget);
  expect(find.byIcon(Icons.chevron_right), findsOneWidget);
});
```

- [ ] **Step 2: Atualizar `PedidoListCard` para usar `AppStatusPill`**

Substituir import de `app_chip.dart` por:

```dart
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
```

Substituir o `Wrap` de `AppChip` por:

```dart
Wrap(
  spacing: AppSpacing.x2,
  runSpacing: AppSpacing.x2,
  children: [
    AppStatusPill(
      label: data.statusLabel,
      tone: _statusTone(data.tone),
      size: AppStatusPillSize.sm,
      icon: data.icon,
    ),
    for (final label in metaLabels)
      AppStatusPill(
        label: label,
        tone: AppStatusTone.neutral,
        size: AppStatusPillSize.sm,
      ),
  ],
),
```

Adicionar helper:

```dart
AppStatusTone _statusTone(PedidoStatusTone tone) {
  return switch (tone) {
    PedidoStatusTone.success => AppStatusTone.success,
    PedidoStatusTone.warning => AppStatusTone.warning,
    PedidoStatusTone.danger => AppStatusTone.danger,
    PedidoStatusTone.neutral => AppStatusTone.neutral,
    PedidoStatusTone.info => AppStatusTone.info,
  };
}
```

Manter `_toneColor` para o icone/acao.

- [ ] **Step 3: Melhorar destaque visual de `actionLabel`**

Substituir o bloco final da acao por `AppCard` flat compacto:

```dart
AppCard(
  variant: AppCardVariant.flat,
  size: AppCardSize.compact,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        data.hasUserAction
            ? Icons.priority_high_rounded
            : Icons.info_outline_rounded,
        size: 16,
        color: toneColor,
      ),
      const SizedBox(width: AppSpacing.x2),
      Expanded(
        child: Text(
          data.actionLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: toneColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  ),
),
```

- [ ] **Step 4: Rodar teste do card**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_list_card_test.dart
```

Expected:

```txt
All tests passed.
```

---

### Task 7: Estados finais, loading/erro/not found e docs

**Files:**
- Modify: `lib/features/cliente/pedido_detalhe_screen.dart`
- Modify: `lib/features/cliente/widgets/pedido_final_state_panel.dart`
- Modify: `docs/M2_10_VISUAL_PRODUCT_STATUS.md`

- [ ] **Step 1: Melhorar loading do detalhe**

Em `pedido_detalhe_screen.dart`, substituir:

```dart
return const Center(child: CircularProgressIndicator());
```

por:

```dart
return const AppPageScaffold(
  title: 'Detalhe do pedido',
  width: AppContentWidth.medium,
  child: AppCard(
    child: Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Text('A carregar os detalhes do pedido...'),
        ),
      ],
    ),
  ),
);
```

Se `const AppCard` nao compilar por causa de parametros nao const, remover `const` apenas do `AppPageScaffold`.

- [ ] **Step 2: Melhorar erro e not found com `AppActionPanel`**

Substituir os blocos `snapshot.hasError` e `pedido == null` por paineis:

```dart
return AppPageScaffold(
  title: l10n.orderDetailsTitle,
  width: AppContentWidth.medium,
  child: AppActionPanel(
    title: 'Nao conseguimos carregar este pedido',
    message: 'Tenta voltar a lista e abrir o pedido novamente.',
    icon: Icons.error_outline_rounded,
    tone: AppStatusTone.warning,
    primaryAction: AppActionPanelAction(
      label: 'Voltar',
      icon: Icons.arrow_back_rounded,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
  ),
);
```

Para `pedido == null`, usar:

```dart
return AppPageScaffold(
  title: l10n.orderDetailsTitle,
  width: AppContentWidth.medium,
  child: AppActionPanel(
    title: l10n.orderNotFound,
    message: 'Este pedido pode ter sido removido ou nao estar disponivel para esta conta.',
    icon: Icons.search_off_rounded,
    tone: AppStatusTone.neutral,
    primaryAction: AppActionPanelAction(
      label: 'Voltar',
      icon: Icons.arrow_back_rounded,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
  ),
);
```

Adicionar import:

```dart
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
```

- [ ] **Step 3: Polir `PedidoFinalStatePanel` com `AppActionPanel` ou status pill**

Manter dados existentes, mas tornar visual mais premium:

```dart
return AppActionPanel(
  title: data.title,
  message: [
    data.message,
    if (data.detail != null) data.detail!,
    data.actionHint,
  ].join('\n'),
  icon: data.icon,
  tone: _toneFor(data.color, Theme.of(context)),
);
```

Se mapear por cor for frágil, manter o `AppCard` atual e adicionar apenas `AppStatusPill` no topo:

```dart
AppStatusPill(
  label: data.title,
  tone: data.title.toLowerCase().contains('cancel')
      ? AppStatusTone.danger
      : AppStatusTone.success,
  icon: data.icon,
),
```

Preferir a segunda alternativa se a primeira exigir heuristica demais.

- [ ] **Step 4: Atualizar `docs/M2_10_VISUAL_PRODUCT_STATUS.md`**

Alterar estado:

```txt
M2.10.5: iniciado com Pedido, listas e detalhe polish
```

Adicionar secao:

```markdown
## M2.10.5

Escopo planeado:

```text
detalhe do pedido em duas colunas no desktop
mobile em uma coluna limpa
painel lateral com status, proxima acao, valor e acoes
timeline mais compacta e premium
acoes Cliente/Prestador agrupadas em AppActionPanel
PedidoListCard alinhado a foundation visual
estados finais concluido/cancelado mais claros
loading/erro/not found humanos
keys Cliente/Prestador preservadas
```

Fora do escopo mantido:

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

## Evidencia M2.10.5

Esta secao deve receber, na execucao da implementacao, a tabela real dos
comandos observados no terminal. Nao registar sucesso sem output verificado.
```

Durante a implementacao, substituir a frase final por tabela real apenas depois de rodar os comandos.

---

### Task 8: Validacoes finais e commit

**Files:**
- Verify all modified files.

- [ ] **Step 1: Rodar formatacao nos ficheiros tocados**

Run:

```powershell
dart format lib/features/cliente/pedido_detalhe_screen.dart lib/features/cliente/widgets/pedido_detail_components.dart lib/features/cliente/widgets/pedido_status_summary.dart lib/features/cliente/widgets/pedido_next_action_card.dart lib/features/cliente/widgets/pedido_timeline.dart lib/features/cliente/widgets/pedido_list_card.dart lib/features/cliente/widgets/cliente_pedido_acoes.dart lib/features/prestador/widgets/prestador_pedido_acoes.dart test/features/cliente/widgets/pedido_detail_components_test.dart test/features/cliente/widgets/pedido_detail_responsive_test.dart test/features/cliente/widgets/pedido_list_card_test.dart test/features/cliente/widgets/pedido_final_state_panel_test.dart
```

Expected:

```txt
Formatted ...
```

- [ ] **Step 2: Rodar testes Flutter completos**

Run:

```powershell
flutter test
```

Expected:

```txt
All tests passed.
```

- [ ] **Step 3: Rodar testes de scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```txt
todos os testes de scripts passam
```

- [ ] **Step 4: Rodar Firebase Emulator tests**

Run:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```txt
37/37 passing
```

- [ ] **Step 5: Confirmar que nao houve alteracao fora do escopo**

Run:

```powershell
git status --short
git diff -- firestore.rules storage.rules functions android/key.properties
```

Expected:

```txt
status mostra apenas ficheiros da M2.10.5, os artefactos locais do companion se existirem, e as duas delecoes antigas dos ~$...pptx
diff para rules/functions/key.properties vazio
```

- [ ] **Step 6: Commit**

Stage apenas ficheiros da M2.10.5:

```powershell
git add -- lib/features/cliente/pedido_detalhe_screen.dart lib/features/cliente/widgets/pedido_detail_components.dart lib/features/cliente/widgets/pedido_status_summary.dart lib/features/cliente/widgets/pedido_next_action_card.dart lib/features/cliente/widgets/pedido_timeline.dart lib/features/cliente/widgets/pedido_list_card.dart lib/features/cliente/widgets/cliente_pedido_acoes.dart lib/features/prestador/widgets/prestador_pedido_acoes.dart test/features/cliente/widgets/pedido_detail_components_test.dart test/features/cliente/widgets/pedido_detail_responsive_test.dart test/features/cliente/widgets/pedido_list_card_test.dart test/features/cliente/widgets/pedido_final_state_panel_test.dart docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Nao adicionar:

```txt
.superpowers/**
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
android/key.properties
keystore
```

Commit:

```powershell
git commit -m "Avancar M2.10.5 pedido listas detalhe polish"
```

---

## Self-review do plano

Spec coverage:

```txt
leitura da estrutura atual: Contexto, Estrutura de ficheiros, Task 5
preservacao de keys Cliente/Prestador: Keys e comportamentos, Task 4, Task 8
PedidoDetailLayout responsivo: Task 1, Task 2, Task 5
PedidoDetailSidePanel / rail lateral: Task 1, Task 2, Task 5
PedidoValueSummary: Task 1, Task 2, Task 5
timeline compacta: Task 3
acoes Cliente agrupadas: Task 4
acoes Prestador agrupadas: Task 4
PedidoListCard polish: Task 6
estados finais premium: Task 7
loading/erro/not found humanos: Task 7
testes Flutter: Tasks 1, 3, 5, 6, 8
docs/status M2.10: Task 7
validacoes finais: Task 8
```

Placeholder scan:

```txt
O plano evita marcadores indefinidos e mantem backend, regras, Functions, deploy e dados reais fora do escopo.
```

Type consistency:

```txt
PedidoDetailSidePanel recebe Pedido, PedidoStatusSummaryData e PedidoNextActionData vindos de PedidoStatusPresenter.
PedidoValueSummary usa Pedido e CurrencyUtils, sem chamar services.
PedidoDetailLayout recebe widgets prontos e decide apenas responsividade.
PedidoListCard continua recebendo PedidoListCardData.
ClientePedidoAcoes e PrestadorPedidoAcoes preservam callbacks e keys; apenas a casca visual muda para AppActionPanel.
```
