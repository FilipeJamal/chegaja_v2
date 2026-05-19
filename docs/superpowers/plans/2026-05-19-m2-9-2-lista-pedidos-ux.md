# M2.9.2 Lista Pedidos UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Melhorar as listas e cards de pedidos para Cliente e Prestador com estado claro, proxima acao resumida, empty states melhores e erros mais humanos.

**Architecture:** Reutilizar a camada pura criada na M2.9.1 (`PedidoStatusPresenter`) e adicionar um presenter pequeno para cards de lista. Criar widgets focados (`PedidoListCard` e `PedidoEmptyState`) para evitar aumentar ainda mais `cliente_home_screen.dart` e `prestador_home_screen.dart`. Integrar os widgets mantendo streams, navegacao, keys e acoes atuais.

**Tech Stack:** Flutter/Dart, Material widgets, `flutter_test`, modelo `Pedido`, `PedidoStatusPresenter`, componentes locais `AppCard`, `AppChip`, `AppSpacing`, `AppPalette`, `AppLoadingView` e `AppErrorView`.

---

## File Structure

**Criar:**

- `lib/features/cliente/widgets/pedido_list_presenter.dart`
  - Helper puro para converter `Pedido + role` em dados compactos para card.
- `lib/features/cliente/widgets/pedido_list_card.dart`
  - Card visual reutilizavel para pedidos em listas.
- `lib/features/cliente/widgets/pedido_empty_state.dart`
  - Empty state especifico para listas de pedidos.
- `test/features/cliente/widgets/pedido_list_presenter_test.dart`
  - Testes unitarios do presenter de lista.
- `test/features/cliente/widgets/pedido_list_card_test.dart`
  - Testes de widget para card e empty state.

**Modificar:**

- `lib/features/cliente/cliente_home_screen.dart`
  - Integrar card/empty state na aba de pedidos do Cliente e humanizar erro/loading.
- `lib/features/prestador/prestador_home_screen.dart`
  - Integrar card/empty state nas listas do Prestador e preservar keys/acoes.
- `docs/M2_9_BETA_WEB_STATUS.md`
  - Registar M2.9.2 avancada e evidencias de validacao quando a implementacao passar.

**Nao modificar:**

- `functions/`
- `firestore.rules`
- `storage.rules`
- `firebase.json`
- `android/key.properties`
- keystore
- ficheiros `~$...pptx`

---

### Task 1: Presenter puro para cards de lista

**Files:**
- Create: `lib/features/cliente/widgets/pedido_list_presenter.dart`
- Test: `test/features/cliente/widgets/pedido_list_presenter_test.dart`

- [ ] **Step 1: Criar teste falhando para presenter de lista**

Criar `test/features/cliente/widgets/pedido_list_presenter_test.dart` com:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

Pedido buildPedido({
  String estado = 'criado',
  String? prestadorId,
  String tipoPreco = 'a_combinar',
  String tipoPagamento = 'dinheiro',
  String statusProposta = 'nenhuma',
  String statusConfirmacaoValor = 'nenhum',
  double? precoPropostoPrestador,
  double? precoFinal,
  double? valorMinEstimadoPrestador,
  double? valorMaxEstimadoPrestador,
  String? canceladoPor,
  String? servicoNome,
  String modo = 'IMEDIATO',
  DateTime? agendadoPara,
}) {
  return Pedido(
    id: 'pedido_1',
    clienteId: 'cliente_1',
    prestadorId: prestadorId,
    servicoId: 'srv_eletricista',
    servicoNome: servicoNome ?? 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida',
    modo: modo,
    status: estado,
    tipoPreco: tipoPreco,
    tipoPagamento: tipoPagamento,
    statusProposta: statusProposta,
    statusConfirmacaoValor: statusConfirmacaoValor,
    precoPropostoPrestador: precoPropostoPrestador,
    precoFinal: precoFinal,
    valorMinEstimadoPrestador: valorMinEstimadoPrestador,
    valorMaxEstimadoPrestador: valorMaxEstimadoPrestador,
    canceladoPor: canceladoPor,
    dataAgendada: agendadoPara,
    createdAt: DateTime(2026, 5, 19),
  );
}

