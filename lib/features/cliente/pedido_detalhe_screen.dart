// lib/features/cliente/pedido_detalhe_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/features/prestador/widgets/prestador_pedido_acoes.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/chat_message.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/avaliacao_service.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/core/services/politica_reembolso.dart';
import 'package:chegaja_v2/core/utils/cancelamento_motivos.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';
import 'package:chegaja_v2/features/common/mensagens/widgets/chat_audio_player.dart';
import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/aguardando_prestador_screen.dart';
import 'package:chegaja_v2/features/cliente/selecionar_prestador_screen.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_pedido_acoes.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class PedidoDetalheScreen extends StatelessWidget {
  final String pedidoId;
  final bool isCliente;

  const PedidoDetalheScreen({
    super.key,
    required this.pedidoId,
    this.isCliente = true,
  });

  String _labelEstado(Pedido pedido, AppLocalizations l10n) {
    if (pedido.estado == 'cancelado') {
      if (pedido.canceladoPor == 'cliente') {
        return l10n.statusCancelledByYou;
      }
      if (pedido.canceladoPor == 'prestador') {
        return l10n.statusCancelledByProvider;
      }
      return l10n.statusCancelled;
    }

    switch (pedido.estado) {
      case 'criado':
        return l10n.statusLookingForProvider;
      case 'aguarda_resposta_prestador':
        return 'Aguardando resposta do prestador';
      case 'aguarda_resposta_cliente':
        return l10n.statusQuoteToDecide;
      case 'aceito':
        if (isCliente &&
            pedido.tipoPreco == 'por_orcamento' &&
            pedido.statusProposta == 'nenhuma') {
          return l10n.statusProviderPreparingQuote;
        }
        return l10n.statusProviderFound;
      case 'em_andamento':
        return l10n.statusServiceInProgress;
      case 'aguarda_confirmacao_valor':
        return l10n.statusAwaitingValueConfirmation;
      case 'concluido':
        return l10n.statusServiceCompleted;
      default:
        return pedido.estado;
    }
  }

  String _buildValorLabel(
    Pedido pedido,
    AppLocalizations l10n,
    NumberFormat currencyFormat,
  ) {
    if (pedido.precoFinal != null &&
        pedido.statusConfirmacaoValor == 'confirmado_cliente') {
      return currencyFormat.format(pedido.precoFinal);
    }

    if (pedido.precoPropostoPrestador != null &&
        pedido.statusConfirmacaoValor == 'pendente_cliente') {
      return l10n.valueToConfirm(
        currencyFormat.format(pedido.precoPropostoPrestador),
      );
    }

    if (pedido.precoFinal != null) {
      return currencyFormat.format(pedido.precoFinal);
    }

    if (pedido.precoPropostoPrestador != null) {
      return l10n.valueProposed(
        currencyFormat.format(pedido.precoPropostoPrestador),
      );
    }

    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;

    if (min != null && max != null) {
      return l10n.valueEstimatedRange(
        currencyFormat.format(min),
        currencyFormat.format(max),
      );
    }
    if (min != null) {
      return l10n.valueEstimatedFrom(
        currencyFormat.format(min),
      );
    }
    if (max != null) {
      return l10n.valueEstimatedUpTo(
        currencyFormat.format(max),
      );
    }

    return l10n.valueUnknown;
  }

  String _resolvePhone(Map<String, dynamic> data) {
    final phone = (data['phoneE164'] ?? data['phoneNumber'] ?? data['phone'] ?? '')
        .toString()
        .trim();
    if (phone.isNotEmpty) return phone;
    return (data['phoneRaw'] ?? '').toString().trim();
  }

  Future<void> _openPhone(String phone) async {
    final uri = Uri.tryParse('tel:$phone');
    if (uri == null) return;
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;
    final df = DateFormat('dd/MM/yyyy HH:mm', localeName);
    final currencyFormat = NumberFormat.simpleCurrency(locale: localeName);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetailsTitle),
      ),
      body: SafeArea(
        child: StreamBuilder<Pedido?>(
          stream: PedidosRepo.streamPedidoPorId(pedidoId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  l10n.orderLoadError(snapshot.error.toString()),
                ),
              );
            }

            final pedido = snapshot.data;

            if (pedido == null) {
              return Center(
                child: Text(l10n.orderNotFound),
              );
            }

            final isAgendado = pedido.modo == 'AGENDADO';
            final categoria = pedido.categoria ?? l10n.categoryNotDefined;
            final desc = pedido.descricao.trim();
            final temDescricao = desc.isNotEmpty;

            final mensagemProposta = pedido.mensagemPropostaPrestador?.trim();
            final temMensagemProposta =
                mensagemProposta != null && mensagemProposta.isNotEmpty;

            String subtituloModo;
            if (isAgendado && pedido.agendadoPara != null) {
              subtituloModo = l10n.scheduledForDate(
                df.format(pedido.agendadoPara!),
              );
            } else if (isAgendado) {
              subtituloModo = l10n.scheduledNoDate;
            } else {
              subtituloModo = l10n.orderImmediate;
            }

            final estadoLabel = _labelEstado(pedido, l10n);
            final valorLabel = _buildValorLabel(
              pedido,
              l10n,
              currencyFormat,
            );

            final bool estaProcurandoPrestador =
                (pedido.estado == 'criado' ||
                        pedido.estado == 'aguarda_resposta_cliente') &&
                    pedido.prestadorId == null;
            final bool aguardandoRespostaPrestador = isCliente &&
                pedido.estado == 'aguarda_resposta_prestador' &&
                pedido.prestadorId != null;
            final bool podeEscolherManual = isCliente &&
                pedido.estado == 'criado' &&
                pedido.prestadorId == null;

            final podeEditar = isCliente && pedido.estado == 'criado';
            final podeCancelar = isCliente &&
                pedido.estado != 'concluido' &&
                pedido.estado != 'cancelado';
            final clienteId = AuthService.currentUser?.uid;
            final podeAvaliar = isCliente &&
                pedido.estado == 'concluido' &&
                pedido.prestadorId != null &&
                clienteId != null;
            final isClienteViewer =
                isCliente && clienteId != null && clienteId == pedido.clienteId;
            final isPrestadorViewer = !isCliente &&
                AuthService.currentUser?.uid == pedido.prestadorId;
            final String? noShowRole =
                isClienteViewer ? 'cliente' : (isPrestadorViewer ? 'prestador' : null);
            final bool hasNoShow = pedido.noShowReportedBy != null;
            final bool podeReportarNoShow = !hasNoShow &&
                pedido.prestadorId != null &&
                noShowRole != null &&
                (pedido.estado == 'aceito' ||
                    pedido.estado == 'em_andamento' ||
                    pedido.estado == 'aguarda_confirmacao_valor');
            final noShowReason = pedido.noShowReason?.trim();
            final noShowAt = pedido.noShowAt;
            final noShowReporterLabel = pedido.noShowReportedBy == 'cliente'
                ? l10n.roleLabelCustomer
                : l10n.roleLabelProvider;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.assignment_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pedido.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              categoria,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtituloModo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          estadoLabel,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _PedidoTimeline(estado: pedido.estado),
                  const SizedBox(height: 12),

                  if (aguardandoRespostaPrestador) ...[
                    _BannerAcaoPrestador(
                      icon: Icons.mark_chat_unread,
                      texto: 'Convite enviado ao prestador. Aguardando resposta.',
                      botao: 'Trocar',
                      onPressed: () =>
                          _trocarPrestadorManual(context, pedido),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (podeEscolherManual) ...[
                    _BannerAcaoPrestador(
                      icon: Icons.search,
                      texto: 'Queres escolher um prestador manualmente?',
                      botao: 'Selecionar',
                      onPressed: () =>
                          _trocarPrestadorManual(context, pedido),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (estaProcurandoPrestador) ...[
                    _BannerAguardandoPrestador(pedidoId: pedido.id),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  // ACOES DO CLIENTE (aceitar prestador / confirmar valor)
                  if (isCliente) ...[
                    ClientePedidoAcoes(pedido: pedido),
                    const SizedBox(height: 16),
                  ],

                  // ACOES DO PRESTADOR (iniciar / concluir / cancelar / renegociacao de valor)
                  if (!isCliente &&
                      AuthService.currentUser?.uid == pedido.prestadorId) ...[
                    PrestadorPedidoAcoes(pedido: pedido),
                    if (pedido.statusConfirmacaoValor ==
                        'rejeitado_cliente') ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.orderValueRejectedTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.orderValueRejectedBody,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _abrirDialogNovoValor(context, pedido),
                                child: Text(l10n.actionProposeNewValue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (pedido.estado != 'aguarda_resposta_prestador') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          onPressed: () =>
                              _cancelarTrabalhoPorPrestador(context, pedido),
                          child: Text(l10n.cancelJobTitle),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  if (podeAvaliar) ...[
                    _AvaliacaoPedidoCard(
                      pedidoId: pedido.id,
                      prestadorId: pedido.prestadorId!,
                      clienteId: clienteId,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (hasNoShow) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.noShowReportedTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.noShowReportedBy(noShowReporterLabel),
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (noShowAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.noShowReportedAt(df.format(noShowAt)),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          if (noShowReason != null &&
                              noShowReason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              noShowReason,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (podeReportarNoShow) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.noShowTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.noShowDescription,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _reportarNoShow(
                                context,
                                pedido,
                                noShowRole,
                              ),
                              icon:
                                  const Icon(Icons.report_gmailerrorred_outlined),
                              label: Text(l10n.noShowReportAction),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    l10n.orderInfoTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l10n.orderInfoIdLabel,
                    value: pedido.id,
                  ),
                  _InfoRow(
                    label: l10n.orderInfoCreatedAtLabel,
                    value: df.format(pedido.createdAt),
                  ),
                  _InfoRow(
                    label: l10n.orderInfoStatusLabel,
                    value: estadoLabel,
                  ),
                  _InfoRow(
                    label: l10n.orderInfoModeLabel,
                    value: pedido.modo,
                  ),
                  _InfoRow(
                    label: l10n.orderInfoValueLabel,
                    value: valorLabel,
                  ),
                  const SizedBox(height: 16),

                  _ContatoSection(
                    pedido: pedido,
                    isCliente: isCliente,
                    resolvePhone: _resolvePhone,
                    onCall: _openPhone,
                  ),
                  const SizedBox(height: 16),

                  // MAPA DO PEDIDO (preview + tap -> fullscreen)
                  Text(
                    l10n.orderLocationTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ð Morada textual (se existir)
                  if (pedido.enderecoTexto?.trim().isNotEmpty ?? false) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pedido.enderecoTexto!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  PedidoMapaCard(
                    pedido: pedido,
                    isCliente: isCliente,
                  ),
                  const SizedBox(height: 16),

                  if (temDescricao) ...[
                    Text(
                      l10n.orderDescriptionTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        desc,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (temMensagemProposta) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.providerMessageTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mensagemProposta,
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // CHAT (cartão que abre/fecha o chat)
                  _ChatExpandable(
                    pedidoId: pedido.id,
                    isCliente: isCliente,
                    otherUserId: isCliente ? pedido.prestadorId : pedido.clienteId,
                    pedidoTitulo: pedido.titulo,
                  ),
                  const SizedBox(height: 16),

                  if (podeEditar || podeCancelar) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  if (podeEditar) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _editarPedido(context, pedido),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l10n.actionEditOrder),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (podeCancelar) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () => _cancelarPedido(context, pedido),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 18,
                        ),
                        label: Text(l10n.actionCancelOrder),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _trocarPrestadorManual(
    BuildContext context,
    Pedido pedido,
  ) async {
    if (!isCliente) return;

    final servicoId =
        pedido.servicoId.isNotEmpty ? pedido.servicoId : null;

    final selecionado = await Navigator.of(context)
        .push<PrestadorSelecionado>(
      MaterialPageRoute(
        builder: (_) => SelecionarPrestadorScreen(
          servicoId: servicoId,
          servicoNome: pedido.categoria,
          latitude: pedido.latitude,
          longitude: pedido.longitude,
        ),
      ),
    );

    if (selecionado == null) return;

    try {
      await PedidoService.instance.convidarPrestadorManual(
        pedido: pedido,
        prestadorId: selecionado.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convite enviado ao prestador.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar convite: $e')),
        );
      }
    }
  }

  Future<void> _editarPedido(BuildContext context, Pedido pedido) async {
    final user = AuthService.currentUser;
    if (user == null || !isCliente) return;
    if (user.uid != pedido.clienteId) return;
    if (pedido.estado != 'criado') return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NovoPedidoScreen(
          modo: pedido.modo,
          pedidoInicial: pedido,
        ),
      ),
    );
  }

  Future<void> _cancelarPedido(BuildContext context, Pedido pedido) async {
    final user = AuthService.currentUser;
    if (user == null || !isCliente) return;
    if (user.uid != pedido.clienteId) return;
    if (pedido.estado == 'concluido' || pedido.estado == 'cancelado') return;
    final l10n = AppLocalizations.of(context)!;

    final estaEmServico =
        pedido.estado == 'em_andamento' ||
            pedido.estado == 'aguarda_confirmacao_valor';

    final motivos = CancelamentoMotivos.forCliente(emServico: estaEmServico);
    CancelamentoMotivoOption selectedMotivo = motivos.first;
    final detalheController = TextEditingController();
    String? detalheError;

    final previewInfo = PoliticaReembolso.calcularParaCancelamentoCliente(
      pedido,
      DateTime.now(),
    );

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final precisaDetalhe = selectedMotivo.requiresDetail;
            return AlertDialog(
              title: Text(l10n.cancelOrderTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    previewInfo.mensagemDetalhada,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (estaEmServico) ...[
                    Text(
                      l10n.orderCancelInProgressWarning,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    Text(
                      l10n.orderCancelConfirmPrompt,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<CancelamentoMotivoOption>(
                    initialValue: selectedMotivo,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: estaEmServico
                          ? l10n.orderCancelReasonLabel
                          : l10n.orderCancelReasonOptionalLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final motivo in motivos)
                        DropdownMenuItem(
                          value: motivo,
                          child: Text(motivo.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedMotivo = value;
                        detalheError = null;
                      });
                    },
                  ),
                  if (precisaDetalhe) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: detalheController,
                      maxLines: 3,
                      onChanged: (_) {
                        if (detalheError == null) return;
                        setState(() => detalheError = null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Detalhe do motivo',
                        border: const OutlineInputBorder(),
                        errorText: detalheError,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.actionNo),
                ),
                TextButton(
                  onPressed: () {
                    if (precisaDetalhe &&
                        detalheController.text.trim().isEmpty) {
                      setState(() {
                        detalheError = 'Informe um detalhe.';
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(l10n.actionYesCancel),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar != true) return;

    final motivo = selectedMotivo.id;
    final motivoDetalhe = detalheController.text.trim();
    final motivoDetalheFinal =
        motivoDetalhe.isEmpty ? null : motivoDetalhe;

    final info = PoliticaReembolso.calcularParaCancelamentoCliente(
      pedido,
      DateTime.now(),
    );

    try {
      await PedidoService.instance.cancelarPorCliente(
        pedido: pedido,
        motivo: motivo,
        motivoDetalhe: motivoDetalheFinal,
        motivoIsId: true,
        tipoReembolso: PoliticaReembolso.tipoToString(info.tipo),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderCancelledSnack(info.mensagemCurta)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderCancelError(e.toString())),
        ),
      );
    }
  }

  Future<void> _reportarNoShow(
    BuildContext context,
    Pedido pedido,
    String role,
  ) async {
    final user = AuthService.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) return;
    if (role == 'cliente' && user.uid != pedido.clienteId) return;
    if (role == 'prestador' && user.uid != pedido.prestadorId) return;
    if (pedido.noShowReportedBy != null) return;

    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.noShowReportDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.noShowReportDialogDescription,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motivoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.noShowReasonOptionalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.actionReport),
            ),
          ],
        );
      },
    );

    final motivo = motivoController.text.trim();
    motivoController.dispose();

    if (confirmar != true) return;

    try {
      await PedidoService.instance.reportNoShow(
        pedido: pedido,
        reporterRole: role,
        motivo: motivo,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noShowReportSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noShowReportError(e.toString())),
        ),
      );
    }
  }

  Future<void> _cancelarTrabalhoPorPrestador(
    BuildContext context,
    Pedido pedido,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final emServico =
        pedido.estado == 'em_andamento' ||
            pedido.estado == 'aguarda_confirmacao_valor';
    final motivos = CancelamentoMotivos.forPrestador(emServico: emServico);
    CancelamentoMotivoOption selectedMotivo = motivos.first;
    final detalheController = TextEditingController();
    String? detalheError;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final precisaDetalhe = selectedMotivo.requiresDetail;
            return AlertDialog(
              title: Text(l10n.cancelJobTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cancelJobPrompt,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CancelamentoMotivoOption>(
                    initialValue: selectedMotivo,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.cancelJobReasonLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final motivo in motivos)
                        DropdownMenuItem(
                          value: motivo,
                          child: Text(motivo.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedMotivo = value;
                        detalheError = null;
                      });
                    },
                  ),
                  if (precisaDetalhe) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: detalheController,
                      maxLines: 3,
                      onChanged: (_) {
                        if (detalheError == null) return;
                        setState(() => detalheError = null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Detalhe do motivo',
                        border: const OutlineInputBorder(),
                        errorText: detalheError,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.actionNo),
                ),
                TextButton(
                  onPressed: () {
                    if (precisaDetalhe &&
                        detalheController.text.trim().isEmpty) {
                      setState(() {
                        detalheError = 'Informe um detalhe.';
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(l10n.actionYesCancel),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar != true) return;

    final motivo = selectedMotivo.id;
    final motivoDetalhe = detalheController.text.trim();
    final motivoDetalheFinal =
        motivoDetalhe.isEmpty ? null : motivoDetalhe;

    try {
      await PedidoService.instance.cancelarPorPrestador(
        pedido: pedido,
        motivo: motivo,
        motivoDetalhe: motivoDetalheFinal,
        motivoIsId: true,
        tipoReembolso: 'nenhum',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cancelJobSuccess),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cancelJobError(e.toString())),
        ),
      );
    }
  }

  void _abrirDialogNovoValor(BuildContext context, Pedido pedido) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat =
        NumberFormat.simpleCurrency(locale: l10n.localeName);
    final currencySymbol = currencyFormat.currencySymbol;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.orderFinalValueTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.orderFinalValueLabel,
              prefixText: '$currencySymbol ',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              child: Text(l10n.actionSend),
              onPressed: () async {
                final texto =
                    controller.text.replaceAll(',', '.').trim();
                final valor = double.tryParse(texto);

                if (valor == null || valor <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(l10n.orderFinalValueInvalid),
                    ),
                  );
                  return;
                }

                try {
                  await PedidoService.instance.proporValorFinal(
                    pedido: pedido,
                    valorFinal: valor,
                  );

                  if (!context.mounted) return;
                  Navigator.of(ctx).pop();

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.orderFinalValueSent),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.orderFinalValueSendError(e.toString()),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _AvaliacaoPedidoCard extends StatefulWidget {
  final String pedidoId;
  final String prestadorId;
  final String clienteId;

  const _AvaliacaoPedidoCard({
    required this.pedidoId,
    required this.prestadorId,
    required this.clienteId,
  });

  @override
  State<_AvaliacaoPedidoCard> createState() => _AvaliacaoPedidoCardState();
}

class _AvaliacaoPedidoCardState extends State<_AvaliacaoPedidoCard> {
  final TextEditingController _comentarioCtrl = TextEditingController();
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docId = '${widget.pedidoId}_${widget.clienteId}';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('avaliacoes')
          .doc(docId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final hasData = snap.data?.exists == true && data != null;

        if (hasData) {
          final estrelasRaw = data['estrelas'] ?? data['rating'] ?? 0;
          final int estrelas = (estrelasRaw is num) ? estrelasRaw.toInt() : 0;
          final String comentario =
              (data['comentario'] ?? '').toString().trim();

          return _avaliacaoResumo(
            estrelas: estrelas,
            comentario: comentario,
          );
        }

        return _avaliacaoForm();
      },
    );
  }

  Widget _avaliacaoResumo({
    required int estrelas,
    required String comentario,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ratingSentTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _starRow(estrelas, readOnly: true),
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comentario,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avaliacaoForm() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ratingProviderTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ratingPrompt,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          _starRow(_rating, readOnly: false),
          const SizedBox(height: 8),
          TextField(
            controller: _comentarioCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.ratingCommentLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _enviar,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.ratingSendAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starRow(int value, {required bool readOnly}) {
    final stars = List<Widget>.generate(5, (index) {
      final int starValue = index + 1;
      final bool selected = value >= starValue;

      return IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(
          selected ? Icons.star : Icons.star_border,
          color: selected ? Colors.amber[700] : Colors.grey,
        ),
        onPressed: readOnly || _sending
            ? null
            : () {
                setState(() => _rating = starValue);
              },
      );
    });

    return Row(children: stars);
  }

  Future<void> _enviar() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingSelectError)),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await AvaliacaoService.instance.enviarAvaliacao(
        pedidoId: widget.pedidoId,
        clienteId: widget.clienteId,
        prestadorId: widget.prestadorId,
        estrelas: _rating,
        comentario: _comentarioCtrl.text,
      );

      if (!mounted) return;
      _comentarioCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingSentSnack)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// -------- WIDGETS DE APOIO --------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoTimeline extends StatelessWidget {
  final String estado;

  const _PedidoTimeline({
    required this.estado,
  });

  int _stepIndex() {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _stepIndex();
    final primary = Theme.of(context).colorScheme.primary;

    Widget buildCircle(bool active) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? primary : Colors.grey.shade300,
        ),
      );
    }

    Widget buildConnector(bool active) {
      return Expanded(
        child: Container(
          height: 2,
          color: active ? primary : Colors.grey.shade300,
        ),
      );
    }

    Widget buildLabel(String text, bool active) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? Colors.black87 : Colors.black54,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            buildCircle(current >= 0),
            buildConnector(current >= 1),
            buildCircle(current >= 1),
            buildConnector(current >= 2),
            buildCircle(current >= 2),
            buildConnector(current >= 3),
            buildCircle(current >= 3),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 70,
              child: buildLabel(l10n.timelineCreated, current >= 0),
            ),
            SizedBox(
              width: 80,
              child: buildLabel(l10n.timelineAccepted, current >= 1),
            ),
            SizedBox(
              width: 90,
              child: buildLabel(l10n.timelineInProgress, current >= 2),
            ),
            SizedBox(
              width: 80,
              child: buildLabel(
                estado == 'cancelado'
                    ? l10n.timelineCancelled
                    : l10n.timelineCompleted,
                current >= 3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BannerAguardandoPrestador extends StatelessWidget {
  final String pedidoId;

  const _BannerAguardandoPrestador({
    required this.pedidoId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.lookingForProviderBanner,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AguardandoPrestadorScreen(
                    pedidoId: pedidoId,
                  ),
                ),
              );
            },
            child: Text(l10n.actionView),
          ),
        ],
      ),
    );
  }
}

