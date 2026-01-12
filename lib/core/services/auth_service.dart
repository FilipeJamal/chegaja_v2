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

  /// Define a role activa do utilizador e marca que ele já usou esse papel.
  ///
  /// roles: {cliente: true/false, prestador: true/false}
  /// activeRole: "cliente" | "prestador"
  static Future<void> setActiveRole(String role) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final r = role.trim().toLowerCase();
    if (r != 'cliente' && r != 'prestador') return;

    await _db.collection('users').doc(user.uid).set(
      {
        'activeRole': r,
        'roles.$r': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ✅ Importante para as regras do Firestore:
    // muitas queries do lado do prestador dependem de
    // exists(/prestadores/{uid}).
    // Se o doc ainda não existir (primeira vez que escolhe "Sou Prestador"),
    // o Firestore pode devolver permission-denied.
    // Criamos um doc mínimo aqui.
    if (r == 'prestador') {
      await _db.collection('prestadores').doc(user.uid).set(
        {
          'isOnline': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }
}
