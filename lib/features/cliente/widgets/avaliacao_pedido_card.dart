// lib/features/cliente/widgets/avaliacao_pedido_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/avaliacao_service.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

typedef AvaliacaoPedidoSubmit = Future<void> Function({
  required String pedidoId,
  required String clienteId,
  required String prestadorId,
  required int estrelas,
  String? comentario,
});

/// Card that shows an existing review or a form to submit one.
class AvaliacaoPedidoCard extends StatefulWidget {
  static const int commentLimit = 500;

  final String pedidoId;
  final String prestadorId;
  final String clienteId;
  final FirebaseFirestore? firestore;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? avaliacaoStream;
  final AvaliacaoPedidoSubmit? onSubmit;

  const AvaliacaoPedidoCard({
    super.key,
    required this.pedidoId,
    required this.prestadorId,
    required this.clienteId,
    this.firestore,
    this.avaliacaoStream,
    this.onSubmit,
  });

  @override
  State<AvaliacaoPedidoCard> createState() => _AvaliacaoPedidoCardState();
}

class _AvaliacaoPedidoCardState extends State<AvaliacaoPedidoCard> {
  final TextEditingController _comentarioCtrl = TextEditingController();
  int _rating = 0;
  bool _sending = false;
  String? _inlineError;

  FirebaseFirestore get _db => widget.firestore ?? FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _comentarioCtrl.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    _comentarioCtrl.removeListener(_onCommentChanged);
    _comentarioCtrl.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    setState(() {
      if (_comentarioCtrl.text.length <= AvaliacaoPedidoCard.commentLimit &&
          _inlineError == _commentLimitError) {
        _inlineError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docId = '${widget.pedidoId}_${widget.clienteId}';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: widget.avaliacaoStream ??
          _db.collection('avaliacoes').doc(docId).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _stateCard(
            icon: Icons.error_outline_rounded,
            title: 'Não conseguimos carregar a avaliação agora.',
            body: 'Tenta novamente daqui a pouco.',
            tone: _AvaliacaoTone.error,
          );
        }

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _stateCard(
            icon: Icons.hourglass_top_rounded,
            title: 'A carregar avaliação...',
            body: 'Estamos a confirmar se já enviaste feedback.',
            tone: _AvaliacaoTone.info,
          );
        }

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _AvaliacaoSurface(
      tone: _AvaliacaoTone.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            icon: Icons.check_circle_outline_rounded,
            title: l10n.ratingSentTitle,
            subtitle: 'Obrigado pelo feedback.',
            tone: _AvaliacaoTone.success,
          ),
          const SizedBox(height: 12),
          _starRow(estrelas, readOnly: true),
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  comentario,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avaliacaoForm() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commentLength = _comentarioCtrl.text.length;
    final isOverLimit = commentLength > AvaliacaoPedidoCard.commentLimit;

    return _AvaliacaoSurface(
      tone: _AvaliacaoTone.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(
            icon: Icons.star_outline_rounded,
            title: 'Avalia este prestador',
            subtitle:
                'A tua avaliação ajuda outros clientes depois do serviço.',
            tone: _AvaliacaoTone.info,
          ),
          const SizedBox(height: 12),
          _starRow(_rating, readOnly: false),
          if (_rating > 0)
            SizedBox(
              key: Key('avaliacao_rating_value_$_rating'),
              height: 0,
              width: 0,
            ),
          const SizedBox(height: 10),
          Text(
            l10n.ratingPrompt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('avaliacao_comment_field'),
            controller: _comentarioCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.ratingCommentLabel,
              border: const OutlineInputBorder(),
              errorText: isOverLimit ? _commentLimitError : null,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$commentLength/${AvaliacaoPedidoCard.commentLimit}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isOverLimit
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (_inlineError != null) ...[
            const SizedBox(height: 8),
            Text(
              _inlineError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final stars = List<Widget>.generate(5, (index) {
      final int starValue = index + 1;
      final bool selected = value >= starValue;

      return IconButton(
        key: Key('avaliacao_star_$starValue'),
        tooltip: readOnly ? null : 'Dar $starValue estrela(s)',
        iconSize: 30,
        icon: Icon(
          selected ? Icons.star : Icons.star_border,
          color: selected ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
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

  String get _commentLimitError =>
      'O comentário não pode passar de 500 caracteres.';

  Future<void> _enviar() async {
    final l10n = AppLocalizations.of(context)!;
    final comentario = _comentarioCtrl.text.trim();
    if (_rating < 1) {
      setState(() => _inlineError = l10n.ratingSelectError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingSelectError)),
      );
      return;
    }

    if (comentario.length > AvaliacaoPedidoCard.commentLimit) {
      setState(() => _inlineError = null);
      return;
    }

    setState(() => _inlineError = null);
    setState(() => _sending = true);

    try {
      final submit = widget.onSubmit ?? _defaultSubmit;
      await submit(
        pedidoId: widget.pedidoId,
        clienteId: widget.clienteId,
        prestadorId: widget.prestadorId,
        estrelas: _rating,
        comentario: comentario,
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

  Future<void> _defaultSubmit({
    required String pedidoId,
    required String clienteId,
    required String prestadorId,
    required int estrelas,
    String? comentario,
  }) {
    return AvaliacaoService.instance.enviarAvaliacao(
      pedidoId: pedidoId,
      clienteId: clienteId,
      prestadorId: prestadorId,
      estrelas: estrelas,
      comentario: comentario,
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String body,
    required _AvaliacaoTone tone,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _AvaliacaoSurface(
      tone: tone,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToneIcon(icon: icon, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AvaliacaoTone { info, success, error }

class _AvaliacaoSurface extends StatelessWidget {
  final _AvaliacaoTone tone;
  final Widget child;

  const _AvaliacaoSurface({
    required this.tone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toneColor = _toneColor(colorScheme, tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toneColor.withValues(alpha: 0.28)),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _AvaliacaoTone tone;

  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToneIcon(icon: icon, tone: tone),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToneIcon extends StatelessWidget {
  final IconData icon;
  final _AvaliacaoTone tone;

  const _ToneIcon({
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toneColor = _toneColor(colorScheme, tone);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: toneColor),
    );
  }
}

Color _toneColor(ColorScheme colorScheme, _AvaliacaoTone tone) {
  switch (tone) {
    case _AvaliacaoTone.success:
      return colorScheme.primary;
    case _AvaliacaoTone.error:
      return colorScheme.error;
    case _AvaliacaoTone.info:
      return colorScheme.secondary;
  }
}
