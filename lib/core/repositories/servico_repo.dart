// lib/core/repositories/servico_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/seed/initial_servicos_full.dart';

class ServicosRepo {
  static String _normalizeMode(String? mode) {
    final raw = (mode ?? '').toUpperCase().trim();
    if (raw == 'POR_PROPOSTA' || raw == 'ORCAMENTO' || raw == 'POR_ORCAMENTO') {
      return 'ORCAMENTO';
    }
    if (raw == 'AGENDADO') return 'AGENDADO';
    if (raw == 'IMEDIATO') return 'IMEDIATO';
    return 'IMEDIATO';
  }
  // Referência para a coleção `servicos`
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('servicos');

  /// Fallback local (emulador costuma começar vazio).
  /// Isto evita a Home "sem categorias" quando est?s a testar com emuladores.
  static List<Servico> _fallbackServicosAtivos() {
    final lista = initialServicosFull
        .map((m) => Servico.fromMap(m, (m['id'] ?? '').toString()))
        .where((s) => s.isActive)
        .toList();

    lista.sort((a, b) => a.name.compareTo(b.name));
    return lista;
  }

  /// Stream de serviços ATIVOS (isActive == true),
  /// já filtrados e ordenados pelo nome.
  static Stream<List<Servico>> streamServicosAtivos() {
    // âš ï¸ IMPORTANTE (fix do â€œHome vaziaâ€):
    // Antigamente fazíamos `.where('isActive' == true)`. Se o catálogo tiver
    // docs antigos sem o campo `isActive` (apenas `ativo`), a query devolve 0
    // resultados e a Home do cliente fica vazia.
    //
    // Como o catálogo é pequeno (~80 serviços), é seguro escutar a coleção toda
    // e filtrar no lado da app (com compatibilidade v1/v2 no modelo Servico).
    return _col.snapshots().map((snapshot) {
      final lista = snapshot.docs
          .map((doc) => Servico.fromMap(doc.data(), doc.id))
          .where((s) => s.isActive)
          .toList();

      lista.sort((a, b) => a.name.compareTo(b.name));

      // Emulador: se estiver vazio, usa fallback local
      if (lista.isEmpty && AppConfig.useFirebaseEmulators) {
        return _fallbackServicosAtivos();
      }

      return lista;
    });
  }

  /// Versão Future: obtém uma lista de serviços ativos uma única vez.
  static Future<List<Servico>> getServicosAtivosOnce() async {
    final snapshot = await _col.get();
    final lista = snapshot.docs
        .map((doc) => Servico.fromMap(doc.data(), doc.id))
        .where((s) => s.isActive)
        .toList();

    lista.sort((a, b) => a.name.compareTo(b.name));

    if (lista.isEmpty && AppConfig.useFirebaseEmulators) {
      return _fallbackServicosAtivos();
    }

    return lista;
  }

  /// Busca todos os serviços ATIVOS (sem filtrar por modo).
  static Future<List<Servico>> buscarServicosAtivosTodos() async {
    final snapshot = await _col.get();
    final lista = snapshot.docs
        .map((doc) => Servico.fromMap(doc.data(), doc.id))
        .where((s) => s.isActive)
        .toList();

    lista.sort((a, b) => a.name.compareTo(b.name));

    if (lista.isEmpty && AppConfig.useFirebaseEmulators) {
      return _fallbackServicosAtivos();
    }

    return lista;
  }

  /// NOVO: busca serviços ativos filtrando por modo
  /// (IMEDIATO / AGENDADO / POR_PROPOSTA).
  ///
  /// Esta função é usada no NovoPedidoScreen v2, onde chamamos:
  ///   ServicosRepo.buscarServicosAtivosPorModo(_modo)
  static Future<List<Servico>> buscarServicosAtivosPorModo(String modo) async {
    // Mesma lógica: compatibilidade com docs antigos (mode/modo e isActive/ativo)
    final target = _normalizeMode(modo);
    final snapshot = await _col.get();

    var lista = snapshot.docs
        .map((doc) => Servico.fromMap(doc.data(), doc.id))
        .where((s) => s.isActive)
        .toList();

    // Emulador: se estiver vazio, usa fallback local antes de filtrar por modo
    if (lista.isEmpty && AppConfig.useFirebaseEmulators) {
      lista = _fallbackServicosAtivos();
    }

    lista = lista.where((s) => _normalizeMode(s.mode) == target).toList();


    lista.sort((a, b) => a.name.compareTo(b.name));
    return lista;
  }

  /// Busca um serviço pelo ID (ou devolve null se não existir).
  static Future<Servico?> getServicoById(String id) async {
    final doc = await _col.doc(id).get();
    if (doc.exists) {
      final data = doc.data();
      if (data == null) return null;
      return Servico.fromMap(data, doc.id);
    }

    // Emulador: tenta no fallback local
    if (AppConfig.useFirebaseEmulators) {
      try {
        final fb = _fallbackServicosAtivos();
        return fb.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Cria ou atualiza um serviço (útil para seeds, painel admin, etc.).
  static Future<void> salvarServico(Servico servico) async {
    await _col.doc(servico.id).set(
          servico.toMap(includeCreatedAt: true),
          SetOptions(merge: true),
        );
  }
}






