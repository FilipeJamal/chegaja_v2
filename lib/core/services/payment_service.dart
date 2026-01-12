import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/core/config/app_config.dart';

/// Pagamentos (Stripe) — camada Flutter.
///
/// Usa Cloud Functions para:
/// - criar PaymentIntent (server-side)
/// - criar conta Connect (prestador)
/// - gerar link de onboarding
class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  HttpsCallable _callable(String name) {
    return _functions.httpsCallable(name);
  }

  /// Fluxo: cria PaymentIntent (Cloud Function) → PaymentSheet → retorna true se pago.
  ///
  /// Requisitos:
  /// - STRIPE_PUBLISHABLE_KEY configurada no app
  /// - STRIPE_SECRET_KEY configurada nas Functions
  Future<bool> payPedido({required String pedidoId}) async {
    final pid = pedidoId.trim();
    if (pid.isEmpty) {
      throw ArgumentError('pedidoId vazio');
    }

    final res = await _callable('payments_createPaymentIntent').call({
      'pedidoId': pid,
    });

    final data = (res.data is Map)
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};

    final clientSecret = (data['clientSecret'] ?? '').toString().trim();
    if (clientSecret.isEmpty) {
      throw Exception('PaymentIntent clientSecret não retornou.');
    }

    // Inicializa PaymentSheet (modo simples, sem customer/ephemeral key)
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'ChegaJá',
        style: ThemeMode.system,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Stripe] pagamento cancelado/erro: ${e.error.localizedMessage}');
      }
      return false;
    }
  }

  /// Cria/recupera conta Connect para o prestador e abre o link de onboarding.
  Future<void> startPrestadorOnboarding() async {
    final res = await _callable('payments_createOnboardingLink').call();

    final data = (res.data is Map)
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};

    final url = (data['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw Exception('Onboarding link não retornou.');
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw Exception('Onboarding link inválido.');
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Não foi possível abrir o link de onboarding.');
    }
  }
}
