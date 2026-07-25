import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chegaja_v2/core/data/firestore_collections.dart';
import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/config/market_config.dart';

class PhoneVerificationSession {
  const PhoneVerificationSession({
    this.verificationId,
    this.resendToken,
    this.webConfirmation,
    this.autoVerified = false,
  });

  final String? verificationId;
  final int? resendToken;
  final ConfirmationResult? webConfirmation;
  final bool autoVerified;
}

/// Servico responsavel pela autenticacao e pelo registo basico do utilizador
/// na colecao privada `users_private` do Firestore.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);
  static Future<User>? _pendingAnonymousEnsure;
  static const String _seenUserFlagKey = 'auth.seenPersistedUser';
  static const List<Duration> _firestoreBootstrapRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 12),
  ];

  static DocumentReference<Map<String, dynamic>> get userRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');
    return _db.collection(FirestoreCollections.usersPrivate).doc(uid);
  }

  /// Garante que existe um utilizador autenticado.
  /// Se ainda nao houver, faz login anonimo.
  ///
  /// A sessao anonima serve apenas para explorar a aplicacao. Ela nao cria
  /// nem atualiza `users_private`; o perfil privado passa a existir depois
  /// de uma identidade real ser confirmada.
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
    if (user == null && !_shouldSkipPreSignInRestoreWait) {
      user = await _waitForRestoredUser(
        timeout: await _restoreTimeoutBeforeAnonymousSignIn(),
      );
    }

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
    final signedUser = user;

    await _markUserSeen();

    if (signedUser.isAnonymous) {
      return signedUser;
    }

    final userDocRef =
        _db.collection(FirestoreCollections.usersPrivate).doc(signedUser.uid);

    // Se ja existir, nao sobrescrevemos campos importantes,
    // mas garantimos default region se nao existir.
    final doc = await _withFirestoreBootstrapRetry(userDocRef.get);
    if (!doc.exists) {
      await _withFirestoreBootstrapRetry(
        () => userDocRef.set(
          {
            'uid': signedUser.uid,
            'isAnonymous': signedUser.isAnonymous,
            'region': AppConfig.pilotMarket.countryCode,
            'lastLoginAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
      );
    } else {
      await _withFirestoreBootstrapRetry(
        () => userDocRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        }),
      );
    }

    return signedUser;
  }

  static Future<T> _withFirestoreBootstrapRetry<T>(
    Future<T> Function() action,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0;
        attempt <= _firestoreBootstrapRetryDelays.length;
        attempt++) {
      try {
        return await action();
      } on FirebaseException catch (error, stackTrace) {
        if (!_isTransientFirestoreBootstrapError(error) ||
            attempt == _firestoreBootstrapRetryDelays.length) {
          rethrow;
        }
        lastError = error;
        lastStackTrace = stackTrace;
      }

      await Future<void>.delayed(_firestoreBootstrapRetryDelays[attempt]);
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  static bool _isTransientFirestoreBootstrapError(FirebaseException error) {
    return error.plugin == 'cloud_firestore' &&
        (error.code == 'unavailable' ||
            error.code == 'deadline-exceeded' ||
            error.code == 'internal');
  }

  static Future<Duration> _restoreTimeoutBeforeAnonymousSignIn() async {
    if (!kIsWeb) return const Duration(seconds: 2);

    final seenPersistedUser = await _hasSeenUser();
    if (seenPersistedUser) {
      return const Duration(seconds: 8);
    }

    return const Duration(seconds: 2);
  }

  static bool get _shouldSkipPreSignInRestoreWait {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
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

  static bool get hasVerifiedPhone => isVerifiedPhoneIdentity(
        isAnonymous: currentUser?.isAnonymous ?? true,
        phoneNumber: currentUser?.phoneNumber,
      );

  static bool isVerifiedPhoneIdentity({
    required bool isAnonymous,
    required String? phoneNumber,
  }) {
    return !isAnonymous && (phoneNumber?.trim().isNotEmpty ?? false);
  }

  /// Normalizes a local or international number against the selected market.
  ///
  /// An explicit international prefix is preserved so that validation can
  /// reject a number from another market instead of silently rewriting it.
  static String normalizePhoneForMarket(
    String rawPhone, {
    MarketConfig? market,
  }) {
    final selectedMarket = market ?? AppConfig.pilotMarket;
    final trimmed = rawPhone.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return selectedMarket.callingCode;
    if (trimmed.startsWith('+')) return '+$digits';
    if (trimmed.startsWith('00') && digits.length > 2) {
      return '+${digits.substring(2)}';
    }

    final callingCodeDigits = selectedMarket.callingCode.replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (digits.startsWith(callingCodeDigits)) return '+$digits';

    final nationalDigits =
        digits.startsWith('0') ? digits.substring(1) : digits;
    return '${selectedMarket.callingCode}$nationalDigits';
  }

  static bool isValidPhoneForMarket(
    String rawPhone, {
    MarketConfig? market,
  }) {
    final selectedMarket = market ?? AppConfig.pilotMarket;
    final normalized = normalizePhoneForMarket(
      rawPhone,
      market: selectedMarket,
    );
    if (!normalized.startsWith(selectedMarket.callingCode)) return false;

    final nationalNumber =
        normalized.substring(selectedMarket.callingCode.length);
    switch (selectedMarket.countryCode) {
      case 'PT':
        // Portuguese mobile-format number suitable for receiving an SMS OTP.
        // Firebase remains the authority that the number can receive the OTP.
        return RegExp(r'^9\d{8}$').hasMatch(nationalNumber);
      case 'MZ':
        // Historical Maputo adaptation: Mozambican mobile numbers.
        return RegExp(r'^8\d{8}$').hasMatch(nationalNumber);
      default:
        final allDigits = normalized.substring(1);
        return RegExp(r'^\d{8,15}$').hasMatch(allDigits) &&
            nationalNumber.isNotEmpty;
    }
  }

  static String phoneExampleForMarket([MarketConfig? market]) {
    final selectedMarket = market ?? AppConfig.pilotMarket;
    switch (selectedMarket.countryCode) {
      case 'PT':
        return '${selectedMarket.callingCode} 912 345 678';
      case 'MZ':
        return '${selectedMarket.callingCode} 84 000 0000';
      default:
        return '${selectedMarket.callingCode} ...';
    }
  }

  static String phoneCountryLabelForMarket([MarketConfig? market]) {
    final selectedMarket = market ?? AppConfig.pilotMarket;
    switch (selectedMarket.countryCode) {
      case 'PT':
        return 'Portugal';
      case 'MZ':
        return 'Moçambique';
      default:
        return selectedMarket.countryCode;
    }
  }

  /// Sends an OTP while preserving the current anonymous account.
  static Future<PhoneVerificationSession> requestPhoneCode(
    String phoneE164, {
    int? forceResendingToken,
  }) async {
    final market = AppConfig.pilotMarket;
    final phone = normalizePhoneForMarket(phoneE164, market: market);
    if (!isValidPhoneForMarket(phone, market: market)) {
      throw ArgumentError(
        'Número de telefone inválido. Usa o formato '
        '${phoneExampleForMarket(market)}.',
      );
    }
    final user = await ensureSignedInAnonymously();

    if (kIsWeb) {
      final confirmation = await user.linkWithPhoneNumber(phone);
      return PhoneVerificationSession(webConfirmation: confirmation);
    }

    final completer = Completer<PhoneVerificationSession>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          await _completePhoneCredential(credential);
          if (!completer.isCompleted) {
            completer.complete(
              const PhoneVerificationSession(autoVerified: true),
            );
          }
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(verificationId: verificationId),
          );
        }
      },
    );
    return completer.future.timeout(const Duration(minutes: 2));
  }

  static Future<User> confirmPhoneCode({
    required PhoneVerificationSession session,
    required String smsCode,
  }) async {
    final code = smsCode.trim();
    if (code.length < 4) throw ArgumentError('Codigo SMS invalido.');

    if (session.autoVerified) {
      return _auth.currentUser ??
          (throw StateError('Telefone confirmado sem sessao ativa.'));
    }

    if (session.webConfirmation != null) {
      final result = await session.webConfirmation!.confirm(code);
      await _syncPhoneIdentity();
      return result.user ??
          _auth.currentUser ??
          (throw StateError('Telefone confirmado sem sessao ativa.'));
    }

    final verificationId = session.verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      throw StateError('Sessao de verificacao expirada.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return _completePhoneCredential(credential);
  }

  static Future<User> _completePhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    final sourceUser = _auth.currentUser;
    if (sourceUser == null) throw StateError('Sessao anonima inexistente.');
    try {
      final linked = await sourceUser.linkWithCredential(credential);
      await _syncPhoneIdentity();
      return linked.user ?? _auth.currentUser!;
    } on FirebaseAuthException catch (error) {
      if (!sourceUser.isAnonymous ||
          !{
            'credential-already-in-use',
            'account-exists-with-different-credential',
          }.contains(error.code)) {
        rethrow;
      }

      final sourceIdToken = await sourceUser.getIdToken(true);
      if (sourceIdToken == null || sourceIdToken.isEmpty) rethrow;
      final signedIn = await _auth.signInWithCredential(credential);
      await _functions.httpsCallable('auth_mergeAnonymousData').call({
        'sourceIdToken': sourceIdToken,
      });
      await _syncPhoneIdentity();
      return signedIn.user ?? _auth.currentUser!;
    }
  }

  static Future<void> _syncPhoneIdentity() async {
    await _auth.currentUser?.getIdToken(true);
    await _functions.httpsCallable('auth_syncPhoneIdentity').call();
  }

  static Future<User?> waitForCurrentUser({
    Duration? timeout,
  }) {
    return _waitForRestoredUser(timeout: timeout);
  }

  /// Atualiza a regiao do utilizador (ex: 'PT', 'MZ').
  static Future<void> updateUserRegion(String region) async {
    final user = _auth.currentUser;
    if (user == null ||
        !isVerifiedPhoneIdentity(
          isAnonymous: user.isAnonymous,
          phoneNumber: user.phoneNumber,
        )) {
      return;
    }

    await _db.collection(FirestoreCollections.usersPrivate).doc(user.uid).set(
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
    if (user == null ||
        !isVerifiedPhoneIdentity(
          isAnonymous: user.isAnonymous,
          phoneNumber: user.phoneNumber,
        )) {
      return null;
    }

    final doc = await _db
        .collection(FirestoreCollections.usersPrivate)
        .doc(user.uid)
        .get();
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

    // A escolha de papel e persistida localmente por RoleModeService. Uma
    // sessao temporaria nao deve criar perfil privado, perfil publico ou
    // estado de dispatch no backend.
    if (!isVerifiedPhoneIdentity(
      isAnonymous: user.isAnonymous,
      phoneNumber: user.phoneNumber,
    )) {
      return;
    }

    final userPrivateRef =
        _db.collection(FirestoreCollections.usersPrivate).doc(user.uid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userPrivateRef);
      final roles = mergeRoleHistory(
        snapshot.data()?['roles'],
        activeRole: r,
      );
      transaction.set(
        userPrivateRef,
        {
          'activeRole': r,
          'roles': roles,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    // Importante para as regras do Firestore:
    // muitas queries do lado do prestador dependem de
    // exists(/prestadores/{uid}).
    // Se o doc ainda nao existir (primeira vez que escolhe "Sou Prestador"),
    // o Firestore pode devolver permission-denied.
    // Criamos um doc minimo aqui.
    if (r == 'prestador') {
      final publicRef =
          _db.collection(FirestoreCollections.providerPublic).doc(user.uid);
      final dispatchRef = _db
          .collection(FirestoreCollections.providerDispatchPrivate)
          .doc(user.uid);
      final publicSnap = await publicRef.get();
      final dispatchSnap = await dispatchRef.get();

      // IMPORTANTE:
      // NAO sobrescrever isOnline em cada load.
      // Isto causava o prestador voltar a OFFLINE sempre que a Home abria
      // (setActiveRole e chamado no init).
      final batch = _db.batch();
      batch.set(
        publicRef,
        {
          'uid': user.uid,
          if (!publicSnap.exists) 'isSearchable': false,
          if (!publicSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        dispatchRef,
        {
          'providerId': user.uid,
          if (!dispatchSnap.exists) 'isOnline': false,
          if (!dispatchSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      if (hasVerifiedPhone) {
        await _syncPhoneIdentity();
      }
    }
  }

  @visibleForTesting
  static Map<String, bool> mergeRoleHistory(
    Object? currentRoles, {
    required String activeRole,
  }) {
    final normalizedRole = activeRole.trim().toLowerCase();
    if (normalizedRole != 'cliente' && normalizedRole != 'prestador') {
      throw ArgumentError.value(
        activeRole,
        'activeRole',
        'Must be cliente or prestador.',
      );
    }

    final roles = <String, bool>{};
    if (currentRoles is Map) {
      for (final role in const ['cliente', 'prestador']) {
        if (currentRoles[role] == true) roles[role] = true;
      }
    }
    roles[normalizedRole] = true;
    return Map.unmodifiable(roles);
  }
}