void main() {
  group('PedidoListPresenter', () {
    test('cliente com valor final pendente mostra acao curta', () {
      final pedido = buildPedido(
        estado: 'aguarda_confirmacao_valor',
        prestadorId: 'prestador_1',
        statusConfirmacaoValor: 'pendente_cliente',
        precoPropostoPrestador: 120,
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.title, 'Trocar tomada');
      expect(data.category, 'Eletricista');
      expect(data.statusLabel, 'Confirma o valor final');
      expect(data.actionLabel, 'Confirmar valor final');
      expect(data.hasUserAction, isTrue);
      expect(data.bucket, PedidoListBucket.ativo);
      expect(data.valueLabel, contains('Valor a confirmar'));
    });

    test('prestador com convite pendente mostra aceitar ou recusar', () {
      final pedido = buildPedido(
        estado: 'aguarda_resposta_prestador',
        prestadorId: 'prestador_1',
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.prestador,
      );

      expect(data.statusLabel, 'Convite recebido');
      expect(data.actionLabel, 'Aceitar ou recusar convite');
      expect(data.hasUserAction, isTrue);
      expect(data.bucket, PedidoListBucket.ativo);
    });

    test('pedido concluido nao mostra urgencia', () {
      final pedido = buildPedido(
        estado: 'concluido',
        prestadorId: 'prestador_1',
        statusConfirmacaoValor: 'confirmado_cliente',
        precoFinal: 80,
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.statusLabel, 'Pedido concluido');
      expect(data.actionLabel, 'Sem acao pendente');
      expect(data.hasUserAction, isFalse);
      expect(data.bucket, PedidoListBucket.concluido);
      expect(data.valueLabel, contains('Valor final'));
    });

    test('pedido cancelado mostra estado final', () {
      final pedido = buildPedido(
        estado: 'cancelado',
        canceladoPor: 'prestador',
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.statusLabel, 'Pedido cancelado');
      expect(data.actionLabel, 'Pedido cancelado');
      expect(data.hasUserAction, isFalse);
      expect(data.bucket, PedidoListBucket.cancelado);
    });

    test('faixa estimada e apresentada sem virar valor final', () {
      final pedido = buildPedido(
        estado: 'aguarda_resposta_cliente',
        statusProposta: 'pendente_cliente',
        tipoPreco: 'por_orcamento',
        valorMinEstimadoPrestador: 40,
        valorMaxEstimadoPrestador: 70,
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.valueLabel, contains('Faixa estimada'));
      expect(data.valueLabel, isNot(contains('Valor final')));
    });
  });
}
```

- [ ] **Step 2: Rodar teste e confirmar falha por ficheiro inexistente**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_list_presenter_test.dart
```

Expected:

```text
Error: Error when reading ... pedido_list_presenter.dart
```

- [ ] **Step 3: Implementar presenter minimo**

