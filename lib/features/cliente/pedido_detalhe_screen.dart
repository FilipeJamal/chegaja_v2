// lib/features/cliente/pedido_detalhe_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/core/services/politica_reembolso.dart';
import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/aguardando_prestador_screen.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_pedido_acoes.dart';

class PedidoDetalheScreen extends StatelessWidget {
  final String pedidoId;
  final bool isCliente;

  const PedidoDetalheScreen({
    super.key,
    required this.pedidoId,
    this.isCliente = true,
  });

  String _labelEstado(String estado) {
    switch (estado) {
      case 'criado':
        return 'À espera de prestador';
      case 'aguarda_resposta_cliente':
        return 'Proposta de prestador';
      case 'aceito':
        return 'Prestador aceitou';
      case 'em_andamento':
        return 'Em andamento';
      case 'aguarda_confirmacao_valor':
        return 'A confirmar valor';
      case 'concluido':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  /// Texto que aparece na linha "Valor" das Informações
  String _buildValorLabel(Pedido pedido) {
    // 1) Valor final já confirmado pelo cliente
    if (pedido.precoFinal != null &&
        pedido.statusConfirmacaoValor == 'confirmado_cliente') {
      return '€ ${pedido.precoFinal!.toStringAsFixed(2)}';
    }

    // 2) Prestador lançou valor final e está à espera de confirmação
    if (pedido.precoPropostoPrestador != null &&
        pedido.statusConfirmacaoValor == 'pendente_cliente') {
      return '€ ${pedido.precoPropostoPrestador!.toStringAsFixed(2)} (a confirmar)';
    }

    // 3) Há valor final mas sem estado claro
    if (pedido.precoFinal != null) {
      return '€ ${pedido.precoFinal!.toStringAsFixed(2)}';
    }

    // 4) Só valor lançado pelo prestador (sem estado pendente)
    if (pedido.precoPropostoPrestador != null) {
      return '€ ${pedido.precoPropostoPrestador!.toStringAsFixed(2)} (proposto)';
    }

    // 5) Só faixa estimada
    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;

    if (min != null && max != null) {
      return '€ ${min.toStringAsFixed(2)} a € ${max.toStringAsFixed(2)} (estimado)';
    }
    if (min != null) {
      return 'Desde € ${min.toStringAsFixed(2)} (estimado)';
    }
    if (max != null) {
      return 'Até € ${max.toStringAsFixed(2)} (estimado)';
    }

    // 6) Nada de info
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do pedido'),
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
                child: Text('Erro a carregar pedido: ${snapshot.error}'),
              );
            }

            final pedido = snapshot.data;

            if (pedido == null) {
              return const Center(
                child: Text('Pedido não encontrado.'),
              );
            }

            final isAgendado = pedido.modo == 'AGENDADO';
            final categoria = pedido.categoria ?? 'Categoria não definida';
            final desc = (pedido.descricao ?? '').trim();
            final temDescricao = desc.isNotEmpty;

            final mensagemProposta = pedido.mensagemPropostaPrestador?.trim();
            final temMensagemProposta =
                mensagemProposta != null && mensagemProposta.isNotEmpty;

            String subtituloModo;
            if (isAgendado && pedido.agendadoPara != null) {
              subtituloModo =
                  'Agendado para ${df.format(pedido.agendadoPara!)}';
            } else if (isAgendado) {
              subtituloModo = 'Agendado (sem data definida)';
            } else {
              subtituloModo = 'Serviço imediato';
            }

            final estadoLabel = _labelEstado(pedido.estado);

            // Texto que vai para a linha "Valor"
            final valorLabel = _buildValorLabel(pedido);

            // Está ainda à procura de prestador?
            final bool estaProcurandoPrestador =
                (pedido.estado == 'criado' ||
                        pedido.estado == 'aguarda_resposta_cliente') &&
                    pedido.prestadorId == null;

            // Permissões de edição/cancelamento para o cliente
            final podeEditar = isCliente && pedido.estado == 'criado';
            final podeCancelar = isCliente &&
                pedido.estado != 'concluido' &&
                pedido.estado != 'cancelado';

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TÍTULO
                          Text(
                            pedido.titulo,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            categoria,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // CHIPS DE MODO + ESTADO
                          Row(
                            children: [
                              Chip(
                                label: Text(subtituloModo),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('Estado: $estadoLabel'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Linha do tempo
                          _PedidoTimeline(estado: pedido.estado),
                          const SizedBox(height: 12),

                          // Banner para voltar ao ecrã "A encontrar prestador"
                          if (estaProcurandoPrestador) ...[
                            _BannerAguardandoPrestador(pedidoId: pedido.id),
                            const SizedBox(height: 16),
                          ],

                          const Divider(),
                          const SizedBox(height: 16),

                          // AÇÕES DO CLIENTE (aceitar prestador / confirmar valor)
                          if (isCliente) ...[
                            ClientePedidoAcoes(pedido: pedido),
                            const SizedBox(height: 16),
                          ],

                          // Mensagem do prestador (texto da proposta)
                          if (temMensagemProposta) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mensagem do prestador',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    mensagemProposta!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (temDescricao) ...[
                            const Text(
                              'Descrição',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              desc,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const Text(
                            'Informações',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Criado em',
                            value: df.format(pedido.createdAt),
                          ),
                          if (isAgendado && pedido.agendadoPara != null)
                            _InfoRow(
                              label: 'Agendado para',
                              value: df.format(pedido.agendadoPara!),
                            ),
                          _InfoRow(
                            label: 'Valor',
                            value: valorLabel,
                          ),

                          const SizedBox(height: 24),

                          // Botões de EDITAR / CANCELAR (apenas cliente)
                          if (podeEditar || podeCancelar)
                            Row(
                              children: [
                                if (podeEditar)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _editarPedido(context, pedido),
                                      child: const Text('Editar'),
                                    ),
                                  ),
                                if (podeEditar && podeCancelar)
                                  const SizedBox(width: 12),
                                if (podeCancelar)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _cancelarPedido(context, pedido),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Cancelar pedido'),
                                    ),
                                  ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _editarPedido(BuildContext context, Pedido pedido) async {
    final user = AuthService.currentUser; // Só cliente
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

    final estaEmServico =
        pedido.estado == 'em_andamento' ||
        pedido.estado == 'aguarda_confirmacao_valor';

    final motivoController = TextEditingController();

    // Pré‑cálculo da política para mostrar info no diálogo
    final previewInfo = PoliticaReembolso.calcularParaCancelamentoCliente(
      pedido,
      DateTime.now(),
    );

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancelar pedido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensagem de política de reembolso (inteligente por modo/tempo)
              Text(
                previewInfo.mensagemDetalhada,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (estaEmServico) ...[
                const Text(
                  'O serviço já está em andamento.\n'
                  'Ao cancelar agora, o reembolso pode não ser total.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const Text(
                  'Tens a certeza que queres cancelar este pedido?',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: motivoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: estaEmServico
                      ? 'Motivo do cancelamento'
                      : 'Motivo (opcional)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                if (estaEmServico &&
                    motivoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor escreve um motivo para o cancelamento.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final motivo = motivoController.text.trim();

    // Recalcula a política com a hora real do clique
    final info = PoliticaReembolso.calcularParaCancelamentoCliente(
      pedido,
      DateTime.now(),
    );

    try {
      await PedidoService.instance.cancelarPorCliente(
        pedido: pedido,
        motivo: motivo,
        tipoReembolso: PoliticaReembolso.tipoToString(info.tipo),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido cancelado. ${info.mensagemCurta}.'),
        ),
      );
      Navigator.of(context).pop(); // sair do detalhe
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar pedido: $e')),
      );
    }
  }
}

// ---------------- WIDGETS DE APOIO ----------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha do tempo simples do pedido:
/// Criado → Aceito → Em andamento → Concluído
class _PedidoTimeline extends StatelessWidget {
  final String estado;

  const _PedidoTimeline({
    required this.estado,
  });

  int _stepIndex() {
    switch (estado) {
      case 'criado':
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
            // Step 0
            buildCircle(current >= 0),
            buildConnector(current >= 1),
            // Step 1
            buildCircle(current >= 1),
            buildConnector(current >= 2),
            // Step 2
            buildCircle(current >= 2),
            buildConnector(current >= 3),
            // Step 3
            buildCircle(current >= 3),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 70,
              child: buildLabel('Criado', current >= 0),
            ),
            SizedBox(
              width: 80,
              child: buildLabel('Aceito', current >= 1),
            ),
            SizedBox(
              width: 90,
              child: buildLabel('Em andamento', current >= 2),
            ),
            SizedBox(
              width: 80,
              child: buildLabel('Concluído', current >= 3),
            ),
          ],
        ),
      ],
    );
  }
}

/// Banner para reabrir o ecrã "A encontrar prestador"
class _BannerAguardandoPrestador extends StatelessWidget {
  final String pedidoId;

  const _BannerAguardandoPrestador({
    required this.pedidoId,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ainda estamos a procurar um prestador para este pedido.',
              style: TextStyle(fontSize: 13),
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
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}
