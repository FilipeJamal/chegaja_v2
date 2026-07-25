import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/config/market_config.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:chegaja_v2/features/common/legal_documents_screen.dart';

class VerifiedPhoneGate {
  const VerifiedPhoneGate._();

  static Future<bool> ensure(
    BuildContext context, {
    required String action,
  }) async {
    var identityConfirmedNow = false;
    if (!AuthService.hasVerifiedPhone) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PhoneVerificationScreen(action: action),
        ),
      );
      if (result != true || !AuthService.hasVerifiedPhone || !context.mounted) {
        return false;
      }
      identityConfirmedNow = true;
    }

    if (identityConfirmedNow) {
      final activeRole = RoleModeService.instance.currentRole;
      if (activeRole != null) {
        try {
          await AuthService.setActiveRole(activeRole);
        } catch (error, stackTrace) {
          debugPrint('[PhoneGate] sincronizacao do papel falhou: $error');
          if (kDebugMode) {
            debugPrintStack(stackTrace: stackTrace);
          }
          return false;
        }
      }
    }
    if (!context.mounted) return false;
    return LegalConsentGate.ensure(context, action: action);
  }
}

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key, required this.action});

  final String action;

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  late final MarketConfig _market;
  late final TextEditingController _phoneController;
  final _codeController = TextEditingController();
  PhoneVerificationSession? _session;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _market = AppConfig.pilotMarket;
    _phoneController = TextEditingController(text: _market.callingCode);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _normalizedPhone() {
    return AuthService.normalizePhoneForMarket(
      _phoneController.text,
      market: _market,
    );
  }

  String get _phoneFormatMessage {
    final country = AuthService.phoneCountryLabelForMarket(_market);
    final example = AuthService.phoneExampleForMarket(_market);
    return 'Confirma um número móvel de $country no formato $example.';
  }

  Future<void> _sendCode() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final normalizedPhone = _normalizedPhone();
      if (!AuthService.isValidPhoneForMarket(
        normalizedPhone,
        market: _market,
      )) {
        if (mounted) setState(() => _error = _phoneFormatMessage);
        return;
      }
      final session = await AuthService.requestPhoneCode(
        normalizedPhone,
        forceResendingToken: _session?.resendToken,
      );
      if (!mounted) return;
      if (session.autoVerified && AuthService.hasVerifiedPhone) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _session = session);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageForAuthError(error));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCode() async {
    final session = _session;
    if (_busy || session == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.confirmPhoneCode(
        session: session,
        smsCode: _codeController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageForAuthError(error));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageForAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code':
        return 'O codigo SMS nao esta correto.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarda alguns minutos e tenta novamente.';
      case 'invalid-phone-number':
        return _phoneFormatMessage;
      case 'quota-exceeded':
        return 'O envio de SMS esta temporariamente indisponivel.';
      default:
        return error.message ?? 'Nao foi possivel confirmar o telefone.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeSent = _session != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar telefone')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.phonelink_lock_outlined, size: 64),
            const SizedBox(height: 20),
            Text(
              'Confirma o teu telefone para ${widget.action}.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'O número é privado. Serve para proteger contas, pedidos, '
              'pagamentos e suporte. Neste piloto, confirma um número móvel '
              'de ${AuthService.phoneCountryLabelForMarket(_market)}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextField(
              key: const Key('phone_verification_phone_field'),
              controller: _phoneController,
              enabled: !_busy && !codeSent,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefone',
                hintText: AuthService.phoneExampleForMarket(_market),
                border: const OutlineInputBorder(),
              ),
            ),
            if (codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                key: const Key('phone_verification_code_field'),
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Codigo SMS',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('phone_verification_primary_button'),
              onPressed: _busy ? null : (codeSent ? _confirmCode : _sendCode),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(codeSent ? 'Confirmar codigo' : 'Enviar codigo'),
            ),
            if (codeSent)
              TextButton(
                onPressed: _busy ? null : _sendCode,
                child: const Text('Reenviar codigo'),
              ),
          ],
        ),
      ),
    );
  }
}
