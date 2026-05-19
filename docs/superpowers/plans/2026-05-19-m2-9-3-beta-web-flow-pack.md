# M2.9.3 Beta Web Flow Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Melhorar o fluxo Web completo Cliente <-> Prestador, desde criacao do pedido ate conclusao/cancelamento, com feedback claro, navegacao orientada e linguagem consistente entre lista e detalhe.

**Architecture:** Criar uma camada pura e pequena de apresentacao de fluxo (`PedidoFlowPresenter`) para centralizar textos de sucesso, erro, espera e estados finais. Integrar essa linguagem nos pontos ja existentes de UI sem alterar services, rules, Functions ou schema. Extrair apenas widgets auxiliares pequenos quando isso reduzir complexidade nas telas grandes.

**Tech Stack:** Flutter/Dart, Material widgets, `flutter_test`, modelo `Pedido`, `PedidoStatusPresenter`, `PedidoListPresenter`, `PedidoService`, `PedidosRepo`, `AppLoadingView`, `AppErrorView`, widgets locais de pedido.

---

## File Structure

**Criar:**

- `lib/features/cliente/widgets/pedido_flow_presenter.dart`
  - Presenter puro para mensagens de fluxo: pos-criacao, proposta, valor final, cancelamento, aguardando e estados finais.
- `lib/features/cliente/widgets/pedido_final_state_panel.dart`
  - Painel compacto para pedido concluido/cancelado no detalhe, usando dados ja existentes.
- `test/features/cliente/widgets/pedido_flow_presenter_test.dart`
  - Testes unitarios de textos/estados de fluxo.
- `test/features/cliente/widgets/pedido_final_state_panel_test.dart`
  - Testes de widget para estados finais.

**Modificar:**

- `lib/features/cliente/novo_pedido_screen.dart`
  - Feedback pos-criacao e erro humano sem excecao bruta.
- `lib/features/cliente/aguardando_prestador_screen.dart`
  - Loading/erro/nao encontrado mais humanos e navegacao orientada quando prestador aceita/cancela.
- `lib/features/cliente/pedido_detalhe_screen.dart`
  - Usar painel final; humanizar erros de convite/cancelamento/valor final que ainda despejam excecao.
- `lib/features/cliente/widgets/cliente_pedido_acoes.dart`
  - Textos e SnackBars de proposta/valor final usando presenter.
- `lib/features/prestador/widgets/prestador_pedido_acoes.dart`
  - Textos e SnackBars de convite, inicio, estimativa e valor final usando presenter.
- `docs/M2_9_BETA_WEB_STATUS.md`
  - Registar M2.9.3 avancada e evidencias finais.

**Nao modificar:**

- `functions/`
- `firestore.rules`
- `storage.rules`
- `firebase.json`
- `android/key.properties`
- keystore
- `.env`
- ficheiros `~$...pptx`

---

### Task 1: Presenter puro de fluxo

**Files:**
- Create: `lib/features/cliente/widgets/pedido_flow_presenter.dart`
- Test: `test/features/cliente/widgets/pedido_flow_presenter_test.dart`

- [ ] **Step 1: Criar teste falhando para o presenter**