class _BannerAcaoPrestador extends StatelessWidget {
  final IconData icon;
  final String texto;
  final String botao;
  final VoidCallback onPressed;

  const _BannerAcaoPrestador({
    required this.icon,
    required this.texto,
    required this.botao,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPressed,
            child: Text(botao),
          ),
        ],
      ),
    );
  }
}

// --------- CHAT EXPANDABLE ---------

class _ChatExpandable extends StatefulWidget {
  final String pedidoId;
  final bool isCliente;
  final String? otherUserId;
  final String? pedidoTitulo;

  const _ChatExpandable({
    required this.pedidoId,
    required this.isCliente,
    this.otherUserId,
    this.pedidoTitulo,
  });

  @override
  State<_ChatExpandable> createState() => _ChatExpandableState();
}

class _ChatExpandableState extends State<_ChatExpandable> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = widget.isCliente ? 'cliente' : 'prestador';
      ChatService.instance.marcarEntreguesParaRole(
        pedidoId: widget.pedidoId,
        role: role,
      );
    });
  }

  void _toggleExpanded() {
    final newValue = !_expanded;
    setState(() {
      _expanded = newValue;
    });

    if (newValue) {
      final role = widget.isCliente ? 'cliente' : 'prestador';
      ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: role,
      );
    }
  }

  void _openFullChat() {
    final l10n = AppLocalizations.of(context)!;
    final otherId = (widget.otherUserId ?? '').trim();
    if (otherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatOpenFullUnavailable)),
      );
      return;
    }

    final viewerRole = widget.isCliente ? 'cliente' : 'prestador';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          pedidoId: widget.pedidoId,
          viewerRole: viewerRole,
          otherUserId: otherId,
          pedidoTitulo: widget.pedidoTitulo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ChatService.instance.streamChatMeta(widget.pedidoId),
      builder: (context, snapshot) {
        String subtitle = l10n.chatNoMessagesSubtitle;
        String countLabel = '';

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          final lastMessage = (data['lastMessage'] as String?) ?? '';
          final ts = data['lastMessageAt'];
          final messageCount = (data['messageCount'] as int?) ?? 0;

          DateTime? lastAt;
          if (ts is Timestamp) {
            lastAt = ts.toDate();
          } else if (ts is DateTime) {
            lastAt = ts;
          }

          if (lastMessage.isNotEmpty) {
            final preview = lastMessage.length > 40
                ? '${lastMessage.substring(0, 40)}...'
                : lastMessage;
            if (lastAt != null) {
              final time =
                  DateFormat('HH:mm', l10n.localeName).format(lastAt);
              subtitle = l10n.chatPreviewWithTime(preview, time);
            } else {
              subtitle = preview;
            }
          } else {
            subtitle = l10n.chatNoMessagesSubtitle;
          }

          if (messageCount > 0) {
            countLabel = l10n.chatMessageCount(messageCount);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _toggleExpanded,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.orderChatTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (countLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        countLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _expanded ? l10n.actionClose : l10n.actionOpen,
                      style: TextStyle(
                        fontSize: 12,
                        color: primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openFullChat,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.chatOpenFullAction),
                ),
              ),
              const SizedBox(height: 4),
              _ChatSection(
                pedidoId: widget.pedidoId,
                isCliente: widget.isCliente,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------- CHAT SECTION ----------------

class _ChatSection extends StatefulWidget {
  final String pedidoId;
  final bool isCliente;

  const _ChatSection({
    required this.pedidoId,
    required this.isCliente,
  });

  @override
  State<_ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<_ChatSection> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentPosition() async {
    final l10n = AppLocalizations.of(context)!;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationServiceDisabled)),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationPermissionDenied)),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationPermissionDeniedForever)),
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationFetchError(e.toString()))),
      );
      return null;
    }
  }

  Future<void> _sendLocation() async {
    if (_sending) return;

    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.chatAuthRequired,
          ),
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final pos = await _getCurrentPosition();
      if (pos == null) return;

      if (!mounted) return;
      final lat = pos.latitude;
      final lng = pos.longitude;
      final url = 'https://maps.google.com/?q=$lat,$lng';
      final label = l10n.locationApproxLabel;
      final role = widget.isCliente ? 'cliente' : 'prestador';

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderId: user.uid,
        senderRole: role,
        text: '$label: $url',
        extra: {
          'type': 'location',
          'latitude': lat,
          'longitude': lng,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatSendError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.chatAuthRequired,
          ),
        ),
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
    });

    try {
      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderId: user.uid,
        senderRole: widget.isCliente ? 'cliente' : 'prestador',
        text: text,
      );
      _controller.clear();

      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.chatSendError(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Hoje" / "Ontem" / data (dd/MM/yyyy)
  String _buildDayLabel(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    final diff = today.difference(d).inDays;

    if (diff == 0) return l10n.todayLabel;
    if (diff == 1) return l10n.yesterdayLabel;

    return DateFormat('dd/MM/yyyy', l10n.localeName).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    final canSend = user != null;
    final viewerRole = widget.isCliente ? 'cliente' : 'prestador';

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.instance
                  .streamMessagesForPedido(widget.pedidoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l10n.chatLoadError(snapshot.error.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.chatEmptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final bool isMine;
                    if (widget.isCliente) {
                      isMine = msg.senderRole == 'cliente';
                    } else {
                      isMine = msg.senderRole == 'prestador';
                    }

                    // ----- HEADER DE DIA (Hoje / Ontem / data) -----
                    Widget? dayHeader;
                    final msgDate = msg.createdAt;
                    final next =
                        (index + 1 < messages.length) ? messages[index + 1] : null;
                    final nextDate = next?.createdAt ?? msgDate;
                    final showHeader =
                        next == null || !_isSameDay(msgDate, nextDate);

                    if (showHeader) {
                      final label = _buildDayLabel(msgDate);
                      dayHeader = Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (dayHeader != null) dayHeader,
                        _ChatBubble(
                          message: msg,
                          isMine: isMine,
                          viewerRole: viewerRole,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.locationUseCurrent,
                  onPressed: canSend && !_sending ? _sendLocation : null,
                  icon: const Icon(Icons.my_location),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: canSend && !_sending,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: canSend
                          ? l10n.chatInputHint
                          : l10n.chatLoginHint,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: canSend && !_sending ? _send : null,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String viewerRole; // "cliente" ou "prestador"

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.viewerRole,
  });

  static final RegExp _urlPattern = RegExp(r'(https?://[^\s]+)');

  String? _extractUrl(String text) {
    final match = _urlPattern.firstMatch(text);
    if (match == null) return null;
    return match.group(0);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final alignment =
        isMine ? Alignment.centerRight : Alignment.centerLeft;

    final bgColor = isMine
        ? const Color(0xFFE1FFC7)
        : Colors.white;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMine ? 12 : 0),
      bottomRight: Radius.circular(isMine ? 0 : 12),
    );

    final senderLabel = message.senderRole == 'prestador'
        ? l10n.roleLabelProvider
        : message.senderRole == 'cliente'
            ? l10n.roleLabelCustomer
            : l10n.roleLabelSystem;

    final timeStr =
        DateFormat('HH:mm', l10n.localeName).format(message.createdAt);

    final contentAlignment =
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mediaUrl = message.mediaUrl;
    final isAudio = message.isAudio && mediaUrl != null;
    final isFile = message.isFile && mediaUrl != null;
    final isImage = message.isImage && mediaUrl != null;
    final text = message.text;
    final url = _extractUrl(text);
    final Widget messageBody;

    if (isAudio) {
      final audioUrl = mediaUrl;
      final name = (message.fileName ?? l10n.chatAudioLabel).trim();
      final player = ChatAudioPlayer(
        url: audioUrl,
        title: name,
        compact: true,
        accentColor: theme.colorScheme.primary,
      );
      if (message.text.trim().isNotEmpty) {
        messageBody = Column(
          crossAxisAlignment: contentAlignment,
          children: [
            player,
            const SizedBox(height: 6),
            Text(
              message.text,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        );
      } else {
        messageBody = player;
      }
    } else if (isFile) {
      final name = (message.fileName ?? l10n.chatFileLabel).trim();
      final subtitle = message.fileSize != null
          ? '${(message.fileSize! / 1024).toStringAsFixed(0)} KB'
          : null;

      messageBody = InkWell(
        onTap: () => _openUrl(mediaUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : l10n.chatFileLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (isImage) {
      messageBody = InkWell(
        onTap: () => _openUrl(mediaUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.chatImageLabel,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    } else if (url != null) {
      messageBody = Column(
        crossAxisAlignment: contentAlignment,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _openUrl(url),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: Text(l10n.chatOpenLink),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );
    } else {
      messageBody = Text(
        text,
        style: const TextStyle(fontSize: 13),
      );
    }

    // STATUS enviado/entregue/visto azul para mensagens enviadas por mim
    Widget? statusIcon;
    if (isMine &&
        (message.senderRole == 'cliente' ||
            message.senderRole == 'prestador')) {
      final bool viewerIsCliente = viewerRole == 'cliente';
      final bool deliveredToOther = viewerIsCliente
          ? message.deliveredToPrestador
          : message.deliveredToCliente;
      final bool seenByOther = viewerIsCliente
          ? message.seenByPrestador
          : message.seenByCliente;

      if (seenByOther) {
        // dois certinhos azuis
        statusIcon = const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blueAccent,
        );
      } else if (deliveredToOther) {
        // dois certinhos cinza
        statusIcon = Icon(
          Icons.done_all,
          size: 14,
          color: Colors.grey.shade600,
        );
      } else {
        // um certinho cinza
        statusIcon = Icon(
          Icons.check,
          size: 14,
          color: Colors.grey.shade600,
        );
      }
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: isMine
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: contentAlignment,
          children: [
            Text(
              isMine ? l10n.youLabel : senderLabel,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            messageBody,
            if (timeStr.isNotEmpty || statusIcon != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (statusIcon != null) ...[
                    const SizedBox(width: 4),
                    statusIcon,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ---------- MAPA: CARD + FULLSCREEN ----------

const double _kEtaAvgSpeedKmh = 30.0;

double _distanceKm(LatLng a, LatLng b) {
  const calculator = Distance();
  return calculator.as(LengthUnit.Kilometer, a, b);
}

String _formatDistance(double km, AppLocalizations l10n) {
  if (km < 1) {
    final meters = (km * 1000).round();
    return l10n.distanceMeters(meters.toString());
  }
  final kmLabel = NumberFormat('0.0', l10n.localeName).format(km);
  return l10n.distanceKilometers(kmLabel);
}

class _ContatoSection extends StatelessWidget {
  final Pedido pedido;
  final bool isCliente;
  final String Function(Map<String, dynamic>) resolvePhone;
  final Future<void> Function(String) onCall;

  const _ContatoSection({
    required this.pedido,
    required this.isCliente,
    required this.resolvePhone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final otherId = isCliente ? pedido.prestadorId : pedido.clienteId;
    if (otherId == null || otherId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final collection = isCliente ? 'prestadores' : 'users';
    final fallbackCollection = isCliente ? 'users' : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).doc(otherId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildContactCard(phone: '', loading: true);
        }
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final primaryPhone = resolvePhone(data);
        final shouldFallback = primaryPhone.isEmpty && fallbackCollection != null;

        if (shouldFallback) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(fallbackCollection)
                .doc(otherId)
                .snapshots(),
            builder: (context, fallbackSnap) {
              final fallbackData = fallbackSnap.data?.data() ?? <String, dynamic>{};
              final fallbackPhone = resolvePhone(fallbackData);
              return _buildContactCard(
                phone: fallbackPhone,
              );
            },
          );
        }

        return _buildContactCard(
          phone: primaryPhone,
        );
      },
    );
  }

  Widget _buildContactCard({required String phone, bool loading = false}) {
    final hasPhone = phone.isNotEmpty;
    final label = loading ? 'A carregar...' : (hasPhone ? phone : 'Telefone nao informado');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contacto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (hasPhone)
                IconButton(
                  tooltip: 'Ligar',
                  onPressed: () => onCall(phone),
                  icon: const Icon(Icons.call),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatEta(double km, AppLocalizations l10n) {
  final minutes = (km / _kEtaAvgSpeedKmh * 60).round();
  if (minutes <= 1) return l10n.etaLessThanMinute;
  if (minutes < 60) return l10n.etaMinutes(minutes);
  final hours = minutes ~/ 60;
  final rem = minutes % 60;
  if (rem == 0) return l10n.etaHours(hours);
  return l10n.etaHoursMinutes(hours, rem);
}

class PedidoMapaCard extends StatelessWidget {
  final Pedido pedido;
  final bool isCliente;

  const PedidoMapaCard({
    super.key,
    required this.pedido,
    required this.isCliente,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // If there are no coordinates yet, use Lisbon as fallback.
    final pedidoPoint = (pedido.latitude != null && pedido.longitude != null)
        ? LatLng(pedido.latitude!, pedido.longitude!)
        : const LatLng(38.7223, -9.1393);

    final prestadorId = pedido.prestadorId;
    if (prestadorId == null || prestadorId.trim().isEmpty) {
      return _buildMapa(
        context,
        pedidoPoint: pedidoPoint,
        prestadorPoint: null,
        l10n: l10n,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('prestadores')
          .doc(prestadorId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final lastLocation = data?['lastLocation'] as Map<String, dynamic>?;
        final lat = (lastLocation?['lat'] as num?)?.toDouble();
        final lng = (lastLocation?['lng'] as num?)?.toDouble();

        final prestadorPoint =
            (lat != null && lng != null) ? LatLng(lat, lng) : null;

        return _buildMapa(
          context,
          pedidoPoint: pedidoPoint,
          prestadorPoint: prestadorPoint,
          l10n: l10n,
        );
      },
    );
  }

  Widget _buildMapa(
    BuildContext context, {
    required LatLng pedidoPoint,
    required LatLng? prestadorPoint,
    required AppLocalizations l10n,
  }) {
    final routePoints = prestadorPoint != null
        ? <LatLng>[prestadorPoint, pedidoPoint]
        : const <LatLng>[];
    final distanceKm =
        prestadorPoint != null ? _distanceKm(prestadorPoint, pedidoPoint) : null;
    final etaText = distanceKm != null ? _formatEta(distanceKm, l10n) : null;
    final distanceText =
        distanceKm != null ? _formatDistance(distanceKm, l10n) : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PedidoMapaFullScreen(
              pedidoPoint: pedidoPoint,
              prestadorPoint: prestadorPoint,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: pedidoPoint,
                  initialZoom: 13,
                  // Preview: so mostra o mapa, sem interacao
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.chegaja.app',
                  ),
                  if (routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: Colors.blueAccent,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pedidoPoint,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.redAccent,
                          size: 34,
                        ),
                      ),
                      if (prestadorPoint != null)
                        Marker(
                          point: prestadorPoint,
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (etaText != null && distanceText != null)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.mapEtaLabel(etaText, distanceText),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.mapOpenAction,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PedidoMapaFullScreen extends StatefulWidget {
  final LatLng pedidoPoint;
  final LatLng? prestadorPoint;

  const PedidoMapaFullScreen({
    super.key,
    required this.pedidoPoint,
    this.prestadorPoint,
  });

  @override
  State<PedidoMapaFullScreen> createState() => _PedidoMapaFullScreenState();
}

class _PedidoMapaFullScreenState extends State<PedidoMapaFullScreen> {
  late final MapController _mapController;
  double _zoom = 15;

  LatLng get _mapCenter {
    final prestador = widget.prestadorPoint;
    if (prestador == null) {
      return widget.pedidoPoint;
    }
    return LatLng(
      (widget.pedidoPoint.latitude + prestador.latitude) / 2,
      (widget.pedidoPoint.longitude + prestador.longitude) / 2,
    );
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(3.0, 19.0);
    });
    final center = _mapCenter;
    _mapController.move(center, _zoom);
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(3.0, 19.0);
    });
    final center = _mapCenter;
    _mapController.move(center, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final center = _mapCenter;
    final prestadorPoint = widget.prestadorPoint;
    final routePoints = prestadorPoint != null
        ? <LatLng>[prestadorPoint, widget.pedidoPoint]
        : const <LatLng>[];
    final distanceKm = prestadorPoint != null
        ? _distanceKm(prestadorPoint, widget.pedidoPoint)
        : null;
    final etaText = distanceKm != null ? _formatEta(distanceKm, l10n) : null;
    final distanceText =
        distanceKm != null ? _formatDistance(distanceKm, l10n) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderMapTitle),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _zoom,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chegaja.app',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.pedidoPoint,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      size: 44,
                      color: Colors.redAccent,
                    ),
                  ),
                  if (prestadorPoint != null)
                    Marker(
                      point: prestadorPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_car,
                        size: 34,
                        color: Colors.blueAccent,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (etaText != null && distanceText != null)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.mapEtaLabel(etaText, distanceText),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomInMapaPedido',
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOutMapaPedido',
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

