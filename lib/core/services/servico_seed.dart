import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/seed/initial_servicos_full.dart';

/// Seed automático da coleção `servicos`.
///
/// 🔥 Porquê isto existir?
/// - Em desenvolvimento, é comum apagar a coleção sem querer.
/// - A Home do cliente depende desta coleção para mostrar as categorias.
///
/// Esta classe faz um `ensureSeeded()`:
/// - se estiver vazio, popula a coleção com os serviços do
///   `lib/seed/initial_servicos.dart`;
/// - se já existir conteúdo, adiciona apenas os serviços em falta.
class ServicoSeed {
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('servicos');

  /// Popula a coleção `servicos` se estiver vazia e adiciona novos itens em falta.
  static Future<void> ensureSeeded() async {
    final snap = await _col.get();
    final existingIds = snap.docs.map((doc) => doc.id).toSet();
    final seedAll = existingIds.isEmpty;

    // ⚠️ Batch tem limite de 500 operações. Hoje temos ~80 serviços.
    // Mesmo assim, deixamos o código preparado para crescer.
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int ops = 0;

    Future<void> commitIfNeeded({bool force = false}) async {
      if (!force && ops < 450) return;
      if (ops == 0) return;
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      ops = 0;
    }

    for (final s in initialServicosFull) {
      final id = (s['id'] ?? '').toString();
      if (id.isEmpty) continue;
      if (!seedAll && existingIds.contains(id)) {
        continue;
      }

      final nome = (s['name'] ?? '').toString();
      final modo = (s['mode'] ?? 'IMEDIATO').toString();
      // Se não vier `isActive` (ou se vier apenas no formato antigo), assume TRUE.
      // Isto evita seed criar tudo como “inativo” por engano.
      final isActive = (s['isActive'] ?? s['ativo'] ?? true) == true;

      final data = <String, dynamic>{
        // Campos “novos” (v2)
        'name': nome,
        'mode': modo,
        'isActive': isActive,

        // Campos “antigos” (compatibilidade com versões anteriores)
        'nome': nome,
        'modo': modo,
        'ativo': isActive,

        'keywords': (s['keywords'] is List)
            ? (s['keywords'] as List).map((e) => e.toString()).toList()
            : <String>[],
        'iconKey': s['iconKey']?.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(_col.doc(id), data, SetOptions(merge: true));
      ops++;
      await commitIfNeeded();
    }

    await commitIfNeeded(force: true);
  }
}
