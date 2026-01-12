import 'package:flutter/material.dart';

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

  /// Helper para abrir rapidamente.
  static Future<void> open(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    String? title,
    String Function(String url, int index)? heroTagBuilder,
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
        ),
      ),
    );
  }

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final url = urls[i];
          final heroTag = widget.heroTagBuilder?.call(url, i);

          Widget image = InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
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
    );
  }
}
