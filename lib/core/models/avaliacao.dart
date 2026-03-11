import 'package:cloud_firestore/cloud_firestore.dart';

class Avaliacao {
  final String id;
  final String pedidoId;
  final String clienteId;
  final String prestadorId;
  final int estrelas;
  final String? comentario;
  final DateTime createdAt;

  // Campos apenas locais (join) se necessário futuramente
  final String? clienteNome; 
  final String? clienteFoto;

  Avaliacao({
    required this.id,
    required this.pedidoId,
    required this.clienteId,
    required this.prestadorId,
    required this.estrelas,
    this.comentario,
    required this.createdAt,
    this.clienteNome,
    this.clienteFoto,
  });

  factory Avaliacao.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Avaliacao(
      id: doc.id,
      pedidoId: data['pedidoId'] ?? '',
      clienteId: data['clienteId'] ?? '',
      prestadorId: data['prestadorId'] ?? '',
      estrelas: (data['estrelas'] as num?)?.toInt() ?? 0,
      comentario: data['comentario'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
