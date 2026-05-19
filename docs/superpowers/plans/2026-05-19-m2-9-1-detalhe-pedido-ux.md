# M2.9.1 Detalhe Pedido UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Melhorar a clareza do detalhe do pedido para Cliente e Prestador com banner de estado, proxima acao, timeline mais legivel e textos de orcamento/valor final mais humanos.

**Architecture:** Criar uma camada pequena de apresentacao derivada de `Pedido + role`, testada sem Firestore, e compor widgets novos dentro de `PedidoDetalheScreen`. O backend, regras Firebase, Functions, pagamentos, deploy e Android fisico ficam fora do escopo.

**Tech Stack:** Flutter/Dart, widgets Material existentes, `flutter_test`, modelo `Pedido`, widgets atuais de pedido.

---

## File Structure

**Criar:**

- `lib/features/cliente/widgets/pedido_status_presenter.dart`
  - Helper puro para converter `Pedido + role` em textos/tom/icone/etapa.
- `lib/features/cliente/widgets/pedido_status_summary.dart`
  - Banner visual do estado principal.
- `lib/features/cliente/widgets/pedido_next_action_card.dart`
  - Card visual da proxima acao.
- `test/features/cliente/widgets/pedido_status_presenter_test.dart`
  - Testes unitarios dos textos e mapping de estados.

**Modificar:**

- `lib/features/cliente/pedido_detalhe_screen.dart`
  - Inserir banner e proxima acao no topo, melhorar loading/erro/not-found.
- `lib/features/cliente/widgets/pedido_timeline.dart`
  - Usar helper para mapear etapa e melhorar estado cancelado.
- `lib/features/cliente/widgets/cliente_pedido_acoes.dart`
  - Ajustar textos de proposta/valor final e erros para mensagens humanas.
- `lib/features/prestador/widgets/prestador_pedido_acoes.dart`
  - Ajustar textos de orcamento, valor final e erros sem mudar chamadas de service.
- `docs/M2_9_BETA_WEB_STATUS.md`
  - Registar M2.9.1 avancada quando a implementacao passar.

**Nao modificar:**

- `functions/`
- `firestore.rules`
- `storage.rules`
- `firebase.json`
- `android/key.properties`
- keystore
- ficheiros `~$...pptx`

---

### Task 1: Helper puro de status e proxima acao

**Files:**
- Create: `lib/features/cliente/widgets/pedido_status_presenter.dart`
- Test: `test/features/cliente/widgets/pedido_status_presenter_test.dart`

- [ ] **Step 1: Criar teste falhando para Cliente com valor final pendente**

Criar `test/features/cliente/widgets/pedido_status_presenter_test.dart` com:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

Pedido buildPedido({
  String estado = 'criado',
  String? prestadorId,
  String tipoPreco = 'a_combinar',
  String statusProposta = 'nenhuma',
  String statusConfirmacaoValor = 'nenhum',
  double? precoPropostoPrestador,
  String? canceladoPor,
}) {
  return Pedido(
    id: 'pedido_1',
    clienteId: 'cliente_1',
    prestadorId: prestadorId,
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: tipoPreco,
    tipoPagamento: 'dinheiro',
    statusProposta: statusProposta,
    precoPropostoPrestador: precoPropostoPrestador,
    statusConfirmacaoValor: statusConfirmacaoValor,
    canceladoPor: canceladoPor,
    createdAt: DateTime(2026, 5, 19),
  );
}

