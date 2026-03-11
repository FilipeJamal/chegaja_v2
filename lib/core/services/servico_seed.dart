import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/seed/initial_servicos_full.dart';

/// Auto-seed da colecao `servicos`.
///
/// Em ambiente local, esta rotina preenche a colecao quando necessario.
/// Se o utilizador nao tiver permissao de escrita, a rotina passa a no-op
/// para evitar erros repetidos no arranque.
class ServicoSeed {
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('servicos');

  static bool _seedBlockedByPermissions = false;

  /// Popula `servicos` se estiver vazia e adiciona itens em falta.
  static Future<void> ensureSeeded() async {
    if (_seedBlockedByPermissions) return;

    try {
      final snap = await _col.get();
      final existingIds = snap.docs.map((doc) => doc.id).toSet();
      final seedAll = existingIds.isEmpty;

      // Batch limit is 500 ops. We keep a safe margin.
      WriteBatch batch = FirebaseFirestore.instance.batch();
      var ops = 0;

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
        if (!seedAll && existingIds.contains(id)) continue;

        final nome = (s['name'] ?? '').toString();
        final modo = (s['mode'] ?? 'IMEDIATO').toString();
        final isActive = (s['isActive'] ?? s['ativo'] ?? true) == true;

        final data = <String, dynamic>{
          // v2 fields
          'name': nome,
          'mode': modo,
          'isActive': isActive,
          if (s['name_i18n'] is Map) 'name_i18n': s['name_i18n'],

          // legacy compatibility fields
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
    } on FirebaseException catch (e) {
      // Typical in emulator + anonymous session when writes are denied by rules.
      if (e.code == 'permission-denied') {
        _seedBlockedByPermissions = true;
        return;
      }
      rethrow;
    }
  }
}
