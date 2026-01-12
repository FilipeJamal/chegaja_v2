// lib/features/cliente/aguardando_prestador_screen.dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/core/services/politica_reembolso.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';

class AguardandoPrestadorScreen extends StatefulWidget {
  final String pedidoId;

  const AguardandoPrestadorScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  State<AguardandoPrestadorScreen> createState() =>
      _AguardandoPrestadorScreenState();
}

class _AguardandoPrestadorScreenState
    extends State<AguardandoPrestadorScreen> {
  /// Evita chamar navegação duas vezes
  bool _foiParaDetalhe = false;

  /// Evita recriar o pedido mais que uma vez depois de cancelamento do prestador
  bool _reabriuDepoisCancelPrestador = false;

  // ---------------------- AÇÕES ----------------------

  Future<void> _irParaDetalhe(Pedido pedido) async {
    if (_foiParaDetalhe) return;
    _foiParaDetalhe = true;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Um prestador aceitou o teu pedido.'),
      ),
    );

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PedidoDetalheScreen(
          pedidoId: pedido.id,
          isCliente: true,
        ),
      ),
    );
  }

  /// Quando o prestador cancela: criamos um NOVO pedido igual
  /// e voltamos a este ecrã com o novo ID.
  Future<void> _recriarPedidoDepoisDeCancelamento(Pedido pedido) async {
    if (_reabriuDepoisCancelPrestador) return;
    _reabriuDepoisCancelPrestador = true;

    try {
      final novoId = await PedidosRepo.criarPedido(
        clienteId: pedido.clienteId,
        titulo: pedido.titulo,
        descricao: pedido.descricao,
        modo: pedido.modo,
        agendadoPara: pedido.agendadoPara,
        categoria: pedido.categoria,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O prestador anterior cancelou. '
            'Estamos a procurar outro prestador para ti.',
          ),
        ),
      );

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AguardandoPrestadorScreen(
            pedidoId: novoId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível procurar outro prestador automaticamente: $e',
          ),
        ),
      );
    }
  }

  Future<void> _cancelarPedidoComoCliente(Pedido pedido) async {
    final user = AuthService.currentUser;
    if (user == null || user.uid != pedido.clienteId) return;

    final motivoController = TextEditingController();

    // Calcula política de reembolso para mostrar ao cliente
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
              Text(
                previewInfo.mensagemDetalhada,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Se quiseres, podes indicar o motivo do cancelamento (opcional):',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
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
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final motivo = motivoController.text.trim();

    try {
      final info = PoliticaReembolso.calcularParaCancelamentoCliente(
        pedido,
        DateTime.now(),
      );

      await PedidoService.instance.cancelarPorCliente(
        pedido: pedido,
        motivo: motivo,
        tipoReembolso: PoliticaReembolso.tipoToString(info.tipo),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido cancelado. ${info.mensagemCurta}.'),
        ),
      );

      Navigator.of(context).pop(); // fecha este ecrã
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar pedido: $e'),
        ),
      );
    }
  }

  // ---------------------- UI ----------------------

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('A encontrar prestador'),
      ),
      body: SafeArea(
        child: StreamBuilder<Pedido?>(
          stream: PedidosRepo.streamPedidoPorId(widget.pedidoId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro a carregar pedido: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final pedido = snapshot.data;

            if (pedido == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pedido não encontrado.\n'
                      'Talvez tenha sido removido ou cancelado.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              );
            }

            final canceladoPor = pedido.canceladoPor;
            final bool canceladoPeloPrestador =
                pedido.estado == 'cancelado' && canceladoPor == 'prestador';
            final bool canceladoPeloCliente =
                pedido.estado == 'cancelado' && canceladoPor == 'cliente';

            final bool prestadorAceitouOuServico =
                pedido.estado == 'aceito' ||
                    pedido.estado == 'aguarda_resposta_cliente' ||
                    pedido.estado == 'em_andamento' ||
                    pedido.estado == 'aguarda_confirmacao_valor';

            // 1) Prestador aceitou → vai para ecrã de detalhe (onde podes ter mapa/ETA)
            if (prestadorAceitouOuServico) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _irParaDetalhe(pedido),
              );
              return _buildMensagemCentro(
                primary,
                titulo: 'Prestador encontrado',
                subtitulo:
                    'Um prestador aceitou o teu pedido.\n'
                    'A abrir detalhes do serviço...',
                mostrarLoader: true,
                mostrarBotoes: false,
              );
            }

            // 2) Cliente já cancelou → fecha este ecrã
            if (canceladoPeloCliente) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });

              return _buildMensagemCentro(
                primary,
                titulo: 'Pedido cancelado',
                subtitulo:
                    'Este pedido já foi cancelado.\n'
                    'Se ainda precisares de ajuda, cria um novo pedido.',
                mostrarLoader: false,
                mostrarBotoes: false,
              );
            }

            // 3) Prestador cancelou → criamos novo pedido automaticamente
            if (canceladoPeloPrestador) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _recriarPedidoDepoisDeCancelamento(pedido),
              );

              return _buildMensagemCentro(
                primary,
                titulo: 'O prestador cancelou o pedido',
                subtitulo:
                    'Estamos a procurar outro prestador disponível para ti.\n'
                    'Isto pode levar alguns minutos.',
                mostrarLoader: true,
                mostrarBotoes: false,
              );
            }

            // 4) Estado normal: ainda a procurar prestador
            return _buildEsperandoLayout(
              context,
              primary,
              pedido,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMensagemCentro(
    Color primary, {
    required String titulo,
    required String subtitulo,
    bool mostrarLoader = false,
    bool mostrarBotoes = false,
    Pedido? pedido,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 40,
            backgroundColor: primary.withValues(alpha: 0.08),
            child: Icon(
              Icons.search,
              size: 40,
              color: primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          if (mostrarLoader) const CircularProgressIndicator(),
          if (mostrarBotoes && pedido != null) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () => _cancelarPedidoComoCliente(pedido),
                child: const Text('Cancelar pedido'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Minimizar e continuar a usar a app'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEsperandoLayout(
    BuildContext context,
    Color primary,
    Pedido pedido,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 40,
            backgroundColor: primary.withValues(alpha: 0.08),
            child: Icon(
              Icons.search,
              size: 40,
              color: primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'A encontrar um prestador perto de ti',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Normalmente isto leva apenas alguns minutos.\n'
            'Fica atento às notificações.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => _cancelarPedidoComoCliente(pedido),
              child: const Text('Cancelar pedido'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Minimizar e continuar a usar a app'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
