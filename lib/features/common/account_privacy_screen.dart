import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/services/account_privacy_service.dart';
import 'package:chegaja_v2/features/auth/phone_verification_screen.dart';
import 'package:chegaja_v2/features/common/legal_documents_screen.dart';
import 'package:chegaja_v2/features/common/suporte_screen.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key, required this.userType});

  final String userType;

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  bool _busy = false;

  Future<void> _requestDeletion() async {
    if (!await VerifiedPhoneGate.ensure(
      context,
      action: 'pedir a eliminação da conta',
    )) {
      return;
    }
    if (!mounted) return;
    final controller = TextEditingController();
    final confirmation = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pedir eliminação da conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O perfil público será escondido de imediato. A eliminação ocorre após 7 dias e pode ser cancelada nesse prazo. Trabalhos ativos devem ser concluídos primeiro. Registos transacionais necessários serão pseudonimizados.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Escreve ELIMINAR',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirmar pedido'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmation == null || !mounted) return;
    await _run(
      () => AccountPrivacyService.instance.requestDeletion(confirmation),
      success: 'Pedido registado. O perfil público foi escondido.',
    );
  }

  Future<void> _cancelDeletion() async {
    await _run(
      AccountPrivacyService.instance.cancelDeletion,
      success: 'Pedido de eliminação cancelado.',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível concluir: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conta e privacidade')),
      body: StreamBuilder<AccountDeletionState?>(
        stream: AccountPrivacyService.instance.watchDeletionState(),
        builder: (context, snapshot) {
          final state = snapshot.data;
          final pending = state?.isPending == true;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.shield_outlined),
                title: Text('Os teus dados não são um perfil público'),
                subtitle: Text(
                  'Telefone, morada exata, documentos, pagamentos e decisões internas permanecem em áreas privadas.',
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Termos e Política de Privacidade'),
                subtitle: const Text(
                  'Consulta a versão atualmente apresentada pela aplicação.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalDocumentsScreen(),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Privacidade, contestação e suporte'),
                subtitle: const Text('Pede ajuda ou contesta uma decisão.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SuporteScreen(userType: widget.userType),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (pending) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eliminação pendente',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state?.executeAt == null
                              ? 'A conta está agendada para eliminação.'
                              : 'Agendada para ${DateFormat('dd/MM/yyyy HH:mm').format(state!.executeAt!)}.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _cancelDeletion,
                          icon: const Icon(Icons.undo),
                          label: const Text('Cancelar eliminação'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Eliminar a conta',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta ação esconde o perfil, inicia um prazo de 7 dias e depois elimina dados pessoais. Não elimina registos financeiros ou de disputas que precisem de ser conservados; esses registos são pseudonimizados.',
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _requestDeletion,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Pedir eliminação da conta'),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          );
        },
      ),
    );
  }
}