Criar `test/features/cliente/widgets/pedido_flow_presenter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';

Pedido buildPedido({
  String estado = 'criado',
  String? prestadorId,
  String? canceladoPor,
  String? cancelamentoMotivo,
  double? precoPropostoPrestador,
  double? precoFinal,
  String statusConfirmacaoValor = 'nenhum',
  DateTime? concluidoEm,
  DateTime? canceladoEm,
}) {
  return Pedido(
    id: 'pedido_flow_1',
    clienteId: 'cliente_1',
    prestadorId: prestadorId,
    servicoId: 'srv_1',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: 'por_orcamento',
    tipoPagamento: 'dinheiro',
    canceladoPor: canceladoPor,
    cancelamentoMotivo: cancelamentoMotivo,
    precoPropostoPrestador: precoPropostoPrestador,
    precoFinal: precoFinal,
    statusConfirmacaoValor: statusConfirmacaoValor,
    concluidoEm: concluidoEm,
    canceladoEm: canceladoEm,
    createdAt: DateTime(2026, 5, 19),
  );
}

void main() {
  group('PedidoFlowPresenter', () {
    test('pos-criacao automatica orienta para aguardando prestador', () {
      final feedback = PedidoFlowPresenter.creationSuccess(manual: false);

      expect(feedback.title, 'Pedido criado');
      expect(feedback.message, contains('vamos procurar'));
      expect(feedback.nextStep, contains('avisamos'));
    });

    test('pos-criacao manual orienta para aguardar resposta do prestador', () {
      final feedback = PedidoFlowPresenter.creationSuccess(manual: true);

      expect(feedback.title, 'Convite enviado');
      expect(feedback.message, contains('prestador escolhido'));
      expect(feedback.nextStep, contains('aceitar ou recusar'));
    });

    test('cliente ve copy segura para confirmar valor final', () {
      final copy = PedidoFlowPresenter.clientFinalValueCopy(
        buildPedido(
          estado: 'aguarda_confirmacao_valor',
          precoPropostoPrestador: 120,
          statusConfirmacaoValor: 'pendente_cliente',
        ),
      );

      expect(copy.title, 'Confirma o valor final');
      expect(copy.primaryActionLabel, 'Confirmar valor');
      expect(copy.secondaryActionLabel, 'Tenho uma duvida');
      expect(copy.body, contains('valor final'));
      expect(copy.body, isNot(contains('backend')));
    });

    test('prestador ve copy para aguardar confirmacao do cliente', () {
      final copy = PedidoFlowPresenter.providerWaitingClientCopy(
        buildPedido(
          estado: 'aguarda_confirmacao_valor',
          precoPropostoPrestador: 90,
        ),
      );

      expect(copy.title, 'Aguardar confirmacao do cliente');
      expect(copy.body, contains('cliente confirmar'));
      expect(copy.nextStep, contains('fica concluido'));
    });

    test('pedido concluido gera estado final sem acao indevida', () {
      final state = PedidoFlowPresenter.finalStateFor(
        buildPedido(
          estado: 'concluido',
          precoFinal: 80,
          concluidoEm: DateTime(2026, 5, 19, 10),
        ),
      );

      expect(state.title, 'Pedido concluido');
      expect(state.message, contains('ficou concluido'));
      expect(state.actionHint, 'Consulta os detalhes sempre que precisares.');
      expect(state.isFinal, isTrue);
    });

    test('pedido cancelado mostra responsavel quando existir', () {
      final state = PedidoFlowPresenter.finalStateFor(
        buildPedido(
          estado: 'cancelado',
          canceladoPor: 'prestador',
          cancelamentoMotivo: 'Agenda indisponivel',
          canceladoEm: DateTime(2026, 5, 19, 11),
        ),
      );

      expect(state.title, 'Pedido cancelado');
      expect(state.message, contains('prestador'));
      expect(state.detail, contains('Agenda indisponivel'));
      expect(state.isFinal, isTrue);
    });
  });
}
```

- [ ] **Step 2: Rodar teste e confirmar falha por ficheiro inexistente**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_flow_presenter_test.dart
```

Expected:

```text
Error: Error when reading ... pedido_flow_presenter.dart
```

- [ ] **Step 3: Implementar presenter minimo**

Criar `lib/features/cliente/widgets/pedido_flow_presenter.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/utils/currency_utils.dart';

class PedidoFlowFeedback {
  final String title;
  final String message;
  final String nextStep;

  const PedidoFlowFeedback({
    required this.title,
    required this.message,
    required this.nextStep,
  });
}

class PedidoFlowActionCopy {
  final String title;
  final String body;
  final String? nextStep;
  final String primaryActionLabel;
  final String? secondaryActionLabel;

  const PedidoFlowActionCopy({
    required this.title,
    required this.body,
    required this.primaryActionLabel,
    this.nextStep,
    this.secondaryActionLabel,
  });
}

class PedidoFinalStateData {
  final String title;
  final String message;
  final String? detail;
  final String actionHint;
  final IconData icon;
  final Color color;
  final bool isFinal;

  const PedidoFinalStateData({
    required this.title,
    required this.message,
    required this.actionHint,
    required this.icon,
    required this.color,
    this.detail,
    this.isFinal = true,
  });
}

class PedidoFlowPresenter {
  const PedidoFlowPresenter._();

  static PedidoFlowFeedback creationSuccess({required bool manual}) {
    if (manual) {
      return const PedidoFlowFeedback(
        title: 'Convite enviado',
        message:
            'O pedido foi criado e enviado ao prestador escolhido por ti.',
        nextStep:
            'Agora o prestador pode aceitar ou recusar o convite. Acompanha o estado no detalhe do pedido.',
      );
    }
    return const PedidoFlowFeedback(
      title: 'Pedido criado',
      message:
          'Recebemos o teu pedido e vamos procurar um prestador compativel.',
      nextStep:
          'Fica nesta tela: avisamos assim que alguem aceitar ou quando houver novidades.',
    );
  }

  static PedidoFlowFeedback creationError({required bool editing}) {
    return PedidoFlowFeedback(
      title: editing ? 'Nao conseguimos atualizar' : 'Nao conseguimos criar',
      message: editing
          ? 'Nao foi possivel guardar as alteracoes agora.'
          : 'Nao foi possivel criar o pedido agora.',
      nextStep: 'Verifica a ligacao e tenta novamente.',
    );
  }

