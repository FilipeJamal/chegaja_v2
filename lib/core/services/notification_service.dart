import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:chegaja_v2/core/navigation/app_navigator.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/config/app_config.dart';

const bool kRunFirebaseEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

bool _supportsFcm() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Serviço de notificações (FCM).
///
/// Faz:
/// - requestPermission (Web/iOS/Android 13+)
/// - getToken (no Web exige vapidKey)
/// - guarda token em users/{uid}
/// - escuta token refresh
/// - trata cliques (deep link para Pedido)
/// - mostra SnackBar no foreground (simples)
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  bool _initialized = false;
  static const Duration _tokenRefreshInterval = Duration(days: 30);
  static const Duration _tokenPruneAge = Duration(days: 120);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // ✅ Em testes NÃO inicializamos notificações.
    if (kRunFirebaseEmulatorTests) {
      debugPrint('[NotificationService] (TESTS) Ignorado.');
      return;
    }

    // ✅ Windows/mac/linux: NÃO suportado.
    if (!_supportsFcm()) {
      debugPrint('[NotificationService] Plataforma sem FCM (ignorado).');
      return;
    }

    final user = AuthService.currentUser;
    if (user == null) {
      debugPrint('[NotificationService] Sem user autenticado.');
      return;
    }

    // 1) Permissões
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('[NotificationService] requestPermission falhou: $e');
    }

    // 2) Token policy (refresh + cleanup)
    try {
      await _ensureTokenPolicy(user.uid);
    } catch (e) {
      debugPrint('[NotificationService] token policy falhou: $e');
    }

    // 3) Token refresh
    _tokenSub = _messaging.onTokenRefresh.listen((newToken) async {
      try {
        await _saveToken(uid: user.uid, token: newToken);
      } catch (e) {
        debugPrint('[NotificationService] onTokenRefresh erro: $e');
      }
    });

    // 4) Foreground messages
    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5) Clique em notificação (background)
    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    // 6) App aberto a partir de notificação (terminated)
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _onMessageOpened(initial);
    } catch (e) {
      debugPrint('[NotificationService] getInitialMessage erro: $e');
    }

    // 7) Deep link simples no Web por query param (?pedidoId=...)
    if (kIsWeb) {
      final pedidoId = Uri.base.queryParameters['pedidoId'];
      if (pedidoId != null && pedidoId.trim().isNotEmpty) {
        final openChat =
            (Uri.base.queryParameters['openChat'] ?? '').toLowerCase() ==
                    'true' ||
                (Uri.base.queryParameters['type'] ?? '').toLowerCase() == 'chat';

        if (openChat) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.openChatThread(pedidoId.trim());
          });
        } else {
          _openPedidoWhenReady(pedidoId.trim());
        }
      }
    }
  }

  void _openPedidoWhenReady(String pedidoId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigator.openPedidoDetalhe(pedidoId);
    });
  }

  Future<String?> _getToken() async {
    if (!_supportsFcm()) return null;

    if (kIsWeb) {
      final vapidKey = AppConfig.fcmVapidKey ?? '';
      if (vapidKey.trim().isEmpty) {
        debugPrint(
          '[NotificationService] FCM_VAPID_KEY vazio. '
          'Corre com --dart-define=FCM_VAPID_KEY=...',
        );
        return null;
      }
      return _messaging.getToken(vapidKey: vapidKey);
    }

    return _messaging.getToken();
  }

  String _platformKey() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  Future<void> _saveToken({
    required String uid,
    required String token,
    String? previousToken,
  }) async {
    final platform = _platformKey();
    final ref = _db.collection('users').doc(uid);

    await ref.set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'fcmTokens.$platform': token,
      },
      SetOptions(merge: true),
    );

    await ref.collection('fcmTokens').doc(token).set(
      {
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != token) {
      await ref.collection('fcmTokens').doc(previousToken).delete();
    }

    debugPrint('[NotificationService] Token guardado ($platform).');
  }

  Future<void> _ensureTokenPolicy(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final snap = await userRef.get();
    final data = snap.data() ?? <String, dynamic>{};

    final existingToken = (data['fcmToken'] ?? '').toString().trim();
    final updatedAt = data['fcmTokenUpdatedAt'];
    DateTime? updatedAtDt;
    if (updatedAt is Timestamp) updatedAtDt = updatedAt.toDate();

    final now = DateTime.now();
    final shouldRefresh = updatedAtDt == null ||
        now.difference(updatedAtDt) > _tokenRefreshInterval;

    if (existingToken.isEmpty || shouldRefresh) {
      final token = await _getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _saveToken(
          uid: uid,
          token: token.trim(),
          previousToken: existingToken,
        );
      }
    }

    await _pruneOldTokens(uid);
  }

  Future<void> _pruneOldTokens(String uid) async {
    final cutoff = DateTime.now().subtract(_tokenPruneAge);
    final cutoffTs = Timestamp.fromDate(cutoff);
    final tokensRef = _db.collection('users').doc(uid).collection('fcmTokens');
    final old = await tokensRef.where('updatedAt', isLessThan: cutoffTs).get();
    if (old.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in old.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title;
    final body = message.notification?.body;

    final text =
        [title, body].where((s) => s != null && s.trim().isNotEmpty).join(' — ');

    if (text.trim().isNotEmpty) {
      AppNavigator.showSnack(text);
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final data = message.data;
    final pedidoId = (data['pedidoId'] ?? '').toString().trim();
    final type = (data['type'] ?? '').toString().trim().toLowerCase();
    final openChat = type == 'chat' ||
        type == 'chat_message' ||
        (data['openChat']?.toString().toLowerCase() == 'true');

    if (pedidoId.isNotEmpty) {
      if (openChat) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNavigator.openChatThread(pedidoId);
        });
      } else {
        _openPedidoWhenReady(pedidoId);
      }
      return;
    }

    AppNavigator.showSnack('Notificação aberta.');
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    _tokenSub = null;
    _onMessageSub = null;
    _onMessageOpenedSub = null;
    _initialized = false;
  }
}