void main() {
  group('PedidoStatusPresenter', () {
    test('cliente ve proxima acao correta em valor final pendente', () {
      final pedido = buildPedido(
        estado: 'aguarda_confirmacao_valor',
        prestadorId: 'prestador_1',
        statusConfirmacaoValor: 'pendente_cliente',
        precoPropostoPrestador: 100,
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(summary.title, 'Confirma o valor final');
      expect(summary.tone, PedidoStatusTone.warning);
      expect(summary.icon, Icons.price_check_rounded);
      expect(nextAction.title, 'Proxima acao');
      expect(nextAction.description, contains('confirma'));
      expect(nextAction.description, contains('valor final'));
      expect(nextAction.nextStep, contains('pedido fica concluido'));
      expect(nextAction.hasUserAction, isTrue);
    });
  });
}
```

- [ ] **Step 2: Rodar teste e confirmar falha por ficheiro/helper inexistente**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_status_presenter_test.dart
```

Expected:

```text
Error: Error when reading ... pedido_status_presenter.dart
```

- [ ] **Step 3: Implementar helper minimo**

Criar `lib/features/cliente/widgets/pedido_status_presenter.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';

enum PedidoViewerRole { cliente, prestador }

enum PedidoStatusTone { info, success, warning, danger, neutral }

class PedidoStatusSummaryData {
  final String title;
  final String description;
  final String actor;
  final PedidoStatusTone tone;
  final IconData icon;

  const PedidoStatusSummaryData({
    required this.title,
    required this.description,
    required this.actor,
    required this.tone,
    required this.icon,
  });
}

class PedidoNextActionData {
  final String title;
  final String description;
  final String nextStep;
  final bool hasUserAction;

  const PedidoNextActionData({
    required this.title,
    required this.description,
    required this.nextStep,
    required this.hasUserAction,
  });
}

class PedidoStatusPresenter {
  const PedidoStatusPresenter._();

  static PedidoStatusSummaryData summaryFor(
    Pedido pedido, {
    required PedidoViewerRole role,
  }) {
    if (pedido.estado == 'cancelado') {
      final actor = pedido.canceladoPor == 'cliente'
          ? 'Cancelado pelo cliente'
          : pedido.canceladoPor == 'prestador'
              ? 'Cancelado pelo prestador'
              : 'Pedido cancelado';
      return PedidoStatusSummaryData(
        title: 'Pedido cancelado',
        description: 'Este pedido terminou sem conclusao do servico.',
        actor: actor,
        tone: PedidoStatusTone.danger,
        icon: Icons.cancel_outlined,
      );
    }

    if (pedido.estado == 'concluido') {
      return const PedidoStatusSummaryData(
        title: 'Pedido concluido',
        description: 'O servico ficou concluido e podes consultar os detalhes.',
        actor: 'Estado final',
        tone: PedidoStatusTone.success,
        icon: Icons.verified_rounded,
      );
    }

    if (pedido.statusConfirmacaoValor == 'pendente_cliente' ||
        pedido.estado == 'aguarda_confirmacao_valor') {
      return const PedidoStatusSummaryData(
        title: 'Confirma o valor final',
        description: 'O prestador terminou o servico e enviou o valor final.',
        actor: 'Acao do cliente',
        tone: PedidoStatusTone.warning,
        icon: Icons.price_check_rounded,
      );
    }

    if (role == PedidoViewerRole.prestador &&
        pedido.estado == 'aguarda_resposta_prestador') {
      return const PedidoStatusSummaryData(
        title: 'Convite recebido',
        description: 'O cliente escolheu-te para este servico.',
        actor: 'Acao do prestador',
        tone: PedidoStatusTone.warning,
        icon: Icons.mark_chat_unread_rounded,
      );
    }

    if (pedido.estado == 'criado') {
      return const PedidoStatusSummaryData(
        title: 'A procurar prestador',
        description: 'Estamos a procurar alguem disponivel para este pedido.',
        actor: 'A aguardar prestador',
        tone: PedidoStatusTone.info,
        icon: Icons.search_rounded,
      );
    }

    if (pedido.estado == 'aceito') {
      return const PedidoStatusSummaryData(
        title: 'Prestador aceite',
        description: 'O pedido ja tem prestador e esta pronto para iniciar.',
        actor: 'Proximo passo: iniciar servico',
        tone: PedidoStatusTone.info,
        icon: Icons.handshake_rounded,
      );
    }

    if (pedido.estado == 'em_andamento') {
      return const PedidoStatusSummaryData(
        title: 'Servico em andamento',
        description: 'O trabalho esta em curso.',
        actor: 'A acompanhar',
        tone: PedidoStatusTone.info,
        icon: Icons.build_circle_outlined,
      );
    }

    if (pedido.estado == 'aguarda_resposta_cliente' ||
        pedido.statusProposta == 'pendente_cliente') {
      return const PedidoStatusSummaryData(
        title: 'Proposta para rever',
        description: 'O prestador enviou uma estimativa para o servico.',
        actor: 'Acao do cliente',
        tone: PedidoStatusTone.warning,
        icon: Icons.request_quote_rounded,
      );
    }

    return PedidoStatusSummaryData(
      title: pedido.estado,
      description: 'Consulta os detalhes e acompanha o progresso do pedido.',
      actor: 'Estado do pedido',
      tone: PedidoStatusTone.neutral,
      icon: Icons.assignment_outlined,
    );
  }

  static PedidoNextActionData nextActionFor(
    Pedido pedido, {
    required PedidoViewerRole role,
  }) {
    if (pedido.estado == 'cancelado') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Este pedido foi cancelado.',
        nextStep: 'Podes consultar o historico e criar outro pedido se precisares.',
        hasUserAction: false,
      );
    }

    if (pedido.estado == 'concluido') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Pedido concluido. Podes consultar os detalhes deste servico.',
        nextStep: 'Nao ha acoes obrigatorias neste pedido.',
        hasUserAction: false,
      );
    }

    if (pedido.statusConfirmacaoValor == 'pendente_cliente' ||
        pedido.estado == 'aguarda_confirmacao_valor') {
      if (role == PedidoViewerRole.cliente) {
        return const PedidoNextActionData(
          title: 'Proxima acao',
          description: 'Revê e confirma o valor final enviado pelo prestador.',
          nextStep: 'Depois da confirmacao, o pedido fica concluido.',
          hasUserAction: true,
        );
      }
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Aguarda a confirmacao do valor final pelo cliente.',
        nextStep: 'Quando o cliente confirmar, o pedido fica concluido.',
        hasUserAction: false,
      );
    }

    if (role == PedidoViewerRole.prestador &&
        pedido.estado == 'aguarda_resposta_prestador') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Aceita ou recusa o convite direto do cliente.',
        nextStep: 'Se aceitares, o pedido avanca para servico aceite.',
        hasUserAction: true,
      );
    }

    if (role == PedidoViewerRole.cliente &&
        (pedido.estado == 'aguarda_resposta_cliente' ||
            pedido.statusProposta == 'pendente_cliente')) {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Revê a estimativa do prestador antes de escolher.',
        nextStep: 'Se aceitares, o pedido avanca para servico aceite.',
        hasUserAction: true,
      );
    }

    if (role == PedidoViewerRole.prestador && pedido.estado == 'em_andamento') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Quando terminares o trabalho, envia o valor final.',
        nextStep: 'O cliente tera de confirmar esse valor para concluir o pedido.',
        hasUserAction: true,
      );
    }

    if (pedido.estado == 'criado') {
      return PedidoNextActionData(
        title: 'Proxima acao',
        description: role == PedidoViewerRole.cliente
            ? 'Aguarda por um prestador ou escolhe manualmente.'
            : 'Este pedido esta disponivel para prestadores compativeis.',
        nextStep: 'Quando houver prestador aceite, o pedido avanca.',
        hasUserAction: role == PedidoViewerRole.cliente,
      );
    }

    return const PedidoNextActionData(
      title: 'Proxima acao',
      description: 'Acompanha o estado do pedido nesta tela.',
      nextStep: 'As acoes disponiveis aparecem abaixo quando forem necessarias.',
      hasUserAction: false,
    );
  }

  static int timelineStepFor(String estado) {
    switch (estado) {
      case 'criado':
      case 'aguarda_resposta_prestador':
      case 'aguarda_resposta_cliente':
        return 0;
      case 'aceito':
        return 1;
      case 'em_andamento':
      case 'aguarda_confirmacao_valor':
        return 2;
      case 'concluido':
      case 'cancelado':
        return 3;
      default:
        return 0;
    }
  }
}
```

- [ ] **Step 4: Rodar teste especifico e confirmar passagem**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_status_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Expandir testes do helper**

Adicionar no mesmo ficheiro:

```dart
    test('prestador ve proxima acao correta em convite pendente', () {
      final pedido = buildPedido(
        estado: 'aguarda_resposta_prestador',
        prestadorId: 'prestador_1',
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.prestador,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.prestador,
      );

      expect(summary.title, 'Convite recebido');
      expect(summary.actor, 'Acao do prestador');
      expect(nextAction.description, contains('Aceita ou recusa'));
      expect(nextAction.hasUserAction, isTrue);
    });

    test('pedido concluido mostra estado final sem acao indevida', () {
      final pedido = buildPedido(
        estado: 'concluido',
        prestadorId: 'prestador_1',
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(summary.title, 'Pedido concluido');
      expect(summary.tone, PedidoStatusTone.success);
      expect(nextAction.hasUserAction, isFalse);
      expect(nextAction.description, contains('consultar os detalhes'));
      expect(nextAction.description, isNot(contains('avaliar')));
    });

    test('pedido cancelado mostra cancelamento', () {
      final pedido = buildPedido(
        estado: 'cancelado',
        canceladoPor: 'prestador',
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(summary.title, 'Pedido cancelado');
      expect(summary.actor, 'Cancelado pelo prestador');
      expect(summary.tone, PedidoStatusTone.danger);
      expect(nextAction.hasUserAction, isFalse);
    });

    test('timeline mapeia estados principais', () {
      expect(PedidoStatusPresenter.timelineStepFor('criado'), 0);
      expect(PedidoStatusPresenter.timelineStepFor('aguarda_resposta_prestador'), 0);
      expect(PedidoStatusPresenter.timelineStepFor('aguarda_resposta_cliente'), 0);
      expect(PedidoStatusPresenter.timelineStepFor('aceito'), 1);
      expect(PedidoStatusPresenter.timelineStepFor('em_andamento'), 2);
      expect(PedidoStatusPresenter.timelineStepFor('aguarda_confirmacao_valor'), 2);
      expect(PedidoStatusPresenter.timelineStepFor('concluido'), 3);
      expect(PedidoStatusPresenter.timelineStepFor('cancelado'), 3);
    });
```

- [ ] **Step 6: Rodar teste expandido**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_status_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 7: Commit**

```powershell
git add lib/features/cliente/widgets/pedido_status_presenter.dart test/features/cliente/widgets/pedido_status_presenter_test.dart
git commit -m "Adicionar presenter de status do pedido"
```

---

### Task 2: Widgets de banner e proxima acao

**Files:**
- Create: `lib/features/cliente/widgets/pedido_status_summary.dart`
- Create: `lib/features/cliente/widgets/pedido_next_action_card.dart`
- Modify: `lib/features/cliente/pedido_detalhe_screen.dart`

- [ ] **Step 1: Criar `PedidoStatusSummary`**

Criar `lib/features/cliente/widgets/pedido_status_summary.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoStatusSummary extends StatelessWidget {
  final PedidoStatusSummaryData data;

  const PedidoStatusSummary({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = switch (data.tone) {
      PedidoStatusTone.success => Colors.green,
      PedidoStatusTone.warning => Colors.orange,
      PedidoStatusTone.danger => colors.error,
      PedidoStatusTone.neutral => Colors.grey,
      PedidoStatusTone.info => colors.primary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: toneColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: toneColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  data.actor,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: toneColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Criar `PedidoNextActionCard`**

Criar `lib/features/cliente/widgets/pedido_next_action_card.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoNextActionCard extends StatelessWidget {
  final PedidoNextActionData data;

  const PedidoNextActionCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = data.hasUserAction ? colors.primary : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                data.hasUserAction
                    ? Icons.touch_app_rounded
                    : Icons.hourglass_empty_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            data.nextStep,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Integrar no detalhe do pedido**

Modificar `lib/features/cliente/pedido_detalhe_screen.dart`.

Adicionar imports:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_next_action_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_summary.dart';
```

Depois de calcular `valorLabel`, adicionar:

```dart
            final viewerRole =
                isCliente ? PedidoViewerRole.cliente : PedidoViewerRole.prestador;
            final statusSummary = PedidoStatusPresenter.summaryFor(
              pedido,
              role: viewerRole,
            );
            final nextAction = PedidoStatusPresenter.nextActionFor(
              pedido,
              role: viewerRole,
            );
```

Logo antes do `Row` do cabecalho existente, inserir:

```dart
                  PedidoStatusSummary(data: statusSummary),
                  const SizedBox(height: 12),
                  PedidoNextActionCard(data: nextAction),
                  const SizedBox(height: 16),
```

Manter o `Chip` atual para compatibilidade visual, mas ele passa a ser secundario.

- [ ] **Step 4: Rodar teste Flutter**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_status_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/cliente/widgets/pedido_status_summary.dart lib/features/cliente/widgets/pedido_next_action_card.dart lib/features/cliente/pedido_detalhe_screen.dart
git commit -m "Adicionar resumo e proxima acao no detalhe do pedido"
```

---

### Task 3: Timeline com mapping centralizado

**Files:**
- Modify: `lib/features/cliente/widgets/pedido_timeline.dart`
- Test: `test/features/cliente/widgets/pedido_status_presenter_test.dart`

- [ ] **Step 1: Usar presenter no timeline**

Modificar `lib/features/cliente/widgets/pedido_timeline.dart`.

Adicionar import:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
```

Substituir `_stepIndex()` por:

```dart
  int _stepIndex() => PedidoStatusPresenter.timelineStepFor(estado);
```

- [ ] **Step 2: Melhorar labels do estado final**

No `buildLabel`, manter dimensoes existentes. No ultimo label, manter:

```dart
estado == 'cancelado'
    ? l10n.timelineCancelled
    : l10n.timelineCompleted
```

Nao adicionar novas etapas intermediarias nesta subfase.

- [ ] **Step 3: Rodar teste do presenter**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_status_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 4: Commit**

```powershell
git add lib/features/cliente/widgets/pedido_timeline.dart test/features/cliente/widgets/pedido_status_presenter_test.dart
git commit -m "Centralizar timeline do pedido"
```

---

### Task 4: Textos de Cliente para proposta e valor final

**Files:**
- Modify: `lib/features/cliente/widgets/cliente_pedido_acoes.dart`

- [ ] **Step 1: Ajustar texto da proposta/faixa**

Em `_PropostaPrestadorCard`, trocar:

```dart
const Text(
  'Tens uma proposta de prestador',
```

por:

```dart
const Text(
  'Revê a estimativa do prestador',
```

Trocar:

```dart
'Estimativa: ${CurrencyUtils.format(min)} a ${CurrencyUtils.format(max)}'
```

por:

```dart
'Faixa estimada: ${CurrencyUtils.format(min)} a ${CurrencyUtils.format(max)}'
```

Manter os mesmos botões e keys.

- [ ] **Step 2: Ajustar texto do valor final**

Em `_ValorFinalPendenteCard`, trocar:

```dart
const Text(
  'Valor final do servico',
```

por:

```dart
const Text(
  'Confirma o valor final',
```

Trocar:

```dart
'Total cobrado: ${CurrencyUtils.format(valor)}'
```

por:

```dart
'Valor final enviado pelo prestador: ${CurrencyUtils.format(valor)}'
```

Trocar o texto explicativo por:

```dart
const Text(
  'Ao confirmares, o backend conclui o pedido e calcula automaticamente comissao e ganhos.',
```

- [ ] **Step 3: Humanizar erros sem despejar excecao**

Trocar em `_confirmarValor`:

```dart
content: Text('Erro ao confirmar valor: $e'),
```

por:

```dart
content: Text('Nao conseguimos confirmar o valor agora. Tenta novamente.'),
```

Trocar em `_rejeitarValor`:

```dart
content: Text('Erro ao registar duvida: $e'),
```

por:

```dart
content: Text('Nao conseguimos registar a duvida agora. Tenta novamente.'),
```

Se quiser preservar diagnostico em debug, adicionar `debugPrint` dentro do `catch`:

```dart
debugPrint('Erro ao confirmar valor final: $e');
```

e importar `package:flutter/foundation.dart`.

- [ ] **Step 4: Rodar Flutter test**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/cliente/widgets/cliente_pedido_acoes.dart
git commit -m "Melhorar textos de valor final do cliente"
```

---

### Task 5: Textos de Prestador para orcamento e valor final

**Files:**
- Modify: `lib/features/prestador/widgets/prestador_pedido_acoes.dart`

- [ ] **Step 1: Clarificar orcamento/faixa estimada**

Em `_AcaoEnviarOrcamento`, trocar label do botao:

```dart
label: const Text('Enviar orcamento (faixa min/max)'),
```

por:

```dart
label: const Text('Enviar estimativa ao cliente'),
```

No dialog, trocar titulo:

```dart
title: const Text('Enviar orcamento'),
```

por:

```dart
title: const Text('Enviar estimativa'),
```

Adicionar no topo do `content`:

```dart
const Text(
  'Esta faixa ajuda o cliente a decidir. O valor final so deve ser enviado quando o servico terminar.',
  style: TextStyle(fontSize: 12, color: Colors.black54),
),
const SizedBox(height: 12),
```

- [ ] **Step 2: Clarificar valor final**

Em `_AcaoLancarValorFinal`, no dialog `LanCar valor final`, adicionar texto antes do campo:

```dart
const Text(
  'Este e o valor final do servico. O cliente ainda precisa confirmar antes do pedido ficar concluido.',
  style: TextStyle(fontSize: 12, color: Colors.black54),
),
const SizedBox(height: 12),
```

Trocar erro:

```dart
SnackBar(content: Text('Erro ao enviar valor final: $e')),
```

por:

```dart
SnackBar(content: Text('Nao conseguimos enviar o valor final agora. Tenta novamente.')),
```

Com `debugPrint`, importar `package:flutter/foundation.dart` se necessario.

- [ ] **Step 3: Nao alterar chamadas de service**

Confirmar que continuam iguais:

```dart
PedidoService.instance.enviarPropostaFaixa(...)
PedidoService.instance.proporValorFinal(...)
```

- [ ] **Step 4: Rodar Flutter test**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/prestador/widgets/prestador_pedido_acoes.dart
git commit -m "Melhorar textos de valor final do prestador"
```

---

### Task 6: Fallbacks do detalhe do pedido

**Files:**
- Modify: `lib/features/cliente/pedido_detalhe_screen.dart`

- [ ] **Step 1: Melhorar erro de carregamento**

Trocar:

```dart
return Center(
  child: Text(
    l10n.orderLoadError(snapshot.error.toString()),
  ),
);
```

por:

```dart
return Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 40),
        const SizedBox(height: 12),
        Text(
          l10n.orderLoadError(''),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.actionBack),
        ),
      ],
    ),
  ),
);
```

Se `l10n.actionBack` nao existir, usar texto hardcoded `'Voltar'`.

- [ ] **Step 2: Melhorar pedido nao encontrado**

Trocar:

```dart
return Center(
  child: Text(l10n.orderNotFound),
);
```

por:

```dart
return Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off_rounded, size: 40),
        const SizedBox(height: 12),
        Text(
          l10n.orderNotFound,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Voltar'),
        ),
      ],
    ),
  ),
);
```

- [ ] **Step 3: Rodar Flutter test**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 4: Commit**

```powershell
git add lib/features/cliente/pedido_detalhe_screen.dart
git commit -m "Melhorar fallbacks do detalhe do pedido"
```

---

### Task 7: Documentacao e validacao final M2.9.1

**Files:**
- Create: `docs/M2_9_BETA_WEB_STATUS.md`

- [ ] **Step 1: Atualizar status**

Criar `docs/M2_9_BETA_WEB_STATUS.md` para nao misturar beta web com hardening
de producao:

````markdown
# M2.9 Beta Web Status

Data: 2026-05-19

## Estado

```text
M2.9: iniciado
M2.9.1: avancado em detalhe do pedido UX
```

## M2.9.1

Escopo:

```text
banner principal de estado
proxima acao por Cliente/Prestador
timeline com mapping centralizado
textos mais claros de orcamento e valor final
fallbacks mais humanos no detalhe do pedido
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
pagamentos reais
Play Store
package id final
HTTPS App Links
Android fisico
```
````

- [ ] **Step 2: Rodar validacoes obrigatorias**

Run:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
flutter test: All tests passed, 49/49 ou mais
test:scripts: run_android_integration_test args ok; cleanup ok; health ok
Functions/Rules: 37/37 passing
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
sem key.properties
sem keystore
sem .env
sem ficheiros temporarios ~$...pptx staged
```

