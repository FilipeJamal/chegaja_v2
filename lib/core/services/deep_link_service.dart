import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';

import 'package:chegaja_v2/core/handles/handle_validator.dart';
import 'package:chegaja_v2/core/navigation/app_navigator.dart';

/// Deep links (Android App Links / iOS Universal Links / custom schemes).
///
/// Suporta:
/// - https://teu-dominio/pedido/<pedidoId>
/// - https://teu-dominio/chat/<pedidoId>
/// - chegaja://pedido/<pedidoId>
/// - chegaja://chat/<pedidoId>
/// - https://teu-dominio/p/<handle>
/// - chegaja://p/<handle>
/// - ...?pedidoId=<pedidoId>
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1) Link inicial (app aberta via link)
    try {
      // Nas versões atuais do `app_links`, o método correto é `getInitialLink()`
      // (o antigo `getInitialAppLink()` já não existe).
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleUri(uri);
      }
    } catch (e) {
      debugPrint('[DeepLinkService] getInitialLink erro: $e');
    }

    // 2) Links enquanto a app está a correr
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (err) {
        debugPrint('[DeepLinkService] uriLinkStream erro: $err');
      },
    );
  }

  void _handleUri(Uri uri) {
    final publicHandle = _extractPublicProfileHandle(uri);
    if (publicHandle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigator.openPublicProfileHandle(publicHandle);
      });
      return;
    }

    final pedidoId = _extractPedidoId(uri);
    final openChat = _extractOpenChat(uri);

    if (pedidoId == null) return;

    // Garante que o Navigator já existe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (openChat) {
        AppNavigator.openChatThread(pedidoId);
      } else {
        AppNavigator.openPedidoDetalhe(pedidoId);
      }
    });
  }

  @visibleForTesting
  void handleUriForTesting(Uri uri) => _handleUri(uri);

  @visibleForTesting
  static String? extractPedidoIdForTesting(Uri uri) => _extractPedidoId(uri);

  @visibleForTesting
  static bool extractOpenChatForTesting(Uri uri) => _extractOpenChat(uri);

  @visibleForTesting
  static String? extractPublicProfileHandleForTesting(Uri uri) =>
      _extractPublicProfileHandle(uri);

  static bool _extractOpenChat(Uri uri) {
    // /chat/<pedidoId> ou host chat
    if (uri.host.toLowerCase() == 'chat') return true;
    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first.toLowerCase() == 'chat') {
      return true;
    }
    final t = (uri.queryParameters['type'] ?? '').toLowerCase();
    return t == 'chat' || t == 'chat_message';
  }

  static String? _extractPedidoId(Uri uri) {
    // 1) query param
    final qp = uri.queryParameters['pedidoId'];
    if (qp != null && qp.trim().isNotEmpty) return qp.trim();

    // 2) /pedido/<id> ou /chat/<id>
    if (uri.pathSegments.length >= 2) {
      final first = uri.pathSegments[0].toLowerCase();
      if (first == 'pedido' || first == 'chat') {
        final id = uri.pathSegments[1].trim();
        if (id.isNotEmpty) return id;
      }
    }

    // 3) chegaja://pedido/<id> (host=pedido, pathSegments=[id])
    final host = uri.host.toLowerCase();
    if ((host == 'pedido' || host == 'chat') && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first.trim();
      if (id.isNotEmpty) return id;
    }

    return null;
  }

  static String? _extractPublicProfileHandle(Uri uri) {
    final queryHandle = uri.queryParameters['handle'];
    if (queryHandle != null && queryHandle.trim().isNotEmpty) {
      return _normalizePublicHandle(queryHandle);
    }

    if (uri.pathSegments.length >= 2 &&
        uri.pathSegments.first.toLowerCase() == 'p') {
      return _normalizePublicHandle(uri.pathSegments[1]);
    }

    if (uri.host.toLowerCase() == 'p' && uri.pathSegments.isNotEmpty) {
      return _normalizePublicHandle(uri.pathSegments.first);
    }

    return null;
  }

  static String? _normalizePublicHandle(String rawHandle) {
    final validation = HandleValidator.validate(rawHandle);
    return validation.isValid ? validation.normalizedHandle : null;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
