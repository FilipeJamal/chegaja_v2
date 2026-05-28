import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';

class PrestadorPortfolioManagerSection extends StatelessWidget {
  const PrestadorPortfolioManagerSection({
    super.key,
    required this.urls,
    required this.uploading,
    required this.onAdd,
    required this.onPreview,
    required this.onRemoveConfirmed,
    this.recommendedLimit = 12,
  });

  final List<String> urls;
  final bool uploading;
  final VoidCallback onAdd;
  final void Function(String url, int index) onPreview;
  final Future<void> Function(String url) onRemoveConfirmed;
  final int recommendedLimit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cleanUrls = _cleanUrls(urls);
    final count = cleanUrls.length;

    return AppCard(
      variant: AppCardVariant.outlined,
      size: AppCardSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portfolio',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ajuda o Cliente a confiar antes de te escolher.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusPill(
                label: '$count/$recommendedLimit imagens recomendadas',
                tone: count == 0
                    ? AppStatusTone.neutral
                    : count >= recommendedLimit
                        ? AppStatusTone.success
                        : AppStatusTone.info,
                icon: count == 0
                    ? Icons.photo_size_select_actual_outlined
                    : Icons.check_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mostra trabalhos reais, fotos nitidas e exemplos que expliquem bem o teu serviço.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tooltip(
                message: 'Adicionar imagens ao portfolio',
                child: AppButton(
                  label: uploading ? 'A carregar...' : 'Adicionar imagens',
                  leadingIcon: Icons.add_photo_alternate_outlined,
                  loading: uploading,
                  onPressed: uploading ? null : onAdd,
                ),
              ),
              if (count >= recommendedLimit)
                _PortfolioNotice(
                  text:
                      'Ja tens imagens suficientes. Mantem as melhores fotos visiveis.',
                  icon: Icons.tips_and_updates_outlined,
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (cleanUrls.isEmpty)
            const _PortfolioEmptyState()
          else
            _PortfolioGrid(
              urls: cleanUrls,
              onPreview: onPreview,
              onRemoveConfirmed: onRemoveConfirmed,
            ),
        ],
      ),
    );
  }

  List<String> _cleanUrls(List<String> raw) {
    final seen = <String>{};
    final clean = <String>[];
    for (final url in raw) {
      final value = url.trim();
      if (!value.startsWith('http')) continue;
      if (seen.contains(value)) continue;
      seen.add(value);
      clean.add(value);
    }
    return clean;
  }
}

class _PortfolioNotice extends StatelessWidget {
  const _PortfolioNotice({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioEmptyState extends StatelessWidget {
  const _PortfolioEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mostra o teu trabalho com fotos reais',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Adiciona fotos de trabalhos anteriores para ajudar o Cliente a confiar no teu serviço.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _PortfolioTip(label: 'Fotos nitidas'),
              _PortfolioTip(label: 'Antes/depois'),
              _PortfolioTip(label: 'Trabalhos reais'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioTip extends StatelessWidget {
  const _PortfolioTip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _PortfolioGrid extends StatelessWidget {
  const _PortfolioGrid({
    required this.urls,
    required this.onPreview,
    required this.onRemoveConfirmed,
  });

  final List<String> urls;
  final void Function(String url, int index) onPreview;
  final Future<void> Function(String url) onRemoveConfirmed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 840
            ? 4
            : width >= 560
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urls.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final url = urls[index];
            return _PortfolioImageTile(
              url: url,
              index: index,
              onPreview: () => onPreview(url, index),
              onRemoveConfirmed: () => onRemoveConfirmed(url),
            );
          },
        );
      },
    );
  }
}

class _PortfolioImageTile extends StatelessWidget {
  const _PortfolioImageTile({
    required this.url,
    required this.index,
    required this.onPreview,
    required this.onRemoveConfirmed,
  });

  final String url;
  final int index;
  final VoidCallback onPreview;
  final Future<void> Function() onRemoveConfirmed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Tooltip(
            message: 'Ver imagem',
            child: Semantics(
              label: 'Abrir imagem ${index + 1} do portfolio',
              button: true,
              child: Material(
                color: colorScheme.surfaceContainerHighest,
                child: InkWell(
                  onTap: onPreview,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Icon(
                  Icons.zoom_out_map_rounded,
                  size: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Tooltip(
              message: 'Remover imagem',
              child: Semantics(
                label: 'Remover imagem ${index + 1} do portfolio',
                button: true,
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(38, 38),
                  ),
                  onPressed: () => _confirmRemove(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover imagem?'),
          content: const Text(
            'Esta imagem será removida do teu portfólio. Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await onRemoveConfirmed();
    }
  }
}