Criar `lib/features/cliente/widgets/pedido_list_presenter.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/utils/currency_utils.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

enum PedidoListBucket { ativo, concluido, cancelado }

class PedidoListCardData {
  final String title;
  final String category;
  final String statusLabel;
  final String valueLabel;
  final String actionLabel;
  final PedidoStatusTone tone;
  final IconData icon;
  final bool hasUserAction;
  final PedidoListBucket bucket;

  const PedidoListCardData({
    required this.title,
    required this.category,
    required this.statusLabel,
    required this.valueLabel,
    required this.actionLabel,
    required this.tone,
    required this.icon,
    required this.hasUserAction,
    required this.bucket,
  });
}

class PedidoListPresenter {
  const PedidoListPresenter._();

  static PedidoListCardData dataFor(
    Pedido pedido, {
    required PedidoViewerRole role,
    String? localeName,
  }) {
    final summary = PedidoStatusPresenter.summaryFor(pedido, role: role);
    final nextAction = PedidoStatusPresenter.nextActionFor(pedido, role: role);

    return PedidoListCardData(
      title: _titleFor(pedido),
      category: _categoryFor(pedido),
      statusLabel: summary.title,
      valueLabel: _valueLabelFor(pedido, localeName: localeName),
      actionLabel: _shortActionFor(pedido, role: role),
      tone: summary.tone,
      icon: summary.icon,
      hasUserAction: nextAction.hasUserAction,
      bucket: bucketFor(pedido),
    );
  }

  static PedidoListBucket bucketFor(Pedido pedido) {
    if (pedido.estado == 'cancelado') return PedidoListBucket.cancelado;
    if (pedido.estado == 'concluido') return PedidoListBucket.concluido;
    return PedidoListBucket.ativo;
  }

  static String _titleFor(Pedido pedido) {
    final title = pedido.titulo.trim();
    return title.isEmpty ? 'Pedido sem titulo' : title;
  }

  static String _categoryFor(Pedido pedido) {
    final category = (pedido.categoria ?? pedido.servicoNome ?? '').trim();
    return category.isEmpty ? 'Categoria nao definida' : category;
  }

  static String _valueLabelFor(Pedido pedido, {String? localeName}) {
    String format(double value) => CurrencyUtils.format(
          value,
          localeName: localeName,
        );

    if (pedido.precoFinal != null &&
        pedido.statusConfirmacaoValor == 'confirmado_cliente') {
      return 'Valor final: ${format(pedido.precoFinal!)}';
    }

    if (pedido.precoPropostoPrestador != null &&
        pedido.statusConfirmacaoValor == 'pendente_cliente') {
      return 'Valor a confirmar: ${format(pedido.precoPropostoPrestador!)}';
    }

    if (pedido.precoFinal != null) {
      return 'Valor final: ${format(pedido.precoFinal!)}';
    }

    if (pedido.precoPropostoPrestador != null) {
      return 'Valor proposto: ${format(pedido.precoPropostoPrestador!)}';
    }

    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;
    if (min != null && max != null) {
      return 'Faixa estimada: ${format(min)} a ${format(max)}';
    }
    if (min != null) return 'Faixa estimada: desde ${format(min)}';
    if (max != null) return 'Faixa estimada: ate ${format(max)}';

    return 'Valor a combinar';
  }

  static String _shortActionFor(
    Pedido pedido, {
    required PedidoViewerRole role,
  }) {
    if (pedido.estado == 'cancelado') return 'Pedido cancelado';
    if (pedido.estado == 'concluido') return 'Sem acao pendente';

    if (pedido.statusConfirmacaoValor == 'pendente_cliente' ||
        pedido.estado == 'aguarda_confirmacao_valor') {
      return role == PedidoViewerRole.cliente
          ? 'Confirmar valor final'
          : 'Aguardar confirmacao do cliente';
    }

    if (role == PedidoViewerRole.prestador &&
        pedido.estado == 'aguarda_resposta_prestador') {
      return 'Aceitar ou recusar convite';
    }

    if (pedido.estado == 'aguarda_resposta_cliente' ||
        pedido.statusProposta == 'pendente_cliente') {
      return role == PedidoViewerRole.cliente
          ? 'Rever estimativa'
          : 'Aguardar resposta do cliente';
    }

    if (role == PedidoViewerRole.prestador &&
        pedido.estado == 'em_andamento') {
      return 'Enviar valor final';
    }

    if (pedido.estado == 'aceito') {
      return role == PedidoViewerRole.prestador
          ? 'Iniciar servico'
          : 'Combinar detalhes';
    }

    if (pedido.estado == 'criado') {
      return role == PedidoViewerRole.cliente
          ? 'Aguardar prestador'
          : 'Pedido disponivel';
    }

    return 'Abrir detalhe';
  }
}
```

- [ ] **Step 4: Rodar teste especifico e confirmar passagem**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_list_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Commit de checkpoint**

```powershell
git add lib/features/cliente/widgets/pedido_list_presenter.dart `
  test/features/cliente/widgets/pedido_list_presenter_test.dart
