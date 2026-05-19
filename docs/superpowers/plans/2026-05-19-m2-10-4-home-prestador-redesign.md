# M2.10.4 Home Prestador Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesenhar a Home Prestador como um painel operacional profissional, responsivo e consistente com a foundation visual da M2.10.2, mantendo todos os fluxos existentes.

**Architecture:** A implementacao mantem streams, filtros, callbacks e servicos em `lib/features/prestador/prestador_home_screen.dart`, mas extrai os blocos visuais da aba Inicio para `lib/features/prestador/widgets/prestador_home_components.dart`. Os novos widgets recebem dados ja derivados e callbacks, usam `AppPageScaffold`, `AppContentShell`, `AppResponsiveGrid`, `AppActionPanel`, `AppMetricTile`, `AppStatusPill`, `AppButton` e preservam as keys usadas por testes Android/Windows/E2E.

**Tech Stack:** Flutter/Dart, Material 3, `flutter_test`, Firebase streams existentes, `AppTokens`, design system M2.10.2, `PedidoListCard`, `PedidoListPresenter`, `PedidoStatusPresenter`.

---

## Contexto

Spec aprovada:

```txt
docs/superpowers/specs/2026-05-19-m2-10-4-home-prestador-redesign-design.md
```

Commit da spec:

```txt
b7727ef51c1fda24d8a598659e3a061be8e27abb
Iniciar M2.10.4 home prestador redesign
```

Estado visual anterior:

```txt
M2.10.1: spec visual audit e design direction
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
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
Home Cliente
detalhe/listas inteiras
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
lib/features/prestador/widgets/prestador_home_components.dart
test/features/prestador/widgets/prestador_home_components_test.dart
```

Modificar:

```txt
lib/features/prestador/prestador_home_screen.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Nao modificar:

```txt
lib/features/prestador/widgets/prestador_pedido_acoes.dart
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
prestador_pedido_card_<pedidoId>
prestador_aceitar_pedido_<pedidoId>
prestador_ignorar_pedido_<pedidoId>
prestador_orcamento_dialog_later_button
prestador_orcamento_dialog_now_button
orcamento_min_field
orcamento_max_field
orcamento_msg_field
orcamento_enviar_button
```

Preservar fluxos:

```txt
online/offline atualiza `prestadores/{uid}.isOnline` e lastLocation via LocationService
pedidos disponiveis continuam filtrados por categorias, raio, localizacao e ignorados
Aceitar pedido continua a chamar PedidoService.instance.aceitarPedidoAberto
pedido por orcamento continua a abrir dialog com opcao de enviar agora/mais tarde
Ignorar pedido continua a remover localmente da lista por prestador
mensagens continuam a abrir ChatThreadScreen
trabalho em destaque continua a abrir PedidoDetalheScreen
abas existentes do Prestador continuam no AppShellScaffold
```

Adicionar keys novas para cobertura visual:

```dart
const Key('prestador_home_availability_panel')
const Key('prestador_home_metric_strip')
const Key('prestador_home_next_work_panel')
const Key('prestador_home_categories_panel')
const Key('prestador_home_available_orders_section')
```

---

### Task 1: Testes dos componentes da Home Prestador

**Files:**
- Create: `test/features/prestador/widgets/prestador_home_components_test.dart`
- Create later: `lib/features/prestador/widgets/prestador_home_components.dart`

- [ ] **Step 1: Criar teste falhando para disponibilidade, metricas, categorias e card de pedido**

Criar `test/features/prestador/widgets/prestador_home_components_test.dart`:

```dart
import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

