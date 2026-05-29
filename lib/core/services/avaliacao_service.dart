import 'package:cloud_firestore/cloud_firestore.dart';

class AvaliacaoService {
  AvaliacaoService._();

  static final AvaliacaoService instance = AvaliacaoService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> enviarAvaliacao({
    required String pedidoId,
    required String clienteId,
    required String prestadorId,
    required int estrelas,
    String? comentario,
  }) async {
    final int rating = estrelas.clamp(1, 5);
    final String docId = '${pedidoId}_$clienteId';

    final avaliacaoRef = _db.collection('avaliacoes').doc(docId);
    final avaliacaoSnap = await avaliacaoRef.get();
    if (avaliacaoSnap.exists) {
      return;
    }

    await avaliacaoRef.set({
      'pedidoId': pedidoId,
      'clienteId': clienteId,
      'prestadorId': prestadorId,
      'estrelas': rating,
      if (comentario != null && comentario.trim().isNotEmpty)
        'comentario': comentario.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
