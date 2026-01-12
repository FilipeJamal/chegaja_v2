import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';

/// Abre o detalhe do pedido determinando automaticamente se o utilizador
/// atual é **cliente** ou **prestador** deste pedido.
///
/// Isto é útil para deep links (notificações) onde não sabemos a "role".
class PedidoDetalheAutoScreen extends StatelessWidget {
  final String pedidoId;

  const PedidoDetalheAutoScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pedido?>(
      stream: PedidosRepo.streamPedidoPorId(pedidoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pedido')),
            body: Center(
              child: Text('Erro ao carregar pedido: ${snapshot.error}'),
            ),
          );
        }

        final pedido = snapshot.data;
        if (pedido == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pedido')),
            body: const Center(
              child: Text('Pedido não encontrado.'),
            ),
          );
        }

        final uid = AuthService.currentUser?.uid;
        final isCliente = uid != null && uid == pedido.clienteId;

        return PedidoDetalheScreen(
          pedidoId: pedidoId,
          isCliente: isCliente,
        );
      },
    );
  }
}