  static PedidoFlowActionCopy clientProposalCopy(Pedido pedido) {
    return const PedidoFlowActionCopy(
      title: 'Revê a proposta',
      body:
          'O prestador respondeu ao teu pedido. Confirma se queres avancar com este prestador ou rejeita para continuar a procurar.',
      primaryActionLabel: 'Aceitar este prestador',
      secondaryActionLabel: 'Rejeitar proposta',
      nextStep: 'Se aceitares, o pedido avanca para combinarem e iniciarem o servico.',
    );
  }

  static PedidoFlowActionCopy clientFinalValueCopy(Pedido pedido) {
    final valor = pedido.precoPropostoPrestador ?? pedido.precoFinal;
    final valorTexto =
        valor == null ? 'o valor enviado' : CurrencyUtils.format(valor);

    return PedidoFlowActionCopy(
      title: 'Confirma o valor final',
      body:
          'O prestador terminou o servico e enviou $valorTexto como valor final. Confirma apenas se estiver tudo certo.',
      primaryActionLabel: 'Confirmar valor',
      secondaryActionLabel: 'Tenho uma duvida',
      nextStep:
          'Ao confirmares, o pedido fica concluido. Se tiveres duvidas, fala com o prestador antes de confirmar.',
    );
  }

  static PedidoFlowActionCopy providerInviteCopy(Pedido pedido) {
    return const PedidoFlowActionCopy(
      title: 'Convite direto do cliente',
      body:
          'O cliente escolheu-te para este servico. Aceita se consegues realizar o trabalho.',
      primaryActionLabel: 'Aceitar',
      secondaryActionLabel: 'Recusar',
      nextStep: 'Se aceitares, o cliente passa a acompanhar o pedido contigo.',
    );
  }

  static PedidoFlowActionCopy providerStartCopy(Pedido pedido) {
    return const PedidoFlowActionCopy(
      title: 'Iniciar servico',
      body:
          'Inicia o servico quando estiveres pronto para comecar o trabalho combinado com o cliente.',
      primaryActionLabel: 'Iniciar servico',
      nextStep: 'Depois de iniciares, poderas enviar o valor final quando terminares.',
    );
  }

  static PedidoFlowActionCopy providerFinalValueCopy(Pedido pedido) {
    return const PedidoFlowActionCopy(
      title: 'Enviar valor final',
      body:
          'Envia o valor final apenas quando terminares o trabalho. O cliente ainda precisa confirmar.',
      primaryActionLabel: 'Enviar ao cliente',
      nextStep: 'Quando o cliente confirmar, o pedido fica concluido.',
    );
  }

  static PedidoFlowActionCopy providerWaitingClientCopy(Pedido pedido) {
    return const PedidoFlowActionCopy(
      title: 'Aguardar confirmacao do cliente',
      body:
          'O valor final ja foi enviado. Agora falta o cliente confirmar ou pedir ajuste.',
      primaryActionLabel: 'Aguardar cliente',
      nextStep: 'Quando o cliente confirmar, o pedido fica concluido.',
    );
  }

  static PedidoFinalStateData finalStateFor(Pedido pedido) {
    if (pedido.estado == 'cancelado') {
      final by = _cancelledByLabel(pedido.canceladoPor);
      final reason = pedido.cancelamentoMotivo?.trim();
      return PedidoFinalStateData(
        title: 'Pedido cancelado',
        message: by == null
            ? 'Este pedido foi cancelado.'
            : 'Este pedido foi cancelado pelo $by.',
        detail: reason == null || reason.isEmpty ? null : 'Motivo: $reason',
        actionHint:
            'Consulta os detalhes ou cria um novo pedido quando precisares.',
        icon: Icons.cancel_outlined,
        color: Colors.redAccent,
      );
    }

    if (pedido.estado == 'concluido') {
      return const PedidoFinalStateData(
        title: 'Pedido concluido',
        message: 'O servico ficou concluido.',
        actionHint: 'Consulta os detalhes sempre que precisares.',
        icon: Icons.check_circle_outline,
        color: Colors.green,
      );
    }

    return const PedidoFinalStateData(
      title: 'Pedido em andamento',
      message: 'Este pedido ainda tem passos pendentes.',
      actionHint: 'Segue a proxima acao indicada no topo do detalhe.',
      icon: Icons.info_outline,
      color: Colors.blue,
      isFinal: false,
    );
  }

  static String successMessage(String action) {
    switch (action) {
      case 'acceptProposal':
        return 'Prestador escolhido. Combina os detalhes pelo chat.';
      case 'rejectProposal':
        return 'Proposta rejeitada. O pedido volta a procurar prestador.';
      case 'confirmFinalValue':
        return 'Valor final confirmado. O pedido ficou concluido.';
      case 'rejectFinalValue':
        return 'Duvida registada. Fala com o prestador pelo chat para ajustar.';
      case 'acceptInvite':
        return 'Convite aceite. Podes combinar os detalhes com o cliente.';
      case 'refuseInvite':
        return 'Convite recusado. O cliente podera procurar outro prestador.';
      case 'startService':
        return 'Servico iniciado. Quando terminares, envia o valor final.';
      case 'sendEstimate':
        return 'Estimativa enviada. Agora aguarda a resposta do cliente.';
      case 'sendFinalValue':
        return 'Valor final enviado. Aguarda a confirmacao do cliente.';
      default:
        return 'Acao concluida.';
    }
  }