Pedido buildPedido({
  String id = 'pedido_1',
  String estado = 'criado',
  String tipoPreco = 'por_orcamento',
  String tipoPagamento = 'dinheiro',
  String modo = 'IMEDIATO',
  DateTime? agendadoPara,
}) {
  return Pedido(
    id: id,
    clienteId: 'cliente_1',
    prestadorId: null,
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida perto da cozinha',
    modo: modo,
    status: estado,
    tipoPreco: tipoPreco,
    tipoPagamento: tipoPagamento,
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: 'nenhum',
    dataAgendada: agendadoPara,
    createdAt: DateTime(2026, 5, 19),
  );
}

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PrestadorAvailabilityPanel', () {
    testWidgets('mostra estado online e alterna disponibilidade',
        (tester) async {
      bool? toggled;

      await tester.pumpWidget(
        wrap(
          PrestadorAvailabilityPanel(
            online: true,
            onChanged: (value) => toggled = value,
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_home_availability_panel')),
        findsOneWidget,
      );
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Pronto para receber pedidos compativeis.'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      expect(toggled, isFalse);
    });

    testWidgets('mostra estado offline com orientacao de acao',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrestadorAvailabilityPanel(
            online: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Ativa para receber novos pedidos.'), findsOneWidget);
    });
  });

  group('PrestadorMetricStrip', () {
    testWidgets('mostra ganhos e servicos com AppMetricTile',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const PrestadorMetricStrip(
            liquidoHoje: 'EUR 85.00',
            brutoHoje: 'EUR 100.00',
            taxaHoje: 'EUR 15.00',
            servicosMes: '4',
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_home_metric_strip')),
        findsOneWidget,
      );
      expect(find.text('EUR 85.00'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Bruto: EUR 100.00 | Taxa: EUR 15.00'), findsOneWidget);
    });
  });

  group('PrestadorCategoriesPanel', () {
    testWidgets('mostra categorias e chama edicao', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          PrestadorCategoriesPanel(
            categories: const ['Eletricista', 'Canalizador'],
            loading: false,
            onEdit: () => tapped = true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_home_categories_panel')),
        findsOneWidget,
      );
      expect(find.text('2 selecionadas'), findsOneWidget);
      expect(find.text('Eletricista'), findsOneWidget);

      await tester.tap(find.text('Editar categorias'));
      expect(tapped, isTrue);
    });

    testWidgets('orienta configuracao quando nao ha categorias',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrestadorCategoriesPanel(
            categories: const <String>[],
            loading: false,
            onEdit: () {},
          ),
        ),
      );

      expect(find.text('Seleciona categorias para receber pedidos compativeis.'), findsOneWidget);
      expect(find.text('Selecionar categorias'), findsOneWidget);
    });
  });

  group('PrestadorAvailableOrderCard', () {
    testWidgets('preserva keys criticas e chama aceitar/ignorar',
        (tester) async {
      var accepted = false;
      var ignored = false;
      final pedido = buildPedido(id: 'pedido_42');

      await tester.pumpWidget(
        wrap(
          PrestadorAvailableOrderCard(
            pedido: pedido,
            descricao: pedido.descricao,
            agendadoPara: pedido.agendadoPara,
            modo: pedido.modo,
            tipoPrecoLabel: 'Por orcamento',
            tipoPagamentoLabel: 'Pagamento em dinheiro',
            df: DateFormat('dd/MM HH:mm'),
            onAceitar: () => accepted = true,
            onIgnorar: () => ignored = true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_pedido_card_pedido_42')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('prestador_aceitar_pedido_pedido_42')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('prestador_ignorar_pedido_pedido_42')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('prestador_aceitar_pedido_pedido_42')));
      expect(accepted, isTrue);

      await tester.tap(find.byKey(const Key('prestador_ignorar_pedido_pedido_42')));
      expect(ignored, isTrue);
    });

    testWidgets('mantem largura mobile sem overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          PrestadorAvailableOrderCard(
            pedido: buildPedido(id: 'pedido_mobile'),
            descricao: 'Pedido com descricao curta',
            agendadoPara: null,
            modo: 'IMEDIATO',
            tipoPrecoLabel: 'Por orcamento',
            tipoPagamentoLabel: 'Pagamento em dinheiro',
            df: DateFormat('dd/MM HH:mm'),
            onAceitar: () {},
            onIgnorar: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar falha por componente ausente**

Run:

```powershell
flutter test test/features/prestador/widgets/prestador_home_components_test.dart
```

Expected:

```txt
FAIL: Target of URI doesn't exist: package:chegaja_v2/features/prestador/widgets/prestador_home_components.dart
```

---

### Task 2: Componentes visuais da Home Prestador

**Files:**
- Create: `lib/features/prestador/widgets/prestador_home_components.dart`
- Test: `test/features/prestador/widgets/prestador_home_components_test.dart`

- [ ] **Step 1: Criar `prestador_home_components.dart` com componentes visuais puros**

Criar `lib/features/prestador/widgets/prestador_home_components.dart` com estes componentes:

```dart
import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrestadorAvailabilityPanel extends StatelessWidget {
  const PrestadorAvailabilityPanel({
    super.key,
    required this.online,
    required this.onChanged,
  });

  final bool online;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = online ? 'Online' : 'Offline';
    final message = online
        ? 'Pronto para receber pedidos compativeis.'
        : 'Ativa para receber novos pedidos.';
    final tone = online ? AppStatusTone.success : AppStatusTone.neutral;
    final icon = online ? Icons.bolt_rounded : Icons.power_settings_new_rounded;

    return AppCard(
      key: const Key('prestador_home_availability_panel'),
      variant: AppCardVariant.elevated,
      size: AppCardSize.large,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final copy = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (online ? AppPalette.success : theme.colorScheme.onSurfaceVariant)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: online ? AppPalette.success : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppStatusPill(
                      label: title,
                      tone: tone,
                      icon: online ? Icons.radio_button_checked : Icons.radio_button_off,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      online
                          ? 'Estas visivel para clientes perto de ti.'
                          : 'Ficas oculto ate voltares a ficar online.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
            ],
          );

          final control = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                online ? 'Receber pedidos' : 'Ativar',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: AppSpacing.x2),
              Switch(value: online, onChanged: onChanged),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: AppSpacing.x4),
                Align(alignment: Alignment.centerLeft, child: control),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppSpacing.x5),
              control,
            ],
          );
        },
      ),
    );
  }
}

class PrestadorMetricStrip extends StatelessWidget {
  const PrestadorMetricStrip({
    super.key,
    required this.liquidoHoje,
    required this.brutoHoje,
    required this.taxaHoje,
    required this.servicosMes,
  });

  final String liquidoHoje;
  final String brutoHoje;
  final String taxaHoje;
  final String servicosMes;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveGrid(
      key: const Key('prestador_home_metric_strip'),
      minItemWidth: 240,
      spacing: AppSpacing.x3,
      runSpacing: AppSpacing.x3,
      children: [
        AppMetricTile(
          label: 'Ganhos hoje',
          value: liquidoHoje,
          supportingText: 'Bruto: $brutoHoje | Taxa: $taxaHoje',
          icon: Icons.euro_rounded,
          tone: AppStatusTone.success,
        ),
        AppMetricTile(
          label: 'Servicos este mes',
          value: servicosMes,
          supportingText: 'Concluidos e confirmados',
          icon: Icons.work_outline_rounded,
          tone: AppStatusTone.info,
        ),
      ],
    );
  }
}

class PrestadorNextWorkPanel extends StatelessWidget {
  const PrestadorNextWorkPanel({
    super.key,
    required this.pedido,
    required this.actionText,
    required this.onOpen,
  });

  final Pedido pedido;
  final String actionText;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('prestador_home_next_work_panel'),
      title: 'Tens um trabalho para gerir',
      message: '$actionText\n${pedido.titulo}',
      icon: Icons.notifications_active_outlined,
      tone: AppStatusTone.warning,
      primaryAction: AppActionPanelAction(
        label: 'Abrir trabalho',
        icon: Icons.arrow_forward_rounded,
        onPressed: onOpen,
      ),
    );
  }
}

class PrestadorCategoriesPanel extends StatelessWidget {
  const PrestadorCategoriesPanel({
    super.key,
    required this.categories,
    required this.loading,
    required this.onEdit,
  });

  final List<String> categories;
  final bool loading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasCategories = categories.isNotEmpty;

    return AppActionPanel(
      key: const Key('prestador_home_categories_panel'),
      title: 'Categorias de atuacao',
      message: hasCategories
          ? '${categories.length} selecionadas'
          : 'Seleciona categorias para receber pedidos compativeis.',
      icon: Icons.category_outlined,
      tone: hasCategories ? AppStatusTone.info : AppStatusTone.warning,
      primaryAction: AppActionPanelAction(
        label: hasCategories ? 'Editar categorias' : 'Selecionar categorias',
        icon: Icons.tune_rounded,
        variant: hasCategories ? AppButtonVariant.secondary : AppButtonVariant.primary,
        onPressed: loading ? null : onEdit,
      ),
      trailing: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

class PrestadorCategoriesChips extends StatelessWidget {
  const PrestadorCategoriesChips({
    super.key,
    required this.categories,
  });

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final category in categories.take(6))
          AppStatusPill(
            label: category,
            tone: AppStatusTone.neutral,
            size: AppStatusPillSize.sm,
          ),
      ],
    );
  }
}

class PrestadorAvailableOrdersSection extends StatelessWidget {
  const PrestadorAvailableOrdersSection({
    super.key,
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('prestador_home_available_orders_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Pedidos perto de ti',
          subtitle: count == 0
              ? 'Quando houver pedidos compativeis, eles aparecem aqui.'
              : '$count pedido${count == 1 ? '' : 's'} compativel${count == 1 ? '' : 'eis'} para analisar.',
        ),
        child,
      ],
    );
  }
}

class PrestadorAvailableOrderCard extends StatelessWidget {
  const PrestadorAvailableOrderCard({
    super.key,
    required this.pedido,
    required this.descricao,
    required this.agendadoPara,
    required this.modo,
    required this.tipoPrecoLabel,
    required this.tipoPagamentoLabel,
    required this.df,
    required this.onAceitar,
    required this.onIgnorar,
  });

  final Pedido pedido;
  final String? descricao;
  final DateTime? agendadoPara;
  final String modo;
  final String tipoPrecoLabel;
  final String tipoPagamentoLabel;
  final DateFormat df;
  final VoidCallback onAceitar;
  final VoidCallback onIgnorar;

  @override
  Widget build(BuildContext context) {
    final linhaAgendamento =
        modo == 'AGENDADO' && agendadoPara != null
            ? 'Agendado: ${df.format(agendadoPara!)}'
            : 'Servico imediato';
    final desc = (descricao ?? '').trim();
    final listData = PedidoListPresenter.dataFor(
      pedido,
      role: PedidoViewerRole.prestador,
    );

    return PedidoListCard(
      key: Key('prestador_pedido_card_${pedido.id}'),
      data: listData,
      metaLabels: [
        tipoPrecoLabel,
        tipoPagamentoLabel,
        linhaAgendamento,
      ],
      trailingActions: [
        AppButton(
          key: Key('prestador_ignorar_pedido_${pedido.id}'),
          label: 'Ignorar',
          onPressed: onIgnorar,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
        ),
        AppButton(
          key: Key('prestador_aceitar_pedido_${pedido.id}'),
          label: 'Aceitar',
          onPressed: onAceitar,
          leadingIcon: Icons.check_rounded,
          size: AppButtonSize.sm,
        ),
      ],
      footer: desc.isEmpty
          ? null
          : Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
    );
  }
}
```

- [ ] **Step 2: Rodar teste de componentes**

Run:

```powershell
flutter test test/features/prestador/widgets/prestador_home_components_test.dart
```

Expected:

```txt
All tests passed.
```

- [ ] **Step 3: Ajustar apenas compilacao visual se algum nome de API divergir**

Se o compilador apontar erro de API nos widgets core, corrigir para a API real mantendo o comportamento definido:

```txt
AppButton aceita `key`, `label`, `onPressed`, `variant`, `size`, `leadingIcon`
AppActionPanel aceita `key`, `title`, `message`, `icon`, `tone`, `primaryAction`, `trailing`
AppMetricTile aceita `label`, `value`, `supportingText`, `icon`, `tone`
AppResponsiveGrid aceita `key`, `children`, `minItemWidth`, `spacing`, `runSpacing`
```

Nao alterar componentes core nesta task.

---

### Task 3: Integrar foundation no topo da aba Inicio

**Files:**
- Modify: `lib/features/prestador/prestador_home_screen.dart`
- Test: `test/features/prestador/widgets/prestador_home_components_test.dart`

- [ ] **Step 1: Adicionar imports da foundation e dos componentes Prestador**

Em `lib/features/prestador/prestador_home_screen.dart`, adicionar imports:

```dart
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_home_components.dart';
```

Remover imports que ficarem sem uso apenas depois de integrar:

```dart
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
```

Manter import de `app_state_views.dart`, `pedido_empty_state.dart` e servicos existentes.

- [ ] **Step 2: Substituir o `SingleChildScrollView` externo por `AppPageScaffold`**

Na parte final de `_PrestadorInicioTabState.build`, substituir:

```dart
return SingleChildScrollView(
  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.providerHomeGreeting, ...),
      ...
    ],
  ),
);
```

por:

```dart
return AppPageScaffold(
  title: l10n.providerHomeGreeting,
  subtitle: l10n.providerHomeSubtitle,
  width: AppContentWidth.wide,
  child: _PrestadorInicioDashboard(
    online: widget.online,
    onToggleOnline: (value) async {
      widget.onToggleOnline(value);
      final user = AuthService.currentUser;
      if (user != null) {
        await LocationService.instance.updatePrestadorLastLocation(
          prestadorId: user.uid,
          isOnline: value,
        );
      }
    },
    liquidoHojeStr: liquidoHojeStr,
    brutoHojeStr: brutoHojeStr,
    taxaHojeStr: taxaHojeStr,
    servicosMesStr: servicosMesStr,
    trabalhoDestaque: trabalhoDestaque,
    trabalhoDestaqueTexto: trabalhoDestaque == null
        ? null
        : _textoAcaoPendentePrestador(trabalhoDestaque),
    onOpenTrabalhoDestaque: trabalhoDestaque == null
        ? null
        : () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PedidoDetalheScreen(
                  pedidoId: trabalhoDestaque.id,
                  isCliente: false,
                ),
              ),
            );
          },
    mensagens: _PrestadorMensagensBanner(prestadorId: user.uid),
    categorias: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _settingsStream,
      builder: (context, settingsSnap) {
        final data = settingsSnap.data?.data() ?? <String, dynamic>{};
        final servicosNomes = (data['servicosNomes'] as List?)
                ?.whereType<String>()
                .toList() ??
            <String>[];
        final loading = settingsSnap.connectionState ==
                ConnectionState.waiting &&
            data.isEmpty;

        return PrestadorCategoriesPanel(
          categories: servicosNomes,
          loading: loading,
          onEdit: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrestadorSettingsScreen(),
              ),
            );
          },
        );
      },
    ),
    pedidosDisponiveis: _buildPedidosDisponiveisSection(
      context: context,
      l10n: l10n,
      df: df,
    ),
  ),
);
```

- [ ] **Step 3: Criar `_PrestadorInicioDashboard` no mesmo ficheiro**

Adicionar abaixo de `_PrestadorInicioTabState` ou antes de `_PrestadorMensagensBanner`:

```dart
class _PrestadorInicioDashboard extends StatelessWidget {
  const _PrestadorInicioDashboard({
    required this.online,
    required this.onToggleOnline,
    required this.liquidoHojeStr,
    required this.brutoHojeStr,
    required this.taxaHojeStr,
    required this.servicosMesStr,
    required this.trabalhoDestaque,
    required this.trabalhoDestaqueTexto,
    required this.onOpenTrabalhoDestaque,
    required this.mensagens,
    required this.categorias,
    required this.pedidosDisponiveis,
  });

  final bool online;
  final ValueChanged<bool> onToggleOnline;
  final String liquidoHojeStr;
  final String brutoHojeStr;
  final String taxaHojeStr;
  final String servicosMesStr;
  final Pedido? trabalhoDestaque;
  final String? trabalhoDestaqueTexto;
  final VoidCallback? onOpenTrabalhoDestaque;
  final Widget mensagens;
  final Widget categorias;
  final Widget pedidosDisponiveis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrestadorAvailabilityPanel(
          online: online,
          onChanged: onToggleOnline,
        ),
        const SizedBox(height: AppSpacing.x4),
        PrestadorMetricStrip(
          liquidoHoje: liquidoHojeStr,
          brutoHoje: brutoHojeStr,
          taxaHoje: taxaHojeStr,
          servicosMes: servicosMesStr,
        ),
        const SizedBox(height: AppSpacing.x5),
        LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= AppBreakpoints.desktopMin;
            final mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trabalhoDestaque != null &&
                    trabalhoDestaqueTexto != null &&
                    onOpenTrabalhoDestaque != null) ...[
                  PrestadorNextWorkPanel(
                    pedido: trabalhoDestaque!,
                    actionText: trabalhoDestaqueTexto!,
                    onOpen: onOpenTrabalhoDestaque!,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                ],
                pedidosDisponiveis,
              ],
            );

            final sideColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                mensagens,
                const SizedBox(height: AppSpacing.x4),
                categorias,
              ],
            );

            if (!desktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (trabalhoDestaque != null &&
                      trabalhoDestaqueTexto != null &&
                      onOpenTrabalhoDestaque != null) ...[
                    PrestadorNextWorkPanel(
                      pedido: trabalhoDestaque!,
                      actionText: trabalhoDestaqueTexto!,
                      onOpen: onOpenTrabalhoDestaque!,
                    ),
                    const SizedBox(height: AppSpacing.x4),
                  ],
                  mensagens,
                  const SizedBox(height: AppSpacing.x4),
                  categorias,
                  const SizedBox(height: AppSpacing.x5),
                  pedidosDisponiveis,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: mainColumn),
                const SizedBox(width: AppSpacing.x5),
                Expanded(flex: 3, child: sideColumn),
              ],
            );
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Rodar analise incremental**

Run:

```powershell
dart analyze lib/features/prestador/prestador_home_screen.dart lib/features/prestador/widgets/prestador_home_components.dart
```

Expected:

```txt
No issues found!
```

---

### Task 4: Extrair a secao de pedidos disponiveis preservando filtros

**Files:**
- Modify: `lib/features/prestador/prestador_home_screen.dart`
- Modify: `lib/features/prestador/widgets/prestador_home_components.dart`
- Test: `test/features/prestador/widgets/prestador_home_components_test.dart`

- [ ] **Step 1: Criar metodo `_buildPedidosDisponiveisSection` em `_PrestadorInicioTabState`**

Adicionar este metodo na classe `_PrestadorInicioTabState`, abaixo de `_ignorarPedido`:

```dart
Widget _buildPedidosDisponiveisSection({
  required BuildContext context,
  required AppLocalizations l10n,
  required DateFormat df,
}) {
  if (!widget.roleReady) {
    return const AppLoadingView(label: 'A preparar pedidos...');
  }

  return StreamBuilder<List<Pedido>>(
    stream: PedidosRepo.streamPedidosDisponiveis(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const PrestadorAvailableOrdersSection(
          count: 0,
          child: AppLoadingView(label: 'A carregar pedidos compativeis...'),
        );
      }

      if (snapshot.hasError) {
        if (kDebugMode) {
          print('[PrestadorHome] pedidos disponiveis error: ${snapshot.error}');
        }
        return const PrestadorAvailableOrdersSection(
          count: 0,
          child: AppErrorView(
            message: 'Nao conseguimos carregar os pedidos agora. Tenta novamente daqui a pouco.',
          ),
        );
      }

      var pedidos = snapshot.data ?? [];
      pedidos = pedidos.where((p) => !_ignorados.contains(p.id)).toList();

      if (pedidos.isEmpty) {
        _atualizarDisponiveis(const <Pedido>[]);
        return PrestadorAvailableOrdersSection(
          count: 0,
          child: PedidoEmptyState(
            title: l10n.noOrdersAvailableMessage,
            message: l10n.providerHomeSubtitle,
            icon: Icons.search_off_rounded,
          ),
        );
      }

      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _pedidosSettingsStream,
        builder: (context, settingsSnap) {
          final sdata = settingsSnap.data?.data();

          if (settingsSnap.connectionState == ConnectionState.waiting &&
              sdata == null) {
            return const PrestadorAvailableOrdersSection(
              count: 0,
              child: AppLoadingView(label: 'A carregar configuracao...'),
            );
          }

          if (sdata == null) {
            _resetDisponiveis();
            return PrestadorAvailableOrdersSection(
              count: 0,
              child: PedidoEmptyState(
                title: 'Configura a tua area de atuacao',
                message: 'Seleciona categorias para receber pedidos compativeis.',
                icon: Icons.tune,
                actionLabel: 'Configurar',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrestadorSettingsScreen(),
                    ),
                  );
                },
              ),
            );
          }

          final servicos = (sdata['servicos'] as List?)?.whereType<String>().toSet() ?? <String>{};
          final servicosNomes = (sdata['servicosNomes'] as List?)?.whereType<String>().toSet() ?? <String>{};
          final hasCategorias = servicos.isNotEmpty || servicosNomes.isNotEmpty;

          if (!hasCategorias) {
            _resetDisponiveis();
            return PrestadorAvailableOrdersSection(
              count: 0,
              child: PedidoEmptyState(
                title: 'Seleciona categorias',
                message: 'Escolhe os servicos que fazes para receber pedidos.',
                icon: Icons.list_alt,
                actionLabel: 'Selecionar categorias',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrestadorSettingsScreen(),
                    ),
                  );
                },
              ),
            );
          }

          final radiusKm = (sdata['radiusKm'] as num?)?.toDouble() ?? 10.0;
          final lastLoc = sdata['lastLocation'] as Map<String, dynamic>?;
          final lat = (lastLoc?['lat'] as num?)?.toDouble();
          final lng = (lastLoc?['lng'] as num?)?.toDouble();
          final isOnline = (sdata['isOnline'] as bool?) ?? false;

          if (!isOnline) {
            _resetDisponiveis();
            return const PrestadorAvailableOrdersSection(
              count: 0,
              child: PedidoEmptyState(
                title: 'Estas offline',
                message: 'Ativa o modo online para receber pedidos compativeis.',
                icon: Icons.wifi_off_rounded,
              ),
            );
          }

          bool matchesService(Pedido p) {
            if (servicos.contains(p.servicoId)) return true;
            final nome = p.servicoNome ?? p.categoria;
            return nome != null && servicosNomes.contains(nome);
          }

          bool matchesDistance(Pedido p) {
            if (lat == null || lng == null) return true;
            if (p.latitude == null || p.longitude == null) return true;
            final distKm = LocationService.instance.distanceKm(
              lat1: lat,
              lng1: lng,
              lat2: p.latitude!,
              lng2: p.longitude!,
            );
            return distKm <= radiusKm;
          }

          final filtered = pedidos.where((p) => matchesService(p) && matchesDistance(p)).toList();
          _atualizarDisponiveis(filtered);

          if (filtered.isEmpty) {
            return const PrestadorAvailableOrdersSection(
              count: 0,
              child: PedidoEmptyState(
                title: 'Sem pedidos compativeis agora',
                message: 'Ajusta servicos/raio ou atualiza a localizacao.',
                icon: Icons.search_off_rounded,
              ),
            );
          }

          return PrestadorAvailableOrdersSection(
            count: filtered.length,
            child: AppResponsiveGrid(
              minItemWidth: 340,
              spacing: AppSpacing.x3,
              runSpacing: AppSpacing.x3,
              children: [
                for (final pedido in filtered)
                  PrestadorAvailableOrderCard(
                    pedido: pedido,
                    descricao: pedido.descricao,
                    agendadoPara: pedido.agendadoPara,
                    modo: pedido.modo,
                    tipoPrecoLabel: _labelTipoPreco(pedido.tipoPreco),
                    tipoPagamentoLabel: _labelTipoPagamento(pedido.tipoPagamento),
                    df: df,
                    onAceitar: () => _aceitarPedido(context, pedido),
                    onIgnorar: () => _ignorarPedido(pedido),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
```

- [ ] **Step 2: Remover o bloco antigo de `StreamBuilder<List<Pedido>>` da Column**

Depois de `_buildPedidosDisponiveisSection` estar ligado ao dashboard, remover o bloco antigo que comeca em:

```dart
const Text(
  'Pedidos perto de ti',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
),
```

e termina antes de:

```dart
const SizedBox(height: 16),
```

O comportamento de filtros deve ficar identico porque o conteudo foi movido para o metodo.

- [ ] **Step 3: Substituir `_PedidoDisponivelCard` por componente publico**

Remover a classe privada `_PedidoDisponivelCard` se nao houver referencias. O componente equivalente passa a ser:

```dart
PrestadorAvailableOrderCard
```

Os parametros e keys devem permanecer equivalentes:

```txt
pedido
descricao
agendadoPara
modo
tipoPrecoLabel
tipoPagamentoLabel
df
onAceitar
onIgnorar
prestador_pedido_card_<pedidoId>
prestador_aceitar_pedido_<pedidoId>
prestador_ignorar_pedido_<pedidoId>
```

- [ ] **Step 4: Rodar testes de componentes**

Run:

```powershell
flutter test test/features/prestador/widgets/prestador_home_components_test.dart
```

Expected:

```txt
All tests passed.
```

---

### Task 5: Refinar mensagens, categorias e estados humanos

**Files:**
- Modify: `lib/features/prestador/prestador_home_screen.dart`
- Modify: `lib/features/prestador/widgets/prestador_home_components.dart`

- [ ] **Step 1: Reaproveitar `_PrestadorMensagensBanner` sem alterar stream**

Manter `_PrestadorMensagensBanner` com o stream atual de mensagens. Apenas garantir que no novo dashboard ele fica na coluna lateral em desktop e acima de categorias em mobile:

```dart
final sideColumn = Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    mensagens,
    const SizedBox(height: AppSpacing.x4),
    categorias,
  ],
);
```

Nao alterar:

```txt
ChatService.instance.ensureChatMetaForPedido
ChatThreadScreen
stream de pedidos do prestador
stream de chats
```

- [ ] **Step 2: Melhorar copy de loading e erros sem mexer em backend**

Usar estas mensagens na Home Prestador:

```txt
A preparar pedidos...
A carregar pedidos compativeis...
A carregar configuracao...
Nao conseguimos carregar os pedidos agora. Tenta novamente daqui a pouco.
Configura a tua area de atuacao
Seleciona categorias para receber pedidos compativeis.
Estas offline
Ativa o modo online para receber pedidos compativeis.
Sem pedidos compativeis agora
Ajusta servicos/raio ou atualiza a localizacao.
```

Nao mostrar excecao bruta ao utilizador. Em `kDebugMode`, manter o `print` existente para diagnostico local.

- [ ] **Step 3: Confirmar que a disponibilidade nao duplicou logica de tracking**

O callback do `Switch` deve continuar a fazer exatamente:

```dart
widget.onToggleOnline(value);
final user = AuthService.currentUser;
if (user != null) {
  await LocationService.instance.updatePrestadorLastLocation(
    prestadorId: user.uid,
    isOnline: value,
  );
}
```

Nao chamar `LocationService` dentro de `PrestadorAvailabilityPanel`; o widget visual so recebe `online` e `onChanged`.

---

### Task 6: Teste de integracao visual leve da Home Prestador

**Files:**
- Create: `test/features/prestador/prestador_home_redesign_test.dart`
- Modify if needed: `lib/features/prestador/prestador_home_screen.dart`

- [ ] **Step 1: Criar teste leve para dashboard sem depender de Firebase real**

Criar `test/features/prestador/prestador_home_redesign_test.dart` com foco nos widgets puros do dashboard. Como `_PrestadorInicioDashboard` e privado, testar o conjunto usando os componentes publicos:

```dart
import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido buildPedido() {
  return Pedido(
    id: 'pedido_dashboard',
    clienteId: 'cliente_1',
    prestadorId: 'prestador_1',
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Montar candeeiro',
    descricao: 'Instalar candeeiro na sala',
    modo: 'IMEDIATO',
    status: 'aceito',
    tipoPreco: 'a_combinar',
    tipoPagamento: 'dinheiro',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: 'nenhum',
    createdAt: DateTime(2026, 5, 19),
  );
}

void main() {
  testWidgets('blocos principais da Home Prestador renderizam em mobile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              PrestadorAvailabilityPanel(
                online: true,
                onChanged: (_) {},
              ),
              const PrestadorMetricStrip(
                liquidoHoje: 'EUR 0.00',
                brutoHoje: 'EUR 0.00',
                taxaHoje: 'EUR 0.00',
                servicosMes: '0',
              ),
              PrestadorNextWorkPanel(
                pedido: buildPedido(),
                actionText: 'Tens um trabalho aceite, pronto para iniciar.',
                onOpen: () {},
              ),
              PrestadorCategoriesPanel(
                categories: const ['Eletricista'],
                loading: false,
                onEdit: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('prestador_home_availability_panel')), findsOneWidget);
    expect(find.byKey(const Key('prestador_home_metric_strip')), findsOneWidget);
    expect(find.byKey(const Key('prestador_home_next_work_panel')), findsOneWidget);
    expect(find.byKey(const Key('prestador_home_categories_panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Rodar testes Prestador**

Run:

```powershell
flutter test test/features/prestador/widgets/prestador_home_components_test.dart test/features/prestador/prestador_home_redesign_test.dart
```

Expected:

```txt
All tests passed.
```

---

### Task 7: Atualizar status M2.10

**Files:**
- Modify: `docs/M2_10_VISUAL_PRODUCT_STATUS.md`

- [ ] **Step 1: Atualizar estado**

Alterar o bloco de estado para:

```txt
M2.9: fechado
M2.10: iniciado
M2.10.1: spec visual audit e design direction
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
M2.10.4: avancado com Home Prestador redesign
```

- [ ] **Step 2: Adicionar secao M2.10.4**

Adicionar ao final:

```markdown
## M2.10.4

Escopo:

```text
Home Prestador recomposta como painel operacional
disponibilidade online/offline como comando principal
metricas com AppMetricTile
trabalho em destaque com AppActionPanel
categorias como painel operacional
pedidos disponiveis em cards responsivos
desktop/Web/Windows com composicao em coluna principal e lateral
mobile preservado em uma coluna direta
keys Aceitar/Ignorar/orcamento preservadas
```

Componentes criados:

```text
PrestadorAvailabilityPanel
PrestadorMetricStrip
PrestadorNextWorkPanel
PrestadorCategoriesPanel
PrestadorCategoriesChips
PrestadorAvailableOrdersSection
PrestadorAvailableOrderCard
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

## Evidencia M2.10.4

Depois de concluir a Task 8, adicionar a tabela com os resultados reais dos
comandos executados. A tabela deve conter apenas resultados observados no
terminal da execucao, por exemplo `passou, 90/90`, `passou`, ou o bloqueio
ambiental concreto se algum comando nao puder ser executado.
```

---

### Task 8: Validacoes finais e commit

**Files:**
- Verify all modified files.

- [ ] **Step 1: Rodar formatacao nos ficheiros tocados**

Run:

```powershell
dart format lib/features/prestador/prestador_home_screen.dart lib/features/prestador/widgets/prestador_home_components.dart test/features/prestador/widgets/prestador_home_components_test.dart test/features/prestador/prestador_home_redesign_test.dart
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
status mostra apenas ficheiros da M2.10.4 e as duas delecoes antigas dos ~$...pptx
diff para rules/functions/key.properties vazio
```

- [ ] **Step 6: Commit**

Stage apenas ficheiros da M2.10.4:

```powershell
git add -- lib/features/prestador/prestador_home_screen.dart lib/features/prestador/widgets/prestador_home_components.dart test/features/prestador/widgets/prestador_home_components_test.dart test/features/prestador/prestador_home_redesign_test.dart docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Nao adicionar:

```txt
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
android/key.properties
keystore
```

Commit:

```powershell
git commit -m "Avancar M2.10.4 home prestador redesign"
```

---

## Self-review do plano

Spec coverage:

```txt
online/offline como comando principal: Task 2, Task 3
metricas simples: Task 2, Task 3
trabalho em destaque: Task 2, Task 3
categorias: Task 2, Task 3, Task 5
pedidos disponiveis com acoes fortes: Task 2, Task 4
desktop dashboard: Task 3
mobile uma coluna: Task 3, Task 6
loading/empty/error humanos: Task 4, Task 5
keys criticas preservadas: Task 1, Task 2, Task 4
docs/status: Task 7
validacoes finais: Task 8
```

Placeholder scan:

```txt
O plano nao usa marcadores indefinidos nem deixa decisoes abertas para backend, regras, Functions ou deploy.
```

Type consistency:

```txt
PrestadorAvailableOrderCard usa Pedido, DateFormat, VoidCallback e as mesmas labels ja derivadas em prestador_home_screen.dart.
PrestadorAvailabilityPanel recebe apenas estado visual e callback; LocationService fica no estado existente.
PrestadorCategoriesPanel recebe lista ja derivada do snapshot; nao consulta Firestore.
```
