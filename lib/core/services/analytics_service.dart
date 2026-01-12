// lib/core/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, Map<String, Object> params) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: params,
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Analytics] logEvent erro: $e');
      }
    }
  }

  Future<void> logPedidoEvent({
    required String name,
    required String pedidoId,
    required String estado,
    String? modo,
    String? tipoPreco,
    String? role,
  }) {
    return logEvent(name, {
      'pedido_id': pedidoId,
      'estado': estado,
      if (modo != null) 'modo': modo,
      if (tipoPreco != null) 'tipo_preco': tipoPreco,
      if (role != null) 'role': role,
    });
  }
}
