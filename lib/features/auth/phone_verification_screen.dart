import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/features/common/legal_documents_screen.dart';

class VerifiedPhoneGate {
  const VerifiedPhoneGate._();

  static Future<bool> ensure(
    BuildContext context, {
    required String action,
  }) async {
    if (!AuthService.hasVerifiedPhone) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PhoneVerificationScreen(action: action),
        ),
      );
      if (result != true || !AuthService.hasVerifiedPhone || !context.mounted) {
        return false;
      }
    }
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
  final _phoneController = TextEditingController(text: '+258');
  final _codeController = TextEditingController();
  PhoneVerificationSession? _session;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _normalizedPhone() {
    final compact = _phoneController.text.replaceAll(RegExp(r'[^+\d]'), '');
    if (compact.startsWith('+')) return compact;
    if (compact.length == 9 && compact.startsWith('8')) return '+258$compact';
    return compact;
  }

  Future<void> _sendCode() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await AuthService.requestPhoneCode(
        _normalizedPhone(),
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
        return 'Confirma o numero e usa o formato +258...';
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
            const Text(
              'O numero e privado. Serve para proteger contas, pedidos, pagamentos e suporte.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextField(
              key: const Key('phone_verification_phone_field'),
              controller: _phoneController,
              enabled: !_busy && !codeSent,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: '+258 84 000 0000',
                border: OutlineInputBorder(),
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
