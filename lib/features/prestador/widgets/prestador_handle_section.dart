import 'package:chegaja_v2/core/handles/handle_normalizer.dart';
import 'package:chegaja_v2/core/handles/handle_validator.dart';
import 'package:chegaja_v2/core/models/public_handle.dart';
import 'package:chegaja_v2/core/services/handle_service.dart';
import 'package:chegaja_v2/core/services/public_profile_link_service.dart';
import 'package:chegaja_v2/features/common/widgets/public_profile_share_actions.dart';
import 'package:flutter/material.dart';

typedef HandleAvailabilityCallback = Future<HandleAvailability> Function(
  String rawHandle,
);

typedef HandleReserveCallback = Future<PublicHandle> Function(
  String rawHandle,
);

class PrestadorHandleSection extends StatefulWidget {
  const PrestadorHandleSection({
    super.key,
    this.currentHandle,
    this.currentHandleDisplay,
    this.handleUpdatedAt,
    required this.onCheckAvailability,
    required this.onReserveHandle,
    this.onReserved,
    this.onCopyPublicLink,
    this.onOpenPublicLinkWhatsApp,
    this.onOpenPublicLinkFacebook,
  });

  final String? currentHandle;
  final String? currentHandleDisplay;
  final DateTime? handleUpdatedAt;
  final HandleAvailabilityCallback onCheckAvailability;
  final HandleReserveCallback onReserveHandle;
  final ValueChanged<PublicHandle>? onReserved;
  final PublicProfileCopyCallback? onCopyPublicLink;
  final PublicProfileOpenUriCallback? onOpenPublicLinkWhatsApp;
  final PublicProfileOpenUriCallback? onOpenPublicLinkFacebook;

  @override
  State<PrestadorHandleSection> createState() => _PrestadorHandleSectionState();
}

class _PrestadorHandleSectionState extends State<PrestadorHandleSection> {
  late final TextEditingController _controller;

  HandleValidationResult _validation = HandleValidator.validate('');
  HandleAvailability? _availability;
  String? _savedHandle;
  String? _savedHandleDisplay;
  String? _feedback;
  bool _checking = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.currentHandle ?? '';
    _controller = TextEditingController(text: initial);
    _validation = HandleValidator.validate(initial);
    _savedHandle = _emptyToNull(widget.currentHandle);
    _savedHandleDisplay = _displayFor(
      widget.currentHandleDisplay,
      _savedHandle,
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant PrestadorHandleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentHandle != widget.currentHandle) {
      final next = widget.currentHandle ?? '';
      if (_controller.text != next) {
        _controller.text = next;
      }
      _savedHandle = _emptyToNull(widget.currentHandle);
      _savedHandleDisplay = _displayFor(
        widget.currentHandleDisplay,
        _savedHandle,
      );
      _validation = HandleValidator.validate(next);
      _availability = null;
      _feedback = null;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final validation = HandleValidator.validate(_controller.text);
    if (validation.normalizedHandle == _validation.normalizedHandle &&
        validation.code == _validation.code &&
        _availability == null &&
        _feedback == null) {
      return;
    }

    setState(() {
      _validation = validation;
      _availability = null;
      _feedback = null;
    });
  }

  Future<void> _checkAvailability() async {
    if (!_validation.isValid || _checking || _saving) return;

    setState(() {
      _checking = true;
      _feedback = null;
    });

    try {
      final result = await widget.onCheckAvailability(_controller.text);
      if (!mounted) return;
      setState(() {
        _availability = result;
        _feedback = result.available
            ? '@${result.normalizedHandle} esta disponivel.'
            : (result.message.trim().isNotEmpty
                ? result.message.trim()
                : 'Este @handle nao esta disponivel. Escolhe outro.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availability = null;
        _feedback = 'Nao conseguimos verificar este @handle agora.';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _reserveHandle() async {
    if (!_validation.isValid || _checking || _saving) return;

    setState(() {
      _saving = true;
      _feedback = null;
    });

    try {
      final reserved = await widget.onReserveHandle(_controller.text);
      if (!mounted) return;
      setState(() {
        _savedHandle = reserved.handle;
        _savedHandleDisplay =
            _displayFor(reserved.handleDisplay, reserved.handle);
        _availability = HandleAvailability(
          normalizedHandle: reserved.handle,
          available: true,
          reason: '',
          message: '',
        );
        _feedback = '@handle guardado com sucesso.';
      });
      widget.onReserved?.call(reserved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('@handle guardado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feedback = 'Nao conseguimos guardar este @handle agora.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao conseguimos guardar este @handle agora.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final normalized = _validation.normalizedHandle;
    final previewHandle = _validation.isValid && normalized.isNotEmpty
        ? normalized
        : _savedHandle;
    final canSubmit = _validation.isValid && !_checking && !_saving;
    final hasCurrentHandle =
        _savedHandleDisplay != null && _savedHandleDisplay!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.alternate_email_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagina publica',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escolhe um @handle para o teu perfil publico no ChegaJa.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasCurrentHandle) ...[
            const SizedBox(height: 14),
            _CurrentHandlePill(label: _savedHandleDisplay!),
            const SizedBox(height: 8),
            Text(
              'Podes altera-lo, mas o antigo fica reservado para evitar confusoes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            PublicProfileShareActions(
              handle: _savedHandle,
              displayName: null,
              framed: false,
              onCopyLink: widget.onCopyPublicLink,
              onOpenWhatsApp: widget.onOpenPublicLinkWhatsApp,
              onOpenFacebook: widget.onOpenPublicLinkFacebook,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            key: const Key('prestador_handle_input'),
            controller: _controller,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: '@handle',
              prefixText: '@',
              helperText: '3 a 30 caracteres: letras, numeros, ponto, _ ou -.',
              errorText: _validation.isValid || _controller.text.trim().isEmpty
                  ? null
                  : _validation.messageForUser,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PublicLinkPreview(handle: previewHandle),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            _FeedbackBanner(
              message: _feedback!,
              positive: _availability?.available == true ||
                  _feedback == '@handle guardado com sucesso.',
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: canSubmit ? _checkAvailability : null,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                  _checking ? 'A verificar...' : 'Verificar disponibilidade',
                ),
              ),
              FilledButton.icon(
                onPressed: canSubmit ? _reserveHandle : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'A guardar...' : 'Guardar @handle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentHandlePill extends StatelessWidget {
  const _CurrentHandlePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'O teu @handle atual',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _PublicLinkPreview extends StatelessWidget {
  const _PublicLinkPreview({required this.handle});

  final String? handle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final normalized = _emptyToNull(handle);
    final link = normalized == null
        ? 'chegaja-ac88d.web.app/p/o-teu-handle'
        : PublicProfileLinkService.displayUrlForHandle(normalized);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link publico',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            link,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            normalized == null
                ? 'Escolhe e guarda um @handle para ativar o link publico.'
                : 'Este e o teu link publico.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.positive,
  });

  final String message;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = positive ? colorScheme.primary : colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String? _emptyToNull(String? value) {
  final normalized = HandleNormalizer.normalize(value ?? '');
  if (normalized.isEmpty) return null;
  return normalized;
}

String? _displayFor(String? display, String? handle) {
  final cleanDisplay = display?.trim();
  if (cleanDisplay != null && cleanDisplay.isNotEmpty) {
    return cleanDisplay.startsWith('@') ? cleanDisplay : '@$cleanDisplay';
  }
  final normalized = _emptyToNull(handle);
  return normalized == null ? null : '@$normalized';
}
