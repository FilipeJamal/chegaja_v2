import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/pedido.dart';

/// Widget principal de ações do cliente num pedido.
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
      return _ConfirmarValorCard(pedido: pedido);
    }

    // 3) Outros estados → nada a mostrar
    return const SizedBox.shrink();
  }
}

/// ---------------- PROPOSTA DO PRESTADOR ----------------

class _PropostaPrestadorCard extends StatelessWidget {
  final Pedido pedido;

  const _PropostaPrestadorCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;
    final mensagem = pedido.mensagemPropostaPrestador?.trim();

    String faixaTexto;
    if (min != null && max != null) {
      faixaTexto =
          'Estimativa: € ${min.toStringAsFixed(2)} a € ${max.toStringAsFixed(2)}';
    } else if (min != null) {
      faixaTexto =
          'Estimativa: desde € ${min.toStringAsFixed(2)}';
    } else if (max != null) {
      faixaTexto =
          'Estimativa: até € ${max.toStringAsFixed(2)}';
    } else {
      faixaTexto = 'Sem valor estimado.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueGrey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proposta do prestador',
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
          if (mensagem != null && mensagem.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              mensagem,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _recusarPrestador(context),
                  child: const Text('Escolher outro'),
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
      final ref = FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedido.id);

      await ref.update({
        'statusProposta': 'aceita_cliente',
        'status': 'aceito',
        'estado': 'aceito', // compat antigo
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prestador escolhido com sucesso.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar prestador: $e'),
        ),
      );
    }
  }

  Future<void> _recusarPrestador(BuildContext context) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedido.id);

      await ref.update({
        'statusProposta': 'rejeitada_cliente',
        'status': 'criado',
        'estado': 'criado',
        'prestadorId': null,
        'valorMinEstimadoPrestador': null,
        'valorMaxEstimadoPrestador': null,
        'mensagemPropostaPrestador': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proposta rejeitada. O pedido volta a ficar disponível.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao rejeitar proposta: $e'),
        ),
      );
    }
  }
}

/// ---------------- CONFIRMAR VALOR FINAL ----------------

class _ConfirmarValorCard extends StatelessWidget {
  final Pedido pedido;

  const _ConfirmarValorCard({required this.pedido});

  bool get _estaAcimaFaixa {
    final valor = pedido.precoPropostoPrestador;
    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;

    if (valor == null) return false;

    // Aqui focamos no "acima da faixa", como pediste
    if (max != null && valor > max + 0.001) {
      return true;
    }

    return false;
  }

  String? get _textoFaixa {
    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;

    if (min != null && max != null) {
      return 'Faixa estimada: € ${min.toStringAsFixed(2)} a € ${max.toStringAsFixed(2)}';
    }
    if (min != null) {
      return 'Mínimo estimado: € ${min.toStringAsFixed(2)}';
    }
    if (max != null) {
      return 'Máximo estimado: € ${max.toStringAsFixed(2)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final valor = pedido.precoPropostoPrestador;
    if (valor == null) {
      return const SizedBox.shrink();
    }

    final acimaFaixa = _estaAcimaFaixa;
    final faixaTexto = _textoFaixa;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
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
            'Total cobrado: € ${valor.toStringAsFixed(2)}',
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
              '⚠️ O prestador colocou um valor acima da faixa estimada.',
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
                  onPressed: () => _tenhoDuvida(context),
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

    const comissaoPercent = 0.20;
    final taxa =
        double.parse((valor * comissaoPercent).toStringAsFixed(2));
    final liquido =
        double.parse((valor - taxa).toStringAsFixed(2));

    try {
      final ref = FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedido.id);

      await ref.update({
        'precoFinal': valor,
        'statusConfirmacaoValor': 'confirmado_cliente',
        'status': 'concluido',
        'estado': 'concluido', // compat antigo
        'commissionPlatform': taxa,
        'earningsProvider': liquido,
        'earningsTotal': valor,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço concluído e valor confirmado.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar valor: $e'),
        ),
      );
    }
  }

  Future<void> _tenhoDuvida(BuildContext context) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedido.id);

      await ref.update({
        'statusConfirmacaoValor': 'rejeitado_cliente',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registámos que tens uma dúvida sobre o valor.\n'
            'Em breve esta área vai permitir falar com o suporte.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registar dúvida: $e'),
        ),
      );
    }
  }
}
