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
      return PedidoStatusSummaryData(
        title: role == PedidoViewerRole.cliente
            ? 'Confirma o valor final'
            : 'A aguardar confirmacao',
        description: role == PedidoViewerRole.cliente
            ? 'O prestador terminou o servico e enviou o valor final.'
            : 'O valor final foi enviado ao cliente para confirmacao.',
        actor: role == PedidoViewerRole.cliente
            ? 'Acao do cliente'
            : 'Acao do cliente',
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

    if (pedido.estado == 'aguarda_resposta_cliente' ||
        pedido.statusProposta == 'pendente_cliente') {
      return PedidoStatusSummaryData(
        title: role == PedidoViewerRole.cliente
            ? 'Proposta para rever'
            : 'Proposta enviada',
        description: role == PedidoViewerRole.cliente
            ? 'O prestador enviou uma estimativa para o servico.'
            : 'A estimativa foi enviada ao cliente.',
        actor: role == PedidoViewerRole.cliente
            ? 'Acao do cliente'
            : 'A aguardar cliente',
        tone: PedidoStatusTone.warning,
        icon: Icons.request_quote_rounded,
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
      if (role == PedidoViewerRole.prestador &&
          pedido.tipoPreco == 'por_orcamento' &&
          pedido.statusProposta != 'aceita_cliente') {
        return const PedidoStatusSummaryData(
          title: 'Enviar estimativa',
          description: 'O cliente precisa de uma faixa antes de decidir.',
          actor: 'Acao do prestador',
          tone: PedidoStatusTone.warning,
          icon: Icons.request_quote_rounded,
        );
      }
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
        nextStep:
            'Podes consultar o historico e criar outro pedido se precisares.',
        hasUserAction: false,
      );
    }

    if (pedido.estado == 'concluido') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description:
            'Pedido concluido. Podes consultar os detalhes deste servico.',
        nextStep: 'Nao ha acoes obrigatorias neste pedido.',
        hasUserAction: false,
      );
    }

    if (pedido.statusConfirmacaoValor == 'pendente_cliente' ||
        pedido.estado == 'aguarda_confirmacao_valor') {
      if (role == PedidoViewerRole.cliente) {
        return const PedidoNextActionData(
          title: 'Proxima acao',
          description: 'Reve e confirma o valor final enviado pelo prestador.',
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
        description: 'Reve a estimativa do prestador antes de escolher.',
        nextStep: 'Se aceitares, o pedido avanca para servico aceite.',
        hasUserAction: true,
      );
    }

    if (role == PedidoViewerRole.prestador &&
        pedido.estado == 'aguarda_resposta_cliente') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Aguarda a resposta do cliente a estimativa enviada.',
        nextStep: 'Se o cliente aceitar, podes combinar e iniciar o servico.',
        hasUserAction: false,
      );
    }

    if (role == PedidoViewerRole.prestador && pedido.estado == 'em_andamento') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Quando terminares o trabalho, envia o valor final.',
        nextStep:
            'O cliente tera de confirmar esse valor para concluir o pedido.',
        hasUserAction: true,
      );
    }

    if (role == PedidoViewerRole.prestador &&
        pedido.estado == 'aceito' &&
        pedido.tipoPreco == 'por_orcamento' &&
        pedido.statusProposta != 'aceita_cliente') {
      return const PedidoNextActionData(
        title: 'Proxima acao',
        description: 'Envia uma faixa estimada para o cliente decidir.',
        nextStep:
            'A faixa nao e o valor final; o valor final vem depois do servico.',
        hasUserAction: true,
      );
    }

    if (pedido.estado == 'aceito') {
      return PedidoNextActionData(
        title: 'Proxima acao',
        description: role == PedidoViewerRole.prestador
            ? 'Inicia o servico quando estiveres no local ou na hora combinada.'
            : 'Combina os detalhes com o prestador antes do inicio.',
        nextStep: 'Depois do inicio, o pedido passa para em andamento.',
        hasUserAction: role == PedidoViewerRole.prestador,
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
      nextStep:
          'As acoes disponiveis aparecem abaixo quando forem necessarias.',
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
