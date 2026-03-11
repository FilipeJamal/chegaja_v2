import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/navigation/app_navigator.dart';

class ReportProblemScreen extends StatefulWidget {
  final String pedidoId;
  final String userRole; // 'cliente' ou 'prestador'

  const ReportProblemScreen({
    super.key,
    required this.pedidoId,
    required this.userRole,
  });

  static void open(BuildContext context, String pedidoId, String role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportProblemScreen(
          pedidoId: pedidoId,
          userRole: role,
        ),
      ),
    );
  }

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _commentController = TextEditingController();
  String? _selectedReason;
  bool _isLoading = false;

  // Motivos baseados na role
  List<String> get _reasons {
    if (widget.userRole == 'cliente') {
      return [
        'Prestador não apareceu (No-show)',
        'Prestador atrasado',
        'Comportamento inadequado',
        'Não consigo contactar o prestador',
        'Outro',
      ];
    } else {
      return [
        'Cliente não apareceu (No-show)',
        'Localização errada/inacessível',
        'Cliente agressivo/inadequado',
        'Não consigo contactar o cliente',
        'Outro',
      ];
    }
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      AppNavigator.showSnack('Por favor selecione um motivo.');
      return;
    }

    final reason = _selectedReason!;
    final details = _commentController.text.trim();

    // Mapeamento simples de motivo -> código interno
    // Para simplificar, usamos o texto ou um slug simples
    String motivoCode = 'outro';
    if (reason.contains('No-show') || reason.contains('não apareceu')) {
      motivoCode = widget.userRole == 'cliente'
          ? 'no_show_prestador'
          : 'no_show_cliente';
    } else if (reason.contains('atrasado')) {
      motivoCode = 'atraso_prestador';
    } else if (reason.contains('Localização')) {
      motivoCode = 'local_inacessivel';
    }

    setState(() => _isLoading = true);

    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilizador não autenticado.');

      await PedidosRepo.cancelarPedido(
        pedidoId: widget.pedidoId,
        userId: uid,
        role: widget.userRole,
        motivo: motivoCode, // código interno para lógica futura
        motivoDetalhe: '$reason. $details', // Texto legível para histórico
        tipoReembolso: 'analise', // Default para disputas
      );

      if (mounted) {
        AppNavigator.showSnack('Problema reportado. O pedido foi cancelado.');
        // Voltar 2x: fechar este ecrã e voltar da tela de detalhe (opcional, ou ir para home)
        // Por segurança, fazemos pop e deixamos a stream do detalhe atualizar para "cancelado"
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppNavigator.showSnack('Erro ao reportar: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Problema'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O que aconteceu?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val),
              child: Column(
                children: _reasons
                    .map(
                      (r) => RadioListTile<String>(
                        title: Text(r),
                        value: r,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Comentários adicionais (opcional):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Descreva melhor a situação...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Reportar e Cancelar',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nota: O reporte de "No-show" (não comparência) resultará no cancelamento imediato do pedido.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
