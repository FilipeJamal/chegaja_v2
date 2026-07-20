import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/features/common/trust_safety/report_content_sheet.dart';
import 'package:chegaja_v2/core/services/private_storage_media_service.dart';
import 'package:chegaja_v2/core/widgets/private_storage_image.dart';

/// Visualizador simples de imagens (URLs) em ecrã inteiro, com zoom/pan.
///
/// - Swipe entre várias imagens (PageView)
/// - Pinch-to-zoom (InteractiveViewer)
///
/// Uso:
/// ```dart
/// await MediaViewerScreen.open(context, urls: urls, initialIndex: i);
/// ```
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.title,
    this.heroTagBuilder,
    this.enableReport = false,
    this.reportTargetOwnerId,
    this.onReportSubmit,
  });

  /// URLs das imagens.
  final List<String> urls;

  /// Índice inicial a abrir.
  final int initialIndex;

  /// Título opcional.
  final String? title;

  /// Se quiseres Hero animation, passa um builder que devolve a tag.
  /// (Tem de coincidir com a tag do widget de origem.)
  final String Function(String url, int index)? heroTagBuilder;

  /// Mostra acao discreta para denunciar a imagem atual.
  final bool enableReport;
  final String? reportTargetOwnerId;
  final ReportSubmitCallback? onReportSubmit;

  /// Helper para abrir rapidamente.
  static Future<void> open(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    String? title,
    String Function(String url, int index)? heroTagBuilder,
    bool enableReport = false,
    String? reportTargetOwnerId,
    ReportSubmitCallback? onReportSubmit,
  }) {
    if (urls.isEmpty) return Future.value();

    final safeIndex = initialIndex.clamp(0, urls.length - 1);

    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MediaViewerScreen(
          urls: urls,
          initialIndex: safeIndex,
          title: title,
          heroTagBuilder: heroTagBuilder,
          enableReport: enableReport,
          reportTargetOwnerId: reportTargetOwnerId,
          onReportSubmit: onReportSubmit,
        ),
      ),
    );
  }

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _controller;
  late final TransformationController _transformationController;
  late int _index;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _controller = PageController(initialPage: _index);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setScale(double value) {
    final nextScale = value.clamp(1.0, 4.0).toDouble();
    setState(() {
      _scale = nextScale;
      _transformationController.value = Matrix4.identity()..scale(nextScale);
    });
  }

  void _resetZoom() => _setScale(1);

  void _handleInteractionEnd(ScaleEndDetails details) {
    final nextScale = _transformationController.value
        .getMaxScaleOnAxis()
        .clamp(1.0, 4.0)
        .toDouble();
    if (nextScale == _scale) return;
    setState(() => _scale = nextScale);
  }

  Future<void> _reportCurrentImage() {
    final currentReference = widget.urls[_index];
    final isPrivate =
        PrivateStorageMediaService.isPrivatePath(currentReference);
    return ReportContentSheet.show(
      context,
      title: 'Denunciar imagem',
      targetType: ReportTargetType.portfolioMedia,
      targetId: currentReference,
      targetOwnerId: widget.reportTargetOwnerId,
      sourceContext: 'portfolio_media',
      mediaUrl: isPrivate ? null : currentReference,
      mediaPath: isPrivate ? currentReference : null,
      onSubmit: widget.onReportSubmit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final title = (widget.title ?? '').trim();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '${_index + 1} / ${urls.length}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (widget.enableReport)
            IconButton(
              tooltip: 'Denunciar imagem',
              onPressed: _reportCurrentImage,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _resetZoom();
            },
            itemBuilder: (context, i) {
              final url = urls[i];
              final heroTag = widget.heroTagBuilder?.call(url, i);

              Widget image = InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1,
                maxScale: 4,
                onInteractionEnd: _handleInteractionEnd,
                child: Center(
                  child: PrivateStorageImage(
                    reference: url,
                    fit: BoxFit.contain,
                    loading: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              );

              if (heroTag != null) {
                image = Hero(tag: heroTag, child: image);
              }

              return image;
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              child: Center(
                child: _ZoomControls(
                  scale: _scale,
                  onZoomIn: () => _setScale(_scale + 0.25),
                  onZoomOut: () => _setScale(_scale - 0.25),
                  onReset: _resetZoom,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Afastar',
              child: IconButton(
                onPressed: scale <= 1 ? null : onZoomOut,
                icon: const Icon(Icons.remove_rounded),
                color: Colors.white,
                disabledColor: Colors.white38,
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${(scale * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Tooltip(
              message: 'Aproximar',
              child: IconButton(
                onPressed: scale >= 4 ? null : onZoomIn,
                icon: const Icon(Icons.add_rounded),
                color: Colors.white,
                disabledColor: Colors.white38,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Repor zoom',
              child: IconButton(
                onPressed: scale == 1 ? null : onReset,
                icon: const Icon(Icons.fit_screen_rounded),
                color: Colors.white,
                disabledColor: Colors.white38,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
