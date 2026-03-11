import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servico responsavel pela autenticacao e pelo registo basico do utilizador
/// na colecao `users` do Firestore.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static Future<User>? _pendingAnonymousEnsure;
  static const String _seenUserFlagKey = 'auth.seenPersistedUser';

  static DocumentReference<Map<String, dynamic>> get userRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');
    return _db.collection('users').doc(uid);
  }

  /// Garante que existe um utilizador autenticado.
  /// Se ainda nao houver, faz login anonimo.
  /// Depois grava/actualiza o documento em `users/{uid}`.
  static Future<User> ensureSignedInAnonymously() async {
    final pending = _pendingAnonymousEnsure;
    if (pending != null) return pending;

    final future = _ensureSignedInAnonymouslyInternal();
    _pendingAnonymousEnsure = future;

    try {
      return await future;
    } finally {
      if (identical(_pendingAnonymousEnsure, future)) {
        _pendingAnonymousEnsure = null;
      }
    }
  }

  static Future<User> _ensureSignedInAnonymouslyInternal() async {
    await _ensureWebPersistence();

    User? user = _auth.currentUser;
    user ??= await _waitForRestoredUser(
      timeout: await _restoreTimeoutBeforeAnonymousSignIn(),
    );

    if (user == null) {
      final credentials = await _auth.signInAnonymously();
      user = credentials.user ??
          await _waitForRestoredUser(
            timeout: const Duration(seconds: 10),
          );
    }

    if (user == null) {
      throw Exception('Falha ao autenticar utilizador anonimo.');
    }

    await _markUserSeen();

    final userDocRef = _db.collection('users').doc(user.uid);

    // Se ja existir, nao sobrescrevemos campos importantes,
    // mas garantimos default region se nao existir.
    final doc = await userDocRef.get();
    if (!doc.exists) {
      await userDocRef.set(
        {
          'uid': user.uid,
          'isAnonymous': user.isAnonymous,
          'region': 'PT',
          'lastLoginAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      await userDocRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  static Future<Duration> _restoreTimeoutBeforeAnonymousSignIn() async {
    if (!kIsWeb) return const Duration(seconds: 2);

    final seenPersistedUser = await _hasSeenUser();
    if (seenPersistedUser) {
      return const Duration(seconds: 8);
    }

    return const Duration(seconds: 2);
  }

  static Future<bool> _hasSeenUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenUserFlagKey) == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markUserSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenUserFlagKey, true);
    } catch (_) {}
  }

  static Future<User?> _waitForRestoredUser({
    Duration? timeout,
  }) async {
    final current = _auth.currentUser;
    if (current != null) return current;

    final deadline = DateTime.now().add(
      timeout ??
          (kIsWeb ? const Duration(seconds: 4) : const Duration(seconds: 2)),
    );

    final completer = Completer<User?>();
    late final StreamSubscription<User?> sub;
    sub = _auth.authStateChanges().listen((user) {
      if (user != null && !completer.isCompleted) {
        completer.complete(user);
      }
    });

    try {
      while (DateTime.now().isBefore(deadline)) {
        final restored = _auth.currentUser;
        if (restored != null) return restored;

        if (completer.isCompleted) {
          return await completer.future;
        }

        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      if (completer.isCompleted) {
        return await completer.future;
      }

      return _auth.currentUser;
    } finally {
      await sub.cancel();
    }
  }

  static Future<void> _ensureWebPersistence() async {
    if (!kIsWeb) return;
    // FirebaseAuthWeb already boots with browser persistence configured.
    // Re-applying persistence on every reload can race with state restoration.
  }

  static User? get currentUser => _auth.currentUser;

  /// Atualiza a regiao do utilizador (ex: 'PT', 'MZ').
  static Future<void> updateUserRegion(String region) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set(
      {
        'region': region.toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Obtem a regiao atual do perfil do utilizador.
  static Future<String?> getUserRegion() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['region'] as String?;
  }

  /// Define a role activa do utilizador e marca que ele ja usou esse papel.
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

    // Importante para as regras do Firestore:
    // muitas queries do lado do prestador dependem de
    // exists(/prestadores/{uid}).
    // Se o doc ainda nao existir (primeira vez que escolhe "Sou Prestador"),
    // o Firestore pode devolver permission-denied.
    // Criamos um doc minimo aqui.
    if (r == 'prestador') {
      final prestadorRef = _db.collection('prestadores').doc(user.uid);
      final prestadorSnap = await prestadorRef.get();

      // IMPORTANTE:
      // NAO sobrescrever isOnline em cada load.
      // Isto causava o prestador voltar a OFFLINE sempre que a Home abria
      // (setActiveRole e chamado no init).
      if (!prestadorSnap.exists) {
        await prestadorRef.set(
          {
            'isOnline': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        await prestadorRef.set(
          {
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }
  }
}