git commit -m "Adicionar presenter de lista de pedidos"
```

---

### Task 2: Card reutilizavel de pedido

**Files:**
- Create: `lib/features/cliente/widgets/pedido_list_card.dart`
- Test: `test/features/cliente/widgets/pedido_list_card_test.dart`

- [ ] **Step 1: Criar teste falhando para o card**

Criar `test/features/cliente/widgets/pedido_list_card_test.dart` com:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

void main() {
  group('PedidoListCard', () {
    testWidgets('mostra estado, valor e proxima acao', (tester) async {
      var tapped = false;
      const data = PedidoListCardData(
        title: 'Trocar tomada',
        category: 'Eletricista',
        statusLabel: 'Confirma o valor final',
        valueLabel: 'Valor a confirmar: 120,00 EUR',
        actionLabel: 'Confirmar valor final',
        tone: PedidoStatusTone.warning,
        icon: Icons.price_check_rounded,
        hasUserAction: true,
        bucket: PedidoListBucket.ativo,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PedidoListCard(
              data: data,
              metaLabels: const ['Por orcamento', 'Dinheiro'],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Trocar tomada'), findsOneWidget);
      expect(find.text('Eletricista'), findsOneWidget);
      expect(find.text('Confirma o valor final'), findsOneWidget);
      expect(find.text('Valor a confirmar: 120,00 EUR'), findsOneWidget);
      expect(find.text('Confirmar valor final'), findsOneWidget);
      expect(find.text('Por orcamento'), findsOneWidget);

      await tester.tap(find.byType(PedidoListCard));
      expect(tapped, isTrue);
    });

    testWidgets('mostra empty state humano', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedidoEmptyState(
              title: 'Sem pedidos ativos',
              message: 'Quando criares um pedido, ele aparece aqui.',
              icon: Icons.inbox_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Sem pedidos ativos'), findsOneWidget);
      expect(
        find.text('Quando criares um pedido, ele aparece aqui.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Rodar teste e confirmar falha por widgets inexistentes**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_list_card_test.dart
```

Expected:

```text
Error: Error when reading ... pedido_list_card.dart
```

- [ ] **Step 3: Criar `PedidoListCard`**

Criar `lib/features/cliente/widgets/pedido_list_card.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_chip.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoListCard extends StatelessWidget {
  final PedidoListCardData data;
  final VoidCallback onTap;
  final List<String> metaLabels;
  final List<Widget> trailingActions;
  final Widget? footer;

  const PedidoListCard({
    super.key,
    required this.data,
    required this.onTap,
    this.metaLabels = const [],
    this.trailingActions = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toneColor = _toneColor(theme, data.tone);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: toneColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(data.icon, color: toneColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      data.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              AppChip(
                label: data.statusLabel,
                variant: AppChipVariant.status,
                size: AppChipSize.sm,
                leading: Icon(data.icon),
              ),
              for (final label in metaLabels)
                AppChip(
                  label: label,
                  variant: AppChipVariant.choice,
                  size: AppChipSize.sm,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            data.valueLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                data.hasUserAction
                    ? Icons.priority_high_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: toneColor,
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Text(
                  data.actionLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: toneColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (trailingActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              alignment: WrapAlignment.end,
              children: trailingActions,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.x3),
            footer!,
          ],
        ],
      ),
    );
  }

  Color _toneColor(ThemeData theme, PedidoStatusTone tone) {
    return switch (tone) {
      PedidoStatusTone.success => AppPalette.success,
      PedidoStatusTone.warning => AppPalette.warning,
      PedidoStatusTone.danger => theme.colorScheme.error,
      PedidoStatusTone.neutral => theme.colorScheme.onSurfaceVariant,
      PedidoStatusTone.info => theme.colorScheme.primary,
    };
  }
}
```

- [ ] **Step 4: Criar `PedidoEmptyState`**

Criar `lib/features/cliente/widgets/pedido_empty_state.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';

class PedidoEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PedidoEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.x4),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Rodar teste do card e confirmar passagem**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_list_card_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 6: Commit de checkpoint**

```powershell
git add lib/features/cliente/widgets/pedido_list_card.dart `
  lib/features/cliente/widgets/pedido_empty_state.dart `
  test/features/cliente/widgets/pedido_list_card_test.dart
