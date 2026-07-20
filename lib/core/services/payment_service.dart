import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/utils/platform_caps.dart';

enum PaymentMethod { cash, mpesa, emola, stripe }

extension PaymentMethodX on PaymentMethod {
  String get storageValue => switch (this) {
        PaymentMethod.cash => 'dinheiro',
        PaymentMethod.mpesa => 'mpesa',
        PaymentMethod.emola => 'emola',
        PaymentMethod.stripe => 'stripe',
      };

  static PaymentMethod fromStorage(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'mpesa' => PaymentMethod.mpesa,
      'emola' => PaymentMethod.emola,
      'stripe' || 'online_antes' || 'online_depois' => PaymentMethod.stripe,
      _ => PaymentMethod.cash,
    };
  }
}

abstract class PaymentProvider {
  const PaymentProvider();

  PaymentMethod get method;
  String get displayName;
  bool get isAvailable;
  bool get requiresExternalConfirmation;

  Future<bool> payPedido(String pedidoId);
}

class CashPaymentProvider extends PaymentProvider {
  const CashPaymentProvider();

  @override
  PaymentMethod get method => PaymentMethod.cash;

  @override
  String get displayName => 'Dinheiro';

  @override
  bool get isAvailable => true;

  @override
  bool get requiresExternalConfirmation => false;

  @override
  Future<bool> payPedido(String pedidoId) async => true;
}

class UnavailablePaymentProvider extends PaymentProvider {
  const UnavailablePaymentProvider({
    required this.method,
    required this.displayName,
    required this.isAvailable,
  });

  @override
  final PaymentMethod method;

  @override
  final String displayName;

  @override
  final bool isAvailable;

  @override
  bool get requiresExternalConfirmation => true;

  @override
  Future<bool> payPedido(String pedidoId) async {
    if (!isAvailable) {
      throw StateError('$displayName ainda nao esta disponivel no piloto.');
    }
    throw UnimplementedError(
      '$displayName foi ativado sem uma integracao validada.',
    );
  }
}

class StripePaymentProvider extends PaymentProvider {
  StripePaymentProvider(this._functions);

  final FirebaseFunctions _functions;

  @override
  PaymentMethod get method => PaymentMethod.stripe;

  @override
  String get displayName => 'Cartao (Stripe)';

  @override
  bool get isAvailable =>
      AppConfig.stripeEnabled && PlatformCaps.supportsStripe;

  @override
  bool get requiresExternalConfirmation => true;

  @override
  Future<bool> payPedido(String pedidoId) async {
    if (!isAvailable) {
      throw StateError('O pagamento Stripe nao esta disponivel no piloto.');
    }
    final result = await _functions
        .httpsCallable('payments_createPaymentIntent')
        .call(<String, dynamic>{'pedidoId': pedidoId});
    final data = Map<String, dynamic>.from(result.data as Map);
    final clientSecret = data['clientSecret']?.toString().trim() ?? '';
    if (clientSecret.isEmpty) {
      throw StateError('O servidor nao devolveu a autorizacao de pagamento.');
    }
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
    } on StripeException catch (error) {
      if (kDebugMode) {
        debugPrint('[Stripe] ${error.error.localizedMessage}');
      }
      return false;
    }
  }
}

class PaymentService {
  PaymentService._()
      : _functions =
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  static final PaymentService instance = PaymentService._();

  final FirebaseFunctions _functions;

  PaymentProvider providerFor(String? storedMethod) {
    return switch (PaymentMethodX.fromStorage(storedMethod)) {
      PaymentMethod.cash => const CashPaymentProvider(),
      PaymentMethod.mpesa => UnavailablePaymentProvider(
          method: PaymentMethod.mpesa,
          displayName: 'M-Pesa',
          isAvailable: AppConfig.mpesaEnabled,
        ),
      PaymentMethod.emola => UnavailablePaymentProvider(
          method: PaymentMethod.emola,
          displayName: 'e-Mola',
          isAvailable: AppConfig.emolaEnabled,
        ),
      PaymentMethod.stripe => StripePaymentProvider(_functions),
    };
  }

  Future<bool> payPedido({
    required String pedidoId,
    String? paymentMethod,
  }) async {
    final id = pedidoId.trim();
    if (id.isEmpty) throw ArgumentError('pedidoId vazio');
    return providerFor(paymentMethod).payPedido(id);
  }

  Future<void> startPrestadorOnboarding() async {
    if (!AppConfig.stripeEnabled || !PlatformCaps.supportsCloudFunctions) {
      throw UnsupportedError('Onboarding Stripe indisponivel no piloto.');
    }
    final result =
        await _functions.httpsCallable('payments_createOnboardingLink').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final url = data['url']?.toString().trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw StateError('Link de onboarding invalido.');
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw StateError('Nao foi possivel abrir o onboarding.');
  }
}