  static String errorMessage(String action) {
    switch (action) {
      case 'acceptProposal':
        return 'Nao conseguimos aceitar a proposta agora. Tenta novamente.';
      case 'rejectProposal':
        return 'Nao conseguimos rejeitar a proposta agora. Tenta novamente.';
      case 'confirmFinalValue':
        return 'Nao conseguimos confirmar o valor agora. Tenta novamente.';
      case 'rejectFinalValue':
        return 'Nao conseguimos registar a duvida agora. Tenta novamente.';
      case 'acceptInvite':
        return 'Nao conseguimos aceitar o convite agora. Tenta novamente.';
      case 'refuseInvite':
        return 'Nao conseguimos recusar o convite agora. Tenta novamente.';
      case 'startService':
        return 'Nao conseguimos iniciar o servico agora. Tenta novamente.';
      case 'sendEstimate':
        return 'Nao conseguimos enviar a estimativa agora. Tenta novamente.';
      case 'sendFinalValue':
        return 'Nao conseguimos enviar o valor final agora. Tenta novamente.';
      case 'cancelOrder':
        return 'Nao conseguimos cancelar o pedido agora. Tenta novamente.';
      default:
        return 'Nao conseguimos concluir a acao agora. Tenta novamente.';
    }
  }

  static String? _cancelledByLabel(String? value) {
    switch (value) {
      case 'cliente':
        return 'cliente';
      case 'prestador':
        return 'prestador';
      case 'sistema':
        return 'sistema';
      default:
        return null;
    }
  }
}
```

- [ ] **Step 4: Rodar teste especifico e confirmar passagem**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_flow_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Commit de checkpoint**

```powershell
git add lib/features/cliente/widgets/pedido_flow_presenter.dart `
  test/features/cliente/widgets/pedido_flow_presenter_test.dart
git commit -m "Adicionar presenter de fluxo beta web"
```

---

### Task 2: Pos-criacao e tela de aguardando prestador

**Files:**
- Modify: `lib/features/cliente/novo_pedido_screen.dart`
- Modify: `lib/features/cliente/aguardando_prestador_screen.dart`
- Test: `test/features/cliente/widgets/pedido_flow_presenter_test.dart`

- [ ] **Step 1: Importar presenter no novo pedido**

Em `lib/features/cliente/novo_pedido_screen.dart`, adicionar:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';
```

- [ ] **Step 2: Trocar feedback de pedido criado**

No ramo de criacao, substituir:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(l10n.orderCreatedSuccess)),
);
```

por:

```dart
final feedback = PedidoFlowPresenter.creationSuccess(manual: manual);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('${feedback.title}. ${feedback.message}'),
  ),
);
```

Manter a navegacao atual:

```text
manual -> PedidoDetalheScreen
automatico -> AguardandoPrestadorScreen
```

- [ ] **Step 3: Trocar erro bruto de criacao/edicao**

Substituir o `catch` que usa `l10n.orderCreateError(e.toString())` e
`l10n.orderUpdateError(e.toString())` por:

```dart
debugPrint('Erro ao salvar pedido: $e');
final feedback = PedidoFlowPresenter.creationError(editing: isEditing);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('${feedback.message} ${feedback.nextStep}'),
  ),
);
```

Manter `debugPrint` para diagnostico local e nao expor excecao ao utilizador.

- [ ] **Step 4: Humanizar loading/erro em `AguardandoPrestadorScreen`**

Adicionar imports:

```dart
import 'package:flutter/foundation.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';
```

Trocar loading:

```dart
return const Center(child: CircularProgressIndicator());
```

por:

```dart
return const AppLoadingView(label: 'A procurar o teu pedido...');
```

Trocar erro:

```dart
return Center(
  child: Text(
    'Erro a carregar pedido: ${snapshot.error}',
    textAlign: TextAlign.center,
  ),
);
```

por:

```dart
if (kDebugMode) {
  debugPrint('[AguardandoPrestador] stream error: ${snapshot.error}');
}
return const AppErrorView(
  message:
      'Nao conseguimos acompanhar este pedido agora. Tenta novamente daqui a pouco.',
);
```

- [ ] **Step 5: Humanizar pedido nao encontrado**

Substituir o `Center/Column` de pedido nulo por:

```dart
return PedidoEmptyState(
  title: 'Pedido nao encontrado',
  message:
      'Talvez este pedido tenha sido cancelado ou ainda nao esteja disponivel.',
  icon: Icons.search_off_rounded,
  actionLabel: 'Voltar',
  onAction: () => Navigator.of(context).pop(),
);
```