git commit -m "Adicionar card e empty state de pedidos"
```

---

### Task 3: Integracao na lista do Cliente

**Files:**
- Modify: `lib/features/cliente/cliente_home_screen.dart`
- Test: `test/features/cliente/widgets/pedido_list_presenter_test.dart`
- Test: `test/features/cliente/widgets/pedido_list_card_test.dart`

- [ ] **Step 1: Adicionar imports do card, empty state e presenter**

Em `lib/features/cliente/cliente_home_screen.dart`, adicionar:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
```

- [ ] **Step 2: Atualizar `_ListaPedidosCliente` para empty state estruturado**

Substituir a classe `_ListaPedidosCliente` por:

```dart
class _ListaPedidosCliente extends StatelessWidget {
  final List<Pedido> pedidos;
  final String emptyTitle;
  final String emptyMessage;

  const _ListaPedidosCliente({
    required this.pedidos,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return PedidoEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.separated(
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return _PedidoClienteCard(pedido: pedido);
      },
    );
  }
}
```

- [ ] **Step 3: Atualizar chamadas da lista do Cliente**

No `TabBarView` de `_ClientePedidosTab`, trocar:

```dart
_ListaPedidosCliente(
  pedidos: pendentes,
  mensagemVazio: l10n.ordersEmptyPending,
),
```

por:

```dart
_ListaPedidosCliente(
  pedidos: pendentes,
  emptyTitle: 'Sem pedidos ativos',
  emptyMessage:
      'Quando criares um pedido, ele aparece aqui ate ser concluido ou cancelado.',
),
```

Trocar a lista de concluidos por:

```dart
_ListaPedidosCliente(
  pedidos: concluidos,
  emptyTitle: 'Sem pedidos concluidos',
  emptyMessage: 'Os pedidos concluidos ficam guardados aqui para consulta.',
),
```

Trocar a lista de cancelados por:

```dart
_ListaPedidosCliente(
  pedidos: cancelados,
  emptyTitle: 'Sem pedidos cancelados',
  emptyMessage: 'Pedidos cancelados aparecem aqui quando existirem.',
),
```

- [ ] **Step 4: Atualizar `_PedidoClienteCard` para usar `PedidoListCard`**

Substituir o `return AppCard(...)` dentro de `_PedidoClienteCard.build` por:

```dart
    final listData = PedidoListPresenter.dataFor(
      pedido,
      role: PedidoViewerRole.cliente,
      localeName: l10n.localeName,
    );

    return PedidoListCard(
      data: listData,
      metaLabels: [
        tipoPrecoLabel,
        tipoPagamentoLabel,
      ],
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
          ),
        );
      },
      footer: PedidoChatPreview(
        pedidoId: pedido.id,
        viewerRole: 'cliente',
      ),
    );
```

Depois remover do metodo as variaveis que deixarem de ser usadas:

```dart
theme
subtitulo
estadoLabel
valorLabel
acaoPendente
textoAcao
```

Manter:

```dart
tipoPrecoLabel
tipoPagamentoLabel
```

- [ ] **Step 5: Humanizar loading e erro do Cliente**

No `StreamBuilder` de `_ClientePedidosTab`, trocar loading:

```dart
return const Center(child: CircularProgressIndicator());
```

por:

```dart
return const AppLoadingView(label: 'A carregar pedidos...');
```

Trocar erro:

```dart
return Center(
  child: Text(
    l10n.ordersLoadError(
      snapshot.error.toString(),
    ),
    textAlign: TextAlign.center,
  ),
);
```

por:

```dart
if (kDebugMode) {
  // ignore: avoid_print
  print('[ClientePedidosTab] stream error: ${snapshot.error}');
}
return const AppErrorView(
  message: 'Nao conseguimos carregar os pedidos agora. Tenta novamente daqui a pouco.',
  retryLabel: 'Tentar novamente',
);
```

