
import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/services/support_service.dart';

class SuporteScreen extends StatefulWidget {
  final String userType; // 'cliente' ou 'prestador'

  const SuporteScreen({
    super.key,
    required this.userType,
  });

  @override
  State<SuporteScreen> createState() => _SuporteScreenState();
}

class _SuporteScreenState extends State<SuporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  
  String _selectedSubject = 'Dúvida Geral';
  bool _sending = false;

  final List<String> _subjects = [
    'Dúvida Geral',
    'Problema com um Pedido',
    'Erro na Aplicação',
    'Denúncia',
    'Outro',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      await SupportService.instance.createTicket(
        _selectedSubject,
        _messageCtrl.text.trim(),
        widget.userType,
      );

      if (!mounted) return;
      
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Pedido Enviado'),
          content: const Text(
            'Recebemos o teu pedido de suporte. A nossa equipa irá analisar e entrar em contacto em breve.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Close screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar pedido: $e')),
      );
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda e Suporte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Como podemos ajudar?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preenche o formulário abaixo e entraremos em contacto o mais breve possível.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: InputDecoration(
                  labelText: 'Assunto',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubject = val);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _messageCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Mensagem',
                  alignLabelWithHint: true,
                  hintText: 'Descreve o problema ou a tua dúvida com detalhes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor, escreve uma mensagem.';
                  }
                  if (val.trim().length < 10) {
                    return 'A mensagem é muito curta.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar Pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
