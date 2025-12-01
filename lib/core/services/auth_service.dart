import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço responsável pela autenticação e pelo registo básico do utilizador
/// na coleção `users` do Firestore.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Garante que existe um utilizador autenticado.
  /// Se ainda não houver, faz login anónimo.
  /// Depois grava/actualiza o documento em `users/{uid}`.
  static Future<User> ensureSignedInAnonymously() async {
    User? user = _auth.currentUser;

    if (user == null) {
      final credentials = await _auth.signInAnonymously();
      user = credentials.user;
    }

    if (user == null) {
      throw Exception('Falha ao autenticar utilizador anónimo.');
    }

    final userRef = _db.collection('users').doc(user.uid);

    await userRef.set(
      {
        'uid': user.uid,
        'isAnonymous': user.isAnonymous,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return user;
  }

  static User? get currentUser => _auth.currentUser;
}