- [ ] **Step 6: Melhorar feedback quando prestador aceita**

Em `_irParaDetalhe`, trocar SnackBar por:

```dart
final feedback = PedidoFlowPresenter.creationSuccess(manual: false);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'Prestador encontrado. Abre o detalhe para combinar os proximos passos.',
    ),
  ),
);
```

Se `feedback` ficar sem uso, nao declarar. O texto deve ser curto e direto.

- [ ] **Step 7: Melhorar erro ao recriar pedido apos cancelamento do prestador**

No `catch` de `_recriarPedidoDepoisDeCancelamento`, trocar mensagem com `$e` por:

```dart
debugPrint('Erro ao recriar pedido depois de cancelamento: $e');
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text(
      'Nao conseguimos procurar outro prestador automaticamente. Tenta criar um novo pedido.',
    ),
  ),
);
```

- [ ] **Step 8: Rodar testes focados**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_flow_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 9: Commit de checkpoint**

```powershell
git add lib/features/cliente/novo_pedido_screen.dart `
  lib/features/cliente/aguardando_prestador_screen.dart
git commit -m "Melhorar pos-criacao e aguardando prestador"
```

---

### Task 3: UX das acoes do Cliente

**Files:**
- Modify: `lib/features/cliente/widgets/cliente_pedido_acoes.dart`
- Test: `test/features/cliente/widgets/pedido_flow_presenter_test.dart`

- [ ] **Step 1: Importar presenter**

Em `lib/features/cliente/widgets/cliente_pedido_acoes.dart`, adicionar:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';
```

- [ ] **Step 2: Aplicar copy de proposta no card de proposta**

No card de proposta, antes dos botoes, criar:

```dart
final copy = PedidoFlowPresenter.clientProposalCopy(pedido);
```

Trocar titulo/textos hardcoded da proposta para:

```dart
Text(
  copy.title,
  style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
  ),
),
const SizedBox(height: 6),
Text(
  copy.body,
  style: const TextStyle(fontSize: 12, color: Colors.black54),
),
```

Manter keys:

```text
cliente_rejeitar_proposta_button
cliente_aceitar_proposta_button
```

Trocar labels dos botoes por:

```dart
child: Text(copy.secondaryActionLabel!),
child: Text(copy.primaryActionLabel),
```

- [ ] **Step 3: Humanizar SnackBars de aceitar/rejeitar proposta**

Em `_aceitarPrestador`, trocar sucesso por:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(PedidoFlowPresenter.successMessage('acceptProposal')),
  ),
);
```

No catch:

```dart
debugPrint('Erro ao aceitar proposta: $e');
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(PedidoFlowPresenter.errorMessage('acceptProposal')),
  ),
);
```

Em `_recusarPrestador`, usar:

```dart
PedidoFlowPresenter.successMessage('rejectProposal')
PedidoFlowPresenter.errorMessage('rejectProposal')
```

- [ ] **Step 4: Aplicar copy de valor final pendente**

Em `_ValorFinalPendenteCard.build`, criar:

```dart
final copy = PedidoFlowPresenter.clientFinalValueCopy(pedido);
```

Trocar titulo por:

```dart
Text(
  copy.title,
  style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
  ),
),
```

Trocar texto explicativo final:

```dart
Text(
  copy.nextStep!,
  style: const TextStyle(
    fontSize: 12,
    color: Colors.black54,
  ),
),
```

Trocar labels dos botoes mantendo keys:

```dart
child: Text(copy.secondaryActionLabel!),
child: Text(copy.primaryActionLabel),
```

- [ ] **Step 5: Remover linguagem tecnica do valor final**

Remover texto visivel:

```text
backend conclui o pedido e calcula automaticamente comissao e ganhos
```

Substituir por:

```text
Ao confirmares, o pedido fica concluido. Se tiveres duvidas, fala com o prestador antes de confirmar.
```

Esta mensagem vem de `copy.nextStep`.

- [ ] **Step 6: Humanizar SnackBars de valor final**

Em `_confirmarValor`, usar:

```dart
PedidoFlowPresenter.successMessage('confirmFinalValue')
PedidoFlowPresenter.errorMessage('confirmFinalValue')
```

Em `_rejeitarValor`, usar:

```dart
PedidoFlowPresenter.successMessage('rejectFinalValue')
PedidoFlowPresenter.errorMessage('rejectFinalValue')
```

Manter `debugPrint` nos catches.

- [ ] **Step 7: Rodar testes focados**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_flow_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 8: Commit de checkpoint**

```powershell
git add lib/features/cliente/widgets/cliente_pedido_acoes.dart
git commit -m "Melhorar UX das acoes do cliente"
```

---

### Task 4: UX das acoes do Prestador

**Files:**
- Modify: `lib/features/prestador/widgets/prestador_pedido_acoes.dart`
- Test: `test/features/cliente/widgets/pedido_flow_presenter_test.dart`

- [ ] **Step 1: Importar presenter**

Em `lib/features/prestador/widgets/prestador_pedido_acoes.dart`, adicionar:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';
```