- [ ] **Step 6: Rodar testes Flutter focados**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_list_presenter_test.dart `
  test/features/cliente/widgets/pedido_list_card_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 7: Rodar suite Flutter**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 8: Commit de checkpoint**

```powershell
git add lib/features/cliente/cliente_home_screen.dart
git commit -m "Melhorar lista de pedidos do cliente"
```

---

### Task 4: Integracao nas listas do Prestador preservando keys e acoes

**Files:**
- Modify: `lib/features/prestador/prestador_home_screen.dart`
- Test: `test/features/cliente/widgets/pedido_list_presenter_test.dart`
- Test: `test/features/cliente/widgets/pedido_list_card_test.dart`

- [ ] **Step 1: Adicionar imports no home do Prestador**

Em `lib/features/prestador/prestador_home_screen.dart`, adicionar:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
```

- [ ] **Step 2: Atualizar `_PrestadorListaPedidos` para empty state estruturado**

Substituir o bloco:

```dart
if (pedidos.isEmpty) {
  return Center(
    child: Text(
      mensagemVazio,
      textAlign: TextAlign.center,
    ),
  );
}
```

por:

```dart
if (pedidos.isEmpty) {
  return PedidoEmptyState(
    title: mensagemVazio.split('\n').first,
    message: mensagemVazio.contains('\n')
        ? mensagemVazio.split('\n').skip(1).join('\n')
        : 'Quando houver trabalhos nesta categoria, eles aparecem aqui.',
    icon: Icons.work_outline,
  );
}
```

- [ ] **Step 3: Atualizar `_PrestadorPedidoCard` para usar `PedidoListCard`**

Dentro de `_PrestadorPedidoCard.build`, manter o calculo de:

```dart
tipoPrecoLabel
tipoPagamentoLabel
valorClienteLabel
valorPrestadorLabel
mostrarCancelar
```

Depois substituir a criacao de `card = Container(...)` por:

```dart
    final listData = PedidoListPresenter.dataFor(
      pedido,
      role: PedidoViewerRole.prestador,
    );

    final valueFooter = <Widget>[
      if (valorClienteLabel != null)
        Text(
          valorClienteLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      if (valorPrestadorLabel != null)
        Text(
          valorPrestadorLabel,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
    ];

    final card = PedidoListCard(
      data: listData,
      metaLabels: [
        tipoPrecoLabel,
        tipoPagamentoLabel,
      ],
      onTap: () => _abrirDetalhe(context),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (temDescricao) ...[
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 8),
          ],
          ...valueFooter,
          if (valueFooter.isNotEmpty) const SizedBox(height: 8),
          PedidoChatPreview(
            pedidoId: pedido.id,
            viewerRole: 'prestador',
          ),
          const SizedBox(height: 8),
          PrestadorPedidoAcoes(pedido: pedido),
          if (mostrarCancelar) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelarTrabalho(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                child: const Text('Cancelar trabalho'),
              ),
            ),
          ],
        ],
      ),
    );
```

Manter o `return InkWell(...)` se continuar necessario, ou substituir por:

```dart
return card;
```

Como `PedidoListCard` ja recebe `onTap`, o retorno preferido e:

```dart
return card;
```

- [ ] **Step 4: Atualizar `_PedidoDisponivelCard` preservando keys**

No `_PedidoDisponivelCard.build`, criar dados:

```dart
    final listData = PedidoListPresenter.dataFor(
      pedido,
      role: PedidoViewerRole.prestador,
    );
```

Substituir o `Container` principal por `PedidoListCard`, preservando estas keys:

```dart
Key('prestador_pedido_card_${pedido.id}')
Key('prestador_ignorar_pedido_${pedido.id}')
Key('prestador_aceitar_pedido_${pedido.id}')
```

O retorno deve ficar assim:

```dart
    return PedidoListCard(
      key: Key('prestador_pedido_card_${pedido.id}'),
      data: listData,
      metaLabels: [
        tipoPrecoLabel,
        tipoPagamentoLabel,
        linhaAgendamento,
      ],
      onTap: onPropor,
      trailingActions: [
        TextButton(
          key: Key('prestador_ignorar_pedido_${pedido.id}'),
          onPressed: onIgnorar,
          child: const Text('Ignorar'),
        ),
        TextButton(
          key: Key('prestador_aceitar_pedido_${pedido.id}'),
          onPressed: onPropor,
          child: const Text('Aceitar'),
        ),
      ],
      footer: temDescricao
          ? Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            )
          : null,
    );
```

