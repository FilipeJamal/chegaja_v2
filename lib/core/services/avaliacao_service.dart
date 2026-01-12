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
    final prestadorRef = _db.collection('prestadores').doc(prestadorId);

    await _db.runTransaction((tx) async {
      final avaliacaoSnap = await tx.get(avaliacaoRef);
      if (avaliacaoSnap.exists) {
        return;
      }

      tx.set(avaliacaoRef, {
        'pedidoId': pedidoId,
        'clienteId': clienteId,
        'prestadorId': prestadorId,
        'estrelas': rating,
        if (comentario != null && comentario.trim().isNotEmpty)
          'comentario': comentario.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prestadorSnap = await tx.get(prestadorRef);
      final data = prestadorSnap.data() ?? <String, dynamic>{};

      final num countRaw = (data['ratingCount'] ?? 0) as num;
      final num sumRaw = (data['ratingSum'] ?? 0) as num;

      final int newCount = countRaw.toInt() + 1;
      final double newSum = sumRaw.toDouble() + rating.toDouble();
      final double newAvg = newSum / newCount;

      tx.set(
        prestadorRef,
        {
          'ratingCount': newCount,
          'ratingSum': newSum,
          'ratingAvg': newAvg,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
