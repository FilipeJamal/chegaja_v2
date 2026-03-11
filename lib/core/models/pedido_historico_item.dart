// lib/core/models/pedido_historico_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um evento no histórico de um Pedido (Audit Trail).
class PedidoHistoricoItem {
  /// O tipo de evento (ex: 'criado', 'aceito', 'cancelado', 'concluido').
  final String evento;

  /// Data e hora exata do evento.
  final DateTime timestamp;

  /// ID do utilizador que realizou a ação (opcional, pode ser sistema).
  final String? userId;

  /// Detalhe extra (ex: motivo do cancelamento, ou "Pagamento confirmado").
  final String? descricao;

  const PedidoHistoricoItem({
    required this.evento,
    required this.timestamp,
    this.userId,
    this.descricao,
  });

  /// Converte para Map (gravação no Firestore).
  Map<String, dynamic> toMap() {
    return {
      'evento': evento,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'descricao': descricao,
    };
  }

  /// Cria a partir de um Map (leitura do Firestore).
  factory PedidoHistoricoItem.fromMap(Map<String, dynamic> map) {
    return PedidoHistoricoItem(
      evento: map['evento'] as String? ?? 'desconhecido',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] as String?,
      descricao: map['descricao'] as String?,
    );
  }
}
