// lib/features/cliente/widgets/avaliacao_pedido_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/avaliacao_service.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

/// Card that shows an existing review or a form to submit one.
class AvaliacaoPedidoCard extends StatefulWidget {
  final String pedidoId;
  final String prestadorId;
  final String clienteId;

  const AvaliacaoPedidoCard({
    super.key,
    required this.pedidoId,
    required this.prestadorId,
    required this.clienteId,
  });

  @override
  State<AvaliacaoPedidoCard> createState() => _AvaliacaoPedidoCardState();
}

class _AvaliacaoPedidoCardState extends State<AvaliacaoPedidoCard> {
  final TextEditingController _comentarioCtrl = TextEditingController();
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docId = '${widget.pedidoId}_${widget.clienteId}';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('avaliacoes')
          .doc(docId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final hasData = snap.data?.exists == true && data != null;

        if (hasData) {
          final estrelasRaw = data['estrelas'] ?? data['rating'] ?? 0;
          final int estrelas = (estrelasRaw is num) ? estrelasRaw.toInt() : 0;
          final String comentario =
              (data['comentario'] ?? '').toString().trim();

          return _avaliacaoResumo(
            estrelas: estrelas,
            comentario: comentario,
          );
        }

        return _avaliacaoForm();
      },
    );
  }

  Widget _avaliacaoResumo({
    required int estrelas,
    required String comentario,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ratingSentTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _starRow(estrelas, readOnly: true),
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comentario,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avaliacaoForm() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ratingProviderTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ratingPrompt,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          _starRow(_rating, readOnly: false),
          const SizedBox(height: 8),
          TextField(
            controller: _comentarioCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.ratingCommentLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _enviar,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.ratingSendAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starRow(int value, {required bool readOnly}) {
    final stars = List<Widget>.generate(5, (index) {
      final int starValue = index + 1;
      final bool selected = value >= starValue;

      return IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(
          selected ? Icons.star : Icons.star_border,
          color: selected ? Colors.amber[700] : Colors.grey,
        ),
        onPressed: readOnly || _sending
            ? null
            : () {
                setState(() => _rating = starValue);
              },
      );
    });

    return Row(children: stars);
  }

  Future<void> _enviar() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingSelectError)),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await AvaliacaoService.instance.enviarAvaliacao(
        pedidoId: widget.pedidoId,
        clienteId: widget.clienteId,
        prestadorId: widget.prestadorId,
        estrelas: _rating,
        comentario: _comentarioCtrl.text,
      );

      if (!mounted) return;
      _comentarioCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingSentSnack)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
