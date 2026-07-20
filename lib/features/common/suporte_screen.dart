import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/support_service.dart';

class SuporteScreen extends StatefulWidget {
  const SuporteScreen({super.key, required this.userType});

  final String userType;

  @override
  State<SuporteScreen> createState() => _SuporteScreenState();
}

class _SuporteScreenState extends State<SuporteScreen> {
  static const Map<String, String> _subjects = {
    'general': 'Dúvida geral',
    'order': 'Problema com um pedido',
    'technical': 'Erro na aplicação',
    'safety': 'Segurança ou denúncia',
    'account': 'Conta e acesso',
    'payment': 'Pagamento ou comissão',
    'privacy_deletion': 'Privacidade ou eliminação',
    'other': 'Outro assunto',
  };

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _sending) return;
    setState(() => _sending = true);
    try {
      final ticketId = await SupportService.instance.createTicket(
        category: _selectedCategory,
        message: _messageController.text.trim(),
        userType: widget.userType,
      );
      if (!mounted) return;
      _messageController.clear();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pedido recebido'),
          content: Text(
            ticketId.isEmpty
                ? 'A equipa de suporte recebeu a tua mensagem.'
                : 'Referência: $ticketId. Podes acompanhar o estado nesta página.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível enviar: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda e suporte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Como podemos ajudar?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Não envies documentos de identidade, palavras-passe, PINs ou dados completos de pagamento.',
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Assunto',
                    border: OutlineInputBorder(),
                  ),
                  items: _subjects.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: _sending
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Mensagem',
                    alignLabelWithHint: true,
                    hintText:
                        'Descreve o que aconteceu e o resultado esperado.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 10) {
                      return 'Escreve pelo menos 10 caracteres.';
                    }
                    if (text.length > 2000) {
                      return 'A mensagem deve ter no máximo 2000 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Enviar pedido'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Pedidos recentes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupportService.instance.watchMyTickets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return const Text(
                  'Não foi possível carregar o histórico agora.',
                );
              }
              final tickets = snapshot.data ?? const [];
              if (tickets.isEmpty) {
                return const Text('Ainda não existem pedidos de suporte.');
              }
              return Column(
                children: tickets.map((ticket) {
                  final status = ticket['status']?.toString() ?? 'open';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.support_agent_outlined),
                    title: Text(ticket['subject']?.toString() ?? 'Suporte'),
                    subtitle: Text(_statusLabel(status)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'in_progress' => 'Em análise',
        'resolved' => 'Resolvido',
        'closed' => 'Fechado',
        _ => 'Recebido',
      };
}