- [ ] **Step 2: Aplicar copy no convite direto**

Em `_AcaoResponderConvite.build`, criar:

```dart
final copy = PedidoFlowPresenter.providerInviteCopy(pedido);
```

Trocar texto:

```dart
Text(
  copy.body,
  style: const TextStyle(fontSize: 12, color: Colors.black54),
),
```

Trocar labels mantendo comportamento:

```dart
child: Text(copy.secondaryActionLabel!),
child: Text(copy.primaryActionLabel),
```

Trocar SnackBars:

```dart
PedidoFlowPresenter.successMessage('refuseInvite')
PedidoFlowPresenter.errorMessage('refuseInvite')
PedidoFlowPresenter.successMessage('acceptInvite')
PedidoFlowPresenter.errorMessage('acceptInvite')
```

Nos catches, adicionar:

```dart
debugPrint('Erro ao aceitar/recusar convite: $e');
```

- [ ] **Step 3: Melhorar copy de estimativa**

No dialog de `_AcaoEnviarOrcamento`, manter keys:

```text
prestador_enviar_orcamento_button
orcamento_min_field
orcamento_max_field
orcamento_msg_field
orcamento_enviar_button
```

Trocar sucesso por:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(PedidoFlowPresenter.successMessage('sendEstimate')),
  ),
);
```

Trocar erro por:

```dart
debugPrint('Erro ao enviar estimativa: $e');
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(PedidoFlowPresenter.errorMessage('sendEstimate')),
  ),
);
```

- [ ] **Step 4: Aplicar copy no inicio de servico**

Em `_AcaoIniciarServico.build`, criar:

```dart
final copy = PedidoFlowPresenter.providerStartCopy(pedido);
```

Manter a variacao agendada, mas trocar label do botao por:

```dart
label: Text(copy.primaryActionLabel),
```

Trocar sucesso por:

```dart
PedidoFlowPresenter.successMessage('startService')
```

Trocar catch bruto:

```dart
debugPrint('Erro ao iniciar servico: $e');
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(PedidoFlowPresenter.errorMessage('startService')),
  ),
);
```

- [ ] **Step 5: Aplicar copy no valor final**

Em `_AcaoLancarValorFinal._abrirDialogValorFinal`, criar antes do dialog:

```dart
final copy = PedidoFlowPresenter.providerFinalValueCopy(pedido);
```

Trocar titulo e body:

```dart
title: Text(copy.title),
...
Text(
  copy.body,
  style: const TextStyle(fontSize: 12, color: Colors.black54),
),
```

Trocar label do botao mantendo key:

```dart
child: Text(copy.primaryActionLabel),
```

Trocar sucesso/erro por:

```dart
PedidoFlowPresenter.successMessage('sendFinalValue')
PedidoFlowPresenter.errorMessage('sendFinalValue')
```

- [ ] **Step 6: Acrescentar estado de aguardando cliente se aplicavel**

Se `PrestadorPedidoAcoes` ja renderiza `_AcaoAguardandoRespostaCliente` para
`aguarda_confirmacao_valor`, trocar texto por:

```dart
final copy = PedidoFlowPresenter.providerWaitingClientCopy(pedido);
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      copy.title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    Text(
      copy.body,
      style: const TextStyle(fontSize: 12, color: Colors.black54),
    ),
    if (copy.nextStep != null) ...[
      const SizedBox(height: 4),
      Text(
        copy.nextStep!,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ],
  ],
);
```

- [ ] **Step 7: Rodar testes focados**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_flow_presenter_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 8: Commit de checkpoint**

```powershell
git add lib/features/prestador/widgets/prestador_pedido_acoes.dart
git commit -m "Melhorar UX das acoes do prestador"
```

---

### Task 5: Painel de estado final no detalhe

**Files:**
- Create: `lib/features/cliente/widgets/pedido_final_state_panel.dart`
- Modify: `lib/features/cliente/pedido_detalhe_screen.dart`
- Test: `test/features/cliente/widgets/pedido_final_state_panel_test.dart`

- [ ] **Step 1: Criar teste falhando para painel final**

Criar `test/features/cliente/widgets/pedido_final_state_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_final_state_panel.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';

