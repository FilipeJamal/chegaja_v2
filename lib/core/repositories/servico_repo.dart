// lib/core/repositories/servico_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/servico.dart';

class ServicosRepo {
  // Referência para a coleção `servicos`
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('servicos');

  /// Stream de serviços ATIVOS (isActive == true),
  /// já filtrados e ordenados pelo nome.
  static Stream<List<Servico>> streamServicosAtivos() {
    return _col
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs.map((doc) {
        // doc.data() => Map<String, dynamic>
        final data = doc.data();
        // 👇 Aqui usamos o fromMap CORRETAMENTE:
        // primeiro o MAP, depois o ID
        return Servico.fromMap(data, doc.id);
      }).toList();

      // Ordenar alfabeticamente pelo nome do serviço
      lista.sort((a, b) => a.name.compareTo(b.name));
      return lista;
    });
  }

  /// Versão Future: obtém uma lista de serviços ativos uma única vez
  static Future<List<Servico>> getServicosAtivosOnce() async {
    final snapshot =
        await _col.where('isActive', isEqualTo: true).get();

    final lista = snapshot.docs.map((doc) {
      final data = doc.data();
      return Servico.fromMap(data, doc.id);
    }).toList();

    lista.sort((a, b) => a.name.compareTo(b.name));
    return lista;
  }

  /// Busca um serviço pelo ID (ou devolve null se não existir)
  static Future<Servico?> getServicoById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return Servico.fromMap(data, doc.id);
  }

  /// Cria ou atualiza um serviço (útil para seeds, painel admin, etc.)
  static Future<void> salvarServico(Servico servico) async {
    await _col.doc(servico.id).set(servico.toMap(includeCreatedAt: true));
  }
}
