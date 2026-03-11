
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => AuthService.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _favoritesRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('favorites');
  }

  /// Adiciona ou remove um prestador dos favoritos.
  /// Retorna true se ficou passou a ser favorito, false se deixou de ser.
  Future<bool> toggleFavorite(String prestadorId) async {
    final ref = _favoritesRef;
    if (ref == null) throw Exception('Utilizador não autenticado');

    final docRef = ref.doc(prestadorId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      return false;
    } else {
      await docRef.set({
        'prestadorId': prestadorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }

  /// Verifica se um prestador é favorito.
  Future<bool> isFavorite(String prestadorId) async {
    final ref = _favoritesRef;
    if (ref == null) return false;

    final doc = await ref.doc(prestadorId).get();
    return doc.exists;
  }

  /// Obtém stream dos IDs dos prestadores favoritos.
  Stream<List<String>> getFavoritesStream() {
    final ref = _favoritesRef;
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  /// Obtém a lista de favoritos (snapshot único).
  Future<List<String>> getFavorites() async {
    final ref = _favoritesRef;
    if (ref == null) return [];

    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
