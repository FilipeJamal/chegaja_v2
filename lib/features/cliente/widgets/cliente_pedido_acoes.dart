// lib/features/cliente/widgets/cliente_pedido_acoes.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/core/services/payment_service.dart';
import 'package:chegaja_v2/core/services/auth_service.dart'; // import AuthService
import 'package:chegaja_v2/core/utils/currency_utils.dart';

/// Widget principal de ações do cliente num pedido.
///
/// Mostra:
/// 1) Proposta de prestador (faixa estimada) a aguardar decisão do cliente;
/// 2) Valor final proposto pelo prestador a aguardar confirmação do cliente.
class ClientePedidoAcoes extends StatelessWidget {
  final Pedido pedido;

  const ClientePedidoAcoes({
    super.key,
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Existe proposta de prestador à espera do cliente
    if (pedido.statusProposta == 'pendente_cliente') {
      return _PropostaPrestadorCard(pedido: pedido);
    }

    // 2) Prestador já lançou valor final e está à espera do cliente
    if (pedido.statusConfirmacaoValor == 'pendente_cliente' &&
        pedido.precoPropostoPrestador != null) {
      return _ValorFinalPendenteCard(pedido: pedido);
    }

    // 3) Outros estados → nada a mostrar
    return const SizedBox.shrink();
  }
}

/// ---------------- PROPOSTA DO PRESTADOR (FAIXA ESTIMADA) ----------------

class _PropostaPrestadorCard extends StatelessWidget {
  final Pedido pedido;

  const _PropostaPrestadorCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;
    final mensagem = pedido.mensagemPropostaPrestador?.trim();
    final expires = pedido.propostaExpiresAt;

    String expiresTxt = '';
    if (expires != null) {
      final now = DateTime.now();
      if (expires.isBefore(now)) {
        expiresTxt = 'Proposta expirada';
      } else {
        final diff = expires.difference(now);
        expiresTxt = diff.inHours > 0
            ? 'Válida por mais ${diff.inHours}h'
            : 'Válida por mais ${diff.inMinutes}min';
      }
    }

    String faixaTexto;
    if (min != null && max != null) {
      faixaTexto =
          'Estimativa: ${CurrencyUtils.format(min)} a ${CurrencyUtils.format(max)}';
    } else if (min != null) {
      faixaTexto = 'Estimativa: desde ${CurrencyUtils.format(min)}';
    } else if (max != null) {
      faixaTexto = 'Estimativa: até ${CurrencyUtils.format(max)}';
    } else {
      faixaTexto = 'Sem valor estimado.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tens uma proposta de prestador',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            faixaTexto,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          if (expiresTxt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              expiresTxt,
              style: TextStyle(
                fontSize: 12,
                color: expiresTxt.contains('expirada')
                    ? Colors.red
                    : Colors.deepOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (mensagem != null && mensagem.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              mensagem,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _recusarPrestador(context),
                  child: const Text('Rejeitar proposta'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _aceitarPrestador(context),
                  child: const Text('Aceitar este prestador'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _aceitarPrestador(BuildContext context) async {
    try {
      final user = AuthService.currentUser; // Get user
      if (user == null) return; // Guard

      await PedidoService.instance.aceitarProposta(
        pedido: pedido,
        clienteId: user.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prestador escolhido com sucesso.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar prestador: $e'),
        ),
      );
    }
  }

  Future<void> _recusarPrestador(BuildContext context) async {
    try {
      final user = AuthService.currentUser; // Get user
      if (user == null) return; // Guard

      await PedidoService.instance.rejeitarProposta(
        pedido: pedido,
        clienteId: user.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proposta rejeitada. O pedido volta a ficar disponível.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao rejeitar proposta: $e'),
        ),
      );
    }
  }
}

/// ---------------- CONFIRMAR / REJEITAR VALOR FINAL ----------------

class _ValorFinalPendenteCard extends StatelessWidget {
  final Pedido pedido;

  const _ValorFinalPendenteCard({required this.pedido});

  bool get _estaAcimaFaixa {
    final valor = pedido.precoPropostoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;

    if (valor == null) return false;

    // Aqui focamos no "acima da faixa"
    if (max != null && valor > max + 0.001) {
      return true;
    }

    return false;
  }

  String? get _textoFaixa {
    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;

    if (min != null && max != null) {
      return 'Faixa estimada: ${CurrencyUtils.format(min)} a ${CurrencyUtils.format(max)}';
    }
    if (min != null) {
      return 'Faixa estimada: desde ${CurrencyUtils.format(min)}';
    }
    if (max != null) {
      return 'Faixa estimada: até ${CurrencyUtils.format(max)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final valor = pedido.precoPropostoPrestador ?? pedido.precoFinal ?? 0;
    final acimaFaixa = _estaAcimaFaixa;
    final faixaTexto = _textoFaixa;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valor final do serviço',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total cobrado: ${CurrencyUtils.format(valor)}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          if (faixaTexto != null) ...[
            const SizedBox(height: 4),
            Text(
              faixaTexto,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          if (acimaFaixa) ...[
            const SizedBox(height: 6),
            const Text(
              'Atenção: este valor está acima da faixa estimada pelo prestador.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Confirma o valor ou indica que tens uma dúvida.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejeitarValor(context),
                  child: const Text('Tenho uma dúvida'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmarValor(context),
                  child: const Text('Confirmar valor'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarValor(BuildContext context) async {
    final valor = pedido.precoPropostoPrestador ?? pedido.precoFinal;
    if (valor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: valor final não encontrado.'),
        ),
      );
      return;
    }

    try {
      // Se o tipo de pagamento for online, cobramos primeiro via Stripe.
      if (pedido.tipoPagamento != 'dinheiro') {
        // UI simples de loading
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              content: Row(
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator()),
                  SizedBox(width: 12),
                  Expanded(child: Text('A iniciar pagamento...')),
                ],
              ),
            ),
          ),
        );

        bool ok = false;
        try {
          ok = await PaymentService.instance.payPedido(pedidoId: pedido.id);
        } finally {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // fecha loading
          }
        }

        if (!ok) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pagamento não concluído.')),
          );
          return;
        }
      }

      // Usa o PedidoService para garantir que:
      // - estado = concluido
      // - statusConfirmacaoValor = confirmado_cliente
      // - earnings / comissão atualizados
      final user = AuthService.currentUser; // Get user
      if (user == null) return; // Guard

      await PedidoService.instance.confirmarValorFinal(
        pedido: pedido,
        clienteId: user.uid,
        valorFinal: valor,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço concluído e valor confirmado.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar valor: $e'),
        ),
      );
    }
  }

  Future<void> _rejeitarValor(BuildContext context) async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('pedidos').doc(pedido.id);

      await ref.update({
        // cliente está a dizer que NÃO concorda com o valor proposto
        'statusConfirmacaoValor': 'rejeitado_cliente',

        // voltamos o fluxo do serviço para "em andamento"
        'status': 'em_andamento',
        'estado': 'em_andamento',

        // (opcional) Se quiseres limpar a proposta antiga, podes descomentar:
        // 'precoPropostoPrestador': null,

        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ⚠️ IMPORTANTE:
      // Este valor "rejeitado_cliente" é o que faz aparecer o banner laranja
      // no lado do prestador (PedidoDetalheScreen em modo prestador),
      // com o botão "Propor novo valor".

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Avisámos o prestador que tens dúvidas sobre o valor.\n'
            'Podes falar com ele pelo chat e combinar um novo valor.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registar dúvida: $e'),
        ),
      );
    }
  }
}
