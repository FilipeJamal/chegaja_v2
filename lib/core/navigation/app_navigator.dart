// lib/core/navigation/app_navigator.dart
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/features/common/pedido_detalhe_auto_screen.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

/// Navegação global (para deep links / notificações).
///
/// Isto permite navegar para um Pedido específico sem depender de um
/// BuildContext local (por exemplo, ao clicar numa notificação).
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static NavigatorState? get _nav => navigatorKey.currentState;

  static void showSnack(String text) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  /// Abre o detalhe do pedido detectando automaticamente se o user
  /// é cliente ou prestador.
  static Future<void> openPedidoDetalhe(String pedidoId) async {
    final nav = _nav;
    if (nav == null) return;

    await nav.push(
      MaterialPageRoute(
        builder: (_) => PedidoDetalheAutoScreen(pedidoId: pedidoId),
      ),
    );
  }

  /// Abre o ecrã de chat (thread) de um pedido.
  ///
  /// Se não conseguir determinar a role ou o outro utilizador, cai para o detalhe do pedido.
  static Future<void> openChatThread(String pedidoId) async {
    final nav = _nav;
    if (nav == null) return;

    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null || uid.trim().isEmpty) {
        return openPedidoDetalhe(pedidoId);
      }

      final snap = await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).get();
      final data = snap.data();
      if (data == null) {
        return openPedidoDetalhe(pedidoId);
      }

      final clienteId = (data['clienteId'] ?? '').toString().trim();
      final prestadorId = (data['prestadorId'] ?? '').toString().trim();

      // Se não dá para saber se é cliente/prestador, cai para detalhe
      String viewerRole;
      if (uid == clienteId) {
        viewerRole = 'cliente';
      } else if (uid == prestadorId) {
        viewerRole = 'prestador';
      } else {
        return openPedidoDetalhe(pedidoId);
      }

      final otherUserId = (viewerRole == 'cliente') ? prestadorId : clienteId;

      // ✅ FIX: ChatThreadScreen exige otherUserId (String) e deve ser válido.
      // Se o pedido ainda não tem prestador (ou cliente), vai para o detalhe.
      if (otherUserId.trim().isEmpty) {
        return openPedidoDetalhe(pedidoId);
      }

      final pedidoTitulo = (data['titulo'] ?? data['pedidoTitulo'] ?? '').toString().trim();

      await nav.push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            pedidoId: pedidoId,
            viewerRole: viewerRole,
            otherUserId: otherUserId,
            pedidoTitulo: pedidoTitulo.isEmpty ? null : pedidoTitulo,
          ),
        ),
      );
    } catch (_) {
      return openPedidoDetalhe(pedidoId);
    }
  }
}