- [ ] **Step 4: Commit final**

Stage apenas ficheiros da M2.9.1:

```powershell
git add lib/features/cliente/widgets/pedido_status_presenter.dart `
  lib/features/cliente/widgets/pedido_status_summary.dart `
  lib/features/cliente/widgets/pedido_next_action_card.dart `
  lib/features/cliente/widgets/pedido_timeline.dart `
  lib/features/cliente/widgets/cliente_pedido_acoes.dart `
  lib/features/prestador/widgets/prestador_pedido_acoes.dart `
  lib/features/cliente/pedido_detalhe_screen.dart `
  test/features/cliente/widgets/pedido_status_presenter_test.dart `
  docs/M2_9_BETA_WEB_STATUS.md
git commit -m "Avancar M2.9.1 detalhe pedido UX"
```

- [ ] **Step 5: Push**

```powershell
git push origin main
```

Expected:

```text
main atualizado no GitHub
```

---

## Self-Review

- Spec coverage: o plano cobre banner, proxima acao, timeline, textos de orcamento/valor final, fallbacks, testes e docs.
- Scope check: nao inclui backend, regras, Functions, deploy, pagamentos, Play Store, package id, HTTPS App Links, Android fisico ou M2.6.
- Test strategy: primeiro helper puro, depois widget/composicao, regressao Flutter e regressao Firebase local.
- Data model: usa apenas campos ja existentes em `Pedido`.
- Risk control: widgets novos evitam aumentar ainda mais a responsabilidade de `pedido_detalhe_screen.dart`.