void main() {
  testWidgets('PedidoFinalStatePanel mostra estado concluido', (tester) async {
    const data = PedidoFinalStateData(
      title: 'Pedido concluido',
      message: 'O servico ficou concluido.',
      actionHint: 'Consulta os detalhes sempre que precisares.',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PedidoFinalStatePanel(data: data),
        ),
      ),
    );

    expect(find.text('Pedido concluido'), findsOneWidget);
    expect(find.text('O servico ficou concluido.'), findsOneWidget);
    expect(
      find.text('Consulta os detalhes sempre que precisares.'),
      findsOneWidget,
    );
  });

  testWidgets('PedidoFinalStatePanel mostra detalhe de cancelamento', (
    tester,
  ) async {
    const data = PedidoFinalStateData(
      title: 'Pedido cancelado',
      message: 'Este pedido foi cancelado pelo prestador.',
      detail: 'Motivo: Agenda indisponivel',
      actionHint: 'Consulta os detalhes ou cria um novo pedido.',
      icon: Icons.cancel_outlined,
      color: Colors.redAccent,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PedidoFinalStatePanel(data: data),
        ),
      ),
    );

    expect(find.text('Pedido cancelado'), findsOneWidget);
    expect(
      find.text('Este pedido foi cancelado pelo prestador.'),
      findsOneWidget,
    );
    expect(find.text('Motivo: Agenda indisponivel'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar teste e confirmar falha**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_final_state_panel_test.dart
```

Expected:

```text
Error: Error when reading ... pedido_final_state_panel.dart
```

- [ ] **Step 3: Criar widget `PedidoFinalStatePanel`**

Criar `lib/features/cliente/widgets/pedido_final_state_panel.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';

class PedidoFinalStatePanel extends StatelessWidget {
  final PedidoFinalStateData data;

  const PedidoFinalStatePanel({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(data.icon, color: data.color),
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
                  data.message,
                  style: theme.textTheme.bodyMedium,
                ),
                if (data.detail != null) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    data.detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x2),
                Text(
                  data.actionHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

- [ ] **Step 4: Integrar no detalhe do pedido**

Em `lib/features/cliente/pedido_detalhe_screen.dart`, importar:

```dart
import 'package:chegaja_v2/features/cliente/widgets/pedido_final_state_panel.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';
```

Depois de `PedidoTimeline(estado: pedido.estado)`, adicionar:

```dart
if (pedido.estado == 'concluido' || pedido.estado == 'cancelado') ...[
  const SizedBox(height: 12),
  PedidoFinalStatePanel(
    data: PedidoFlowPresenter.finalStateFor(pedido),
  ),
],
```

- [ ] **Step 5: Humanizar erros brutos restantes no detalhe ligados ao fluxo**

Trocar catches com textos:

```text
Erro ao enviar convite: $e
orderCancelError(e.toString())
cancelJobError(e.toString())
orderFinalValueSendError(e.toString())
```

por mensagens humanas e `debugPrint`, por exemplo:

```dart
debugPrint('Erro ao enviar convite ao prestador: $e');
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Nao conseguimos enviar o convite agora. Tenta novamente.'),
  ),
);
```

Para cancelamento:

```dart
debugPrint('Erro ao cancelar pedido: $e');
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(PedidoFlowPresenter.errorMessage('cancelOrder')),
  ),
);
```

Para valor final proposto no detalhe:

```dart
PedidoFlowPresenter.errorMessage('sendFinalValue')
```

- [ ] **Step 6: Rodar testes do painel**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_final_state_panel_test.dart
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
git add lib/features/cliente/widgets/pedido_final_state_panel.dart `
  lib/features/cliente/pedido_detalhe_screen.dart `
  test/features/cliente/widgets/pedido_final_state_panel_test.dart
git commit -m "Melhorar estados finais no detalhe do pedido"
```

---

### Task 6: Consistencia, limpeza e validacao M2.9.3

**Files:**
- Modify: `docs/M2_9_BETA_WEB_STATUS.md`
- Modify: ficheiros Flutter tocados nas tarefas anteriores apenas para limpeza de imports/formatacao

- [ ] **Step 1: Verificar que nao ha backend alterado**

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
sem .env
sem keystore
```

- [ ] **Step 2: Confirmar keys de fluxo preservadas**

Run:

```powershell
rg "cliente_rejeitar_proposta_button|cliente_aceitar_proposta_button|cliente_duvida_valor_button|confirmar_valor_button|prestador_enviar_orcamento_button|orcamento_min_field|orcamento_max_field|orcamento_msg_field|orcamento_enviar_button|prestador_iniciar_servico_button|valor_final_field|prestador_enviar_valor_final_button" lib test
```

Expected:

```text
Todas as keys existentes continuam presentes nos ficheiros Flutter.
```

- [ ] **Step 3: Procurar excecoes brutas em textos de fluxo alterados**

Run:

```powershell
rg -n "Erro ao aceitar prestador: \\$e|Erro ao rejeitar proposta: \\$e|Erro ao aceitar: \\$e|Erro ao recusar: \\$e|Erro ao iniciar servi|Erro a carregar pedido: \\$\\{snapshot.error\\}|orderCreateError\\(e\\.toString\\(\\)\\)|orderUpdateError\\(e\\.toString\\(\\)\\)" lib/features/cliente lib/features/prestador
```

Expected:

```text
0 matches para os fluxos tocados pela M2.9.3.
```

Se ainda houver matches dentro do escopo, trocar por mensagem humana + `debugPrint`.
Se houver matches fora do escopo direto, documentar para fase futura e nao abrir refatoracao ampla.

- [ ] **Step 4: Formatar Dart**

Run:

```powershell
dart format lib/features/cliente/widgets/pedido_flow_presenter.dart `
  lib/features/cliente/widgets/pedido_final_state_panel.dart `
  lib/features/cliente/novo_pedido_screen.dart `
  lib/features/cliente/aguardando_prestador_screen.dart `
  lib/features/cliente/pedido_detalhe_screen.dart `
  lib/features/cliente/widgets/cliente_pedido_acoes.dart `
  lib/features/prestador/widgets/prestador_pedido_acoes.dart `
  test/features/cliente/widgets/pedido_flow_presenter_test.dart `
  test/features/cliente/widgets/pedido_final_state_panel_test.dart
```

Expected:

```text
Formatted ... files
```

- [ ] **Step 5: Atualizar status M2.9**

Em `docs/M2_9_BETA_WEB_STATUS.md`, trocar:

```text
M2.9.3: iniciado em beta web flow pack
```

por:

```text
M2.9.3: avancado em beta web flow pack
```

Adicionar evidencia:

```markdown
Escopo implementado:

```text
feedback pos-criacao de pedido
aguardando prestador com loading/erro humano
UX Cliente para proposta e valor final
UX Prestador para convite, estimativa, inicio e valor final
painel de estados finais no detalhe
mensagens de erro sem excecao bruta nos fluxos alterados
keys de fluxo preservadas
```

Arquivos principais:

```text
lib/features/cliente/widgets/pedido_flow_presenter.dart
lib/features/cliente/widgets/pedido_final_state_panel.dart
lib/features/cliente/novo_pedido_screen.dart
lib/features/cliente/aguardando_prestador_screen.dart
lib/features/cliente/pedido_detalhe_screen.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
test/features/cliente/widgets/pedido_flow_presenter_test.dart
test/features/cliente/widgets/pedido_final_state_panel_test.dart
```

Evidencia M2.9.3:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
```

- [ ] **Step 6: Rodar validacoes finais**

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

- [ ] **Step 7: Verificar staged scope antes do commit**

Run:

```powershell
git status --short
git diff --check
git diff --name-status
git diff --cached --name-status
```

Expected:

```text
sem key.properties staged
sem keystore staged
sem .env staged
sem functions/ staged
sem firestore.rules staged
sem storage.rules staged
sem firebase.json staged
as duas delecoes antigas dos ficheiros ~$...pptx continuam fora do stage
```

- [ ] **Step 8: Commit final da implementacao**

Stage apenas ficheiros da M2.9.3:

```powershell
git add lib/features/cliente/widgets/pedido_flow_presenter.dart `
  lib/features/cliente/widgets/pedido_final_state_panel.dart `
  lib/features/cliente/novo_pedido_screen.dart `
  lib/features/cliente/aguardando_prestador_screen.dart `
  lib/features/cliente/pedido_detalhe_screen.dart `
  lib/features/cliente/widgets/cliente_pedido_acoes.dart `
  lib/features/prestador/widgets/prestador_pedido_acoes.dart `
  test/features/cliente/widgets/pedido_flow_presenter_test.dart `
  test/features/cliente/widgets/pedido_final_state_panel_test.dart `
  docs/M2_9_BETA_WEB_STATUS.md
git commit -m "Avancar M2.9.3 beta web flow pack"
```

- [ ] **Step 9: Push**

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

- Spec coverage: o plano cobre feedback pos-criacao, aguardando prestador, Cliente aceitar/rejeitar proposta, Cliente confirmar/rejeitar valor final, Prestador aceitar/recusar convite, iniciar servico, enviar estimativa, enviar valor final, conclusao/cancelamento, navegacao orientada, consistencia lista/detalhe, testes, docs e validacoes.
- Scope check: nao inclui backend, Firestore Rules, Storage Rules, Cloud Functions, deploy, smoke real, cleanup real, health real, Android fisico, pagamentos, Play Store, package id, HTTPS App Links ou fecho da M2.6.
- Type consistency: `PedidoFlowPresenter` define `PedidoFlowFeedback`, `PedidoFlowActionCopy` e `PedidoFinalStateData`; `PedidoFinalStatePanel` consome `PedidoFinalStateData`; actions usam `successMessage` e `errorMessage`.
- Risk control: o plano preserva keys existentes de Cliente/Prestador, mantem services atuais e substitui excecoes brutas por `debugPrint` + mensagem humana apenas nos fluxos tocados.
