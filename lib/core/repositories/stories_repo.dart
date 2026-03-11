import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chegaja_v2/core/models/story.dart';

class StoriesRepo {
  static final _db = FirebaseFirestore.instance;

  /// Cria uma story na coleção `stories`.
  /// [mediaUrl] deve ser obtido após upload para storage.
  static Future<void> createStory({
    required String prestadorId,
    required String prestadorNome,
    String? prestadorFoto,
    required String mediaUrl,
    String? descricao,
  }) async {
    final now = DateTime.now();
    final expires = now.add(const Duration(hours: 24)); // Expira em 24h

    String? countryCode;
    List<String> categoryIds = const <String>[];
    try {
      final prestadorSnap = await _db.collection('prestadores').doc(prestadorId).get();
      final prestadorData = prestadorSnap.data();
      if (prestadorData != null) {
        final rawCountry = prestadorData['countryCode'] ??
            prestadorData['country_code'] ??
            prestadorData['region'] ??
            prestadorData['country'];
        final normalized = rawCountry?.toString().trim().toUpperCase();
        if (normalized != null && normalized.isNotEmpty) {
          countryCode = normalized;
        }

        final rawCategories = prestadorData['categories'];
        if (rawCategories is List) {
          categoryIds = rawCategories
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}
    await _db.collection('stories').add({
      'prestadorId': prestadorId,
      'prestadorNome': prestadorNome,
      'prestadorFoto': prestadorFoto,
      'mediaUrl': mediaUrl,
      'descricao': descricao,
      if (countryCode != null) 'countryCode': countryCode,
      if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expires),
    });
  }

  /// Obtém stream de todas as stories ativas (não expiradas),
  /// ordenadas por data de criação (mais recentes primeiro).
  ///
  /// Nota: Em produção, isto deve ser paginado e filtrado por região/geo.
  static Stream<List<Story>> streamActiveStories({
    String? countryCode,
    List<String>? categoryIds,
  }) {
    final now = Timestamp.now();

    Query<Map<String, dynamic>> query = _db
        .collection('stories')
        .where('expiresAt', isGreaterThan: now);

    if (countryCode != null && countryCode.trim().isNotEmpty) {
      query = query.where('countryCode', isEqualTo: countryCode.trim().toUpperCase());
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      final unique = categoryIds
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (unique.isNotEmpty) {
        query = query.where('categoryIds', arrayContainsAny: unique.take(10).toList());
      }
    }

    return query
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => Story.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }
  /// Obtém stories de um prestador específico
  static Stream<List<Story>> streamStoriesFromPrestador(String prestadorId) {
    final now = Timestamp.now();
    
    return _db.collection('stories')
        .where('prestadorId', isEqualTo: prestadorId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => Story.fromMap(doc.id, doc.data())).toList();
    });
  }
}









