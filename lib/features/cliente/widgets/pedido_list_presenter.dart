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

    if (role == PedidoViewerRole.prestador && pedido.estado == 'em_andamento') {
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
