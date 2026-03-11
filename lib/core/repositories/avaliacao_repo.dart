import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/avaliacao.dart';

class AvaliacaoRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _avaliacoesRef => _db.collection('avaliacoes');

  /// Obtém as avaliações de um prestador, ordenadas por data (mais recentes primeiro).
  Future<List<Avaliacao>> getAvaliacoesPrestador(String prestadorId, {int limit = 10}) async {
    final snapshot = await _avaliacoesRef
        .where('prestadorId', isEqualTo: prestadorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final avaliacoes = snapshot.docs.map((doc) => Avaliacao.fromFirestore(doc)).toList();

    // Opcional: Aqui poderíamos carregar os nomes dos clientes (join manual)
    // Se o user object estiver em 'users/{uid}', podemos fazer um Future.wait.
    // Para MVP, vamos assumir que o frontend pode carregar ou que o backend devia denormalizar.
    // Como estamos no cliente, vamos fazer o fetch rápido dos nomes se forem poucos.
    
    if (avaliacoes.isEmpty) return [];

    return await _enrichWithUserData(avaliacoes);
  }

  Future<List<Avaliacao>> _enrichWithUserData(List<Avaliacao> list) async {
    // Recolhe IDs únicos de clientes
    final userIds = list.map((a) => a.clienteId).toSet();
    if (userIds.isEmpty) return list;

    // Busca users (batch ou individual)
    // Firestore "in" query up to 30.
    // Se forem poucos, fazemos:
    final userDocs = await Future.wait(
      userIds.map((uid) => _db.collection('users').doc(uid).get()),
    );

    final userMap = {
      for (var doc in userDocs)
        doc.id: {
          'displayName': (doc.data()?['displayName'] ?? 'Cliente ChegaJá') as String,
          'photoUrl': doc.data()?['photoUrl'] as String?,
        },
    };

    // Retorna nova lista com dados preenchidos
    return list.map((a) {
      final userData = userMap[a.clienteId];
      if (userData == null) return a;
      
      return Avaliacao(
        id: a.id,
        pedidoId: a.pedidoId,
        clienteId: a.clienteId,
        prestadorId: a.prestadorId,
        estrelas: a.estrelas,
        comentario: a.comentario,
        createdAt: a.createdAt,
        clienteNome: userData['displayName'],
        clienteFoto: userData['photoUrl'],
      );
    }).toList();
  }
}
