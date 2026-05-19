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
        message: 'O pedido foi criado e enviado ao prestador escolhido por ti.',
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
      title: 'Reve a proposta',
      body:
          'O prestador respondeu ao teu pedido. Confirma se queres avancar com este prestador ou rejeita para continuar a procurar.',
      primaryActionLabel: 'Aceitar este prestador',
      secondaryActionLabel: 'Rejeitar proposta',
      nextStep:
          'Se aceitares, o pedido avanca para combinarem e iniciarem o servico.',
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
      nextStep:
          'Depois de iniciares, poderas enviar o valor final quando terminares.',
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
      final reason = pedido.motivoCancelamento?.trim();
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