Preservar o comportamento:

```text
botao Ignorar chama onIgnorar
botao Aceitar chama onPropor
tap no card chama onPropor
```

- [ ] **Step 5: Humanizar loading/erro/empty states do Prestador**

Nos `StreamBuilder` de pedidos do Prestador, trocar mensagens com excecao bruta:

```dart
'Erro a carregar pedidos: ${snapshot.error}'
'Erro a carregar trabalhos: ${snapshot.error}'
```

por mensagens sem detalhes tecnicos:

```dart
if (kDebugMode) {
  // ignore: avoid_print
  print('[PrestadorHome] pedidos stream error: ${snapshot.error}');
}
return const AppErrorView(
  message: 'Nao conseguimos carregar os trabalhos agora. Tenta novamente daqui a pouco.',
  retryLabel: 'Tentar novamente',
);
```

Para estados de configuracao/offline, trocar textos soltos por `PedidoEmptyState`:

```dart
return const PedidoEmptyState(
  title: 'Configura a tua area de atuacao',
  message: 'Seleciona categorias para receber pedidos compativeis.',
  icon: Icons.tune,
);
```

Para offline:

```dart
return const PedidoEmptyState(
  title: 'Estas offline',
  message: 'Ativa o modo online para receber pedidos compativeis.',
  icon: Icons.wifi_off_rounded,
);
```

Quando existir botao de configuracao, manter o botao atual fora ou dentro do
`PedidoEmptyState` usando:

```dart
PedidoEmptyState(
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
)
```

- [ ] **Step 6: Rodar suite Flutter**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 7: Commit de checkpoint**

```powershell
git add lib/features/prestador/prestador_home_screen.dart
git commit -m "Melhorar listas de pedidos do prestador"
```

---

### Task 5: Limpeza de duplicacao e preservacao de comportamento

**Files:**
- Modify: `lib/features/cliente/cliente_home_screen.dart`
- Modify: `lib/features/prestador/prestador_home_screen.dart`

- [ ] **Step 1: Procurar helpers antigos sem uso**

Run:

```powershell
rg "_labelEstadoCliente|_buildValorLabelLista|_temAcaoPendente\\(|_textoAcaoPendente\\(" lib/features/cliente/cliente_home_screen.dart
```

Expected depois da integracao:

```text
0 matches para helpers substituidos pelo presenter
```

Se ainda houver matches apenas nas declaracoes dos helpers, remover os helpers:

```text
_labelEstadoCliente
_buildValorLabelLista
_temAcaoPendente
_textoAcaoPendente
```

Manter helpers ainda usados:

```text
_labelTipoPrecoCliente
_labelTipoPagamentoCliente
_normalizeServicoMode
```

- [ ] **Step 2: Confirmar keys do Prestador continuam presentes**

Run:

```powershell
rg "prestador_pedido_card_|prestador_ignorar_pedido_|prestador_aceitar_pedido_" lib/features/prestador/prestador_home_screen.dart
```

Expected:

```text
Key('prestador_pedido_card_${pedido.id}')
Key('prestador_ignorar_pedido_${pedido.id}')
Key('prestador_aceitar_pedido_${pedido.id}')
```

- [ ] **Step 3: Confirmar que nao houve mudanca de backend**

Run:

```powershell
git diff --name-status
```

Expected:

```text
apenas ficheiros Flutter UI, testes e docs M2.9
sem functions/
sem firestore.rules
sem storage.rules
sem firebase.json
sem android/key.properties
sem keystore
```

- [ ] **Step 4: Formatar Dart**

Run:

```powershell
dart format lib/features/cliente/widgets/pedido_list_presenter.dart `
  lib/features/cliente/widgets/pedido_list_card.dart `
  lib/features/cliente/widgets/pedido_empty_state.dart `
  lib/features/cliente/cliente_home_screen.dart `
  lib/features/prestador/prestador_home_screen.dart `
  test/features/cliente/widgets/pedido_list_presenter_test.dart `
  test/features/cliente/widgets/pedido_list_card_test.dart
```

