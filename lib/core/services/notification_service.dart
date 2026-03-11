import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:chegaja_v2/core/navigation/app_navigator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

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

  // Plugin local (para canais de notificação e som/vibração customizados)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal Android de alta importância
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'high_importance_channel', // id idêntico ao backend
    'Notificações Importantes', // título
    description: 'Avisos de pedidos, chat e estado.',
    importance: Importance.max, // SOM + VIBRAÇÁO
    playSound: true,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // ✅ Testes
    if (kRunFirebaseEmulatorTests) return;

    // ✅ Validação de Plataforma (Universal)
    if (!_supportsFcm()) {
      debugPrint('[NotificationService] FCM não suportado neste OS (Web/Desktop sem vapid?).');
      // Mesmo sem FCM, podemos querer iniciar notificações locais para desktops
      // mas o foco aqui é o push via Firebase.
      return;
    }

    final user = AuthService.currentUser;
    if (user == null) return;

    // 0) Configurar Notificações Locais (Canais) - Universal
    await _setupLocalNotifications();

    // 1) Permissões (FCM)
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('[NotificationService] requestPermission falhou: $e');
    }

    // 2) Token policy
    try {
      await _ensureTokenPolicy(user.uid);
    } catch (_) {}

    // 3) Token refresh
    _tokenSub = _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(uid: user.uid, token: newToken).catchError((_) {});
    });

    // 4) Foreground messages (FCM não mostra pop-up sozinho, nós mostramos via LocalNotifications)
    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5) Clique em notificação (background push)
    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    // 6) App terminated (Cold start via push)
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _onMessageOpened(initial);
    } catch (_) {}

    // 7) Deep link Web
    if (kIsWeb) {
      _checkWebDeepLink();
    }
  }

  Future<void> _setupLocalNotifications() async {
    // Configurações de inicialização
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Para iOS/macOS (Darwin)
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Suporte Linux (opcional, placeholder)
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    // Inicializa plugin
    await _localNotifications.initialize(
      initSettings,
      // Handler para clique em notificação LOCAL (foreground)
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _handleLocalClick(payload);
        }
      },
    );

    // Cria Canal Android (só funciona no Android)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  void _handleLocalClick(String payload) {
    // Payload esperado: "type:pedidoId" ou JSON simples
    // Por simplicidade, vamos assumir que passamos "pedidoId|type"
    final parts = payload.split('|');
    if (parts.isNotEmpty) {
      final pedidoId = parts[0];
      final type = parts.length > 1 ? parts[1] : '';
      
      final openChat = type == 'chat' || type == 'chat_message';
      
      if (openChat) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNavigator.openChatThread(pedidoId);
        });
      } else {
        _openPedidoWhenReady(pedidoId);
      }
    }
  }

  // Mostra notificação visual (Heads-up) mesmo com app aberta
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    final data = message.data;

    // Se tiver notificação visual no payload, mostramos via LocalNotifications
    if (notification != null && !kIsWeb) {
      // Constrói payload para clique
      final pedidoId = (data['pedidoId'] ?? '').toString();
      final type = (data['type'] ?? '').toString();
      final payload = '$pedidoId|$type';

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: android?.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } else {
      // Fallback para Web ou Data-only
      final title = notification?.title;
      final body = notification?.body;
      final text = [title, body].where((s) => s != null && s.isNotEmpty).join(' — ');
      if (text.isNotEmpty) {
        AppNavigator.showSnack(text);
      }
    }
  }

  void _checkWebDeepLink() {
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
  Future<void> _ensureTokenPolicy(String uid) async {
    // Implement token policy check if needed
  }

  Future<void> _saveToken({required String uid, required String token}) async {
    await _db.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  void _openPedidoWhenReady(String pedidoId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigator.openPedidoDetalhe(pedidoId);
    });
  }
}