Expected:

```text
Formatted ... files
```

- [ ] **Step 5: Rodar Flutter test completo**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 6: Commit de checkpoint**

```powershell
git add lib/features/cliente/cliente_home_screen.dart `
  lib/features/prestador/prestador_home_screen.dart `
  lib/features/cliente/widgets/pedido_list_presenter.dart `
  lib/features/cliente/widgets/pedido_list_card.dart `
  lib/features/cliente/widgets/pedido_empty_state.dart `
  test/features/cliente/widgets/pedido_list_presenter_test.dart `
  test/features/cliente/widgets/pedido_list_card_test.dart
git commit -m "Consolidar UX de listas de pedidos"
```

---

### Task 6: Documentacao e validacao final M2.9.2

**Files:**
- Modify: `docs/M2_9_BETA_WEB_STATUS.md`

- [ ] **Step 1: Atualizar status M2.9.2**

Em `docs/M2_9_BETA_WEB_STATUS.md`, trocar:

```text
M2.9.2: planeado em lista de pedidos UX
```

por:

```text
M2.9.2: avancado em lista de pedidos UX
```

Adicionar uma secao de evidencia:

```markdown
## M2.9.2 - Lista de Pedidos UX

Escopo implementado:

```text
cards de pedidos com estado claro
proxima acao resumida para Cliente/Prestador
empty states estruturados
loading e erros mais humanos
preservacao das keys e acoes do Prestador
reuso de PedidoStatusPresenter via presenter de lista
```

Arquivos principais:

```text
lib/features/cliente/widgets/pedido_list_presenter.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/cliente/widgets/pedido_empty_state.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
test/features/cliente/widgets/pedido_list_presenter_test.dart
test/features/cliente/widgets/pedido_list_card_test.dart
```

Validacoes locais:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou |
```

- [ ] **Step 2: Rodar validacoes finais**

Run:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
flutter test: All tests passed
test:scripts: run_android_integration_test args ok; cleanup ok; health ok
Functions/Rules: 37 passing
```

- [ ] **Step 3: Verificar diff e segredos**

Run:

```powershell
git status --short
git diff --check
git diff --name-status
```

Expected:

```text
sem key.properties staged
sem keystore staged
sem .env staged
sem functions/
sem firestore.rules
sem storage.rules
sem firebase.json
as duas delecoes antigas dos ficheiros ~$...pptx continuam fora do stage
```

- [ ] **Step 4: Commit final da implementacao**

Stage apenas ficheiros da M2.9.2:

```powershell
git add lib/features/cliente/widgets/pedido_list_presenter.dart `
  lib/features/cliente/widgets/pedido_list_card.dart `
  lib/features/cliente/widgets/pedido_empty_state.dart `
  lib/features/cliente/cliente_home_screen.dart `
  lib/features/prestador/prestador_home_screen.dart `
  test/features/cliente/widgets/pedido_list_presenter_test.dart `
  test/features/cliente/widgets/pedido_list_card_test.dart `
  docs/M2_9_BETA_WEB_STATUS.md
git commit -m "Avancar M2.9.2 lista pedidos UX"
```

- [ ] **Step 5: Push**

Run:

```powershell
git push origin main
```

Expected:

```text
main atualizado no GitHub
```

---

## Self-Review

- Spec coverage: o plano cobre cards, estado visivel, proxima acao resumida, separacao visual por estado, empty states, loading/erro, Cliente, Prestador, keys preservadas, testes, docs e validacoes.
- Scope check: nao inclui backend, Firestore Rules, Storage Rules, Cloud Functions, deploy, smoke real, cleanup real, health real, Android fisico, pagamentos, Play Store, package id, HTTPS App Links ou fecho da M2.6.
- Type consistency: `PedidoListPresenter.dataFor` retorna `PedidoListCardData`; `PedidoListCard` consome esse tipo; `PedidoEmptyState` e usado diretamente nas listas.
- Risk control: o plano preserva `PedidoChatPreview`, `PrestadorPedidoAcoes`, `onPropor`, `onIgnorar` e as keys dos testes Android/Web.
