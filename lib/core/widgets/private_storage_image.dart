import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/private_storage_media_service.dart';

class PrivateStorageImage extends StatefulWidget {
  const PrivateStorageImage({
    super.key,
    required this.reference,
    this.fit,
    this.width,
    this.height,
    this.loading,
    this.error,
  });

  final String reference;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? loading;
  final Widget? error;

  @override
  State<PrivateStorageImage> createState() => _PrivateStorageImageState();
}

class _PrivateStorageImageState extends State<PrivateStorageImage> {
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = PrivateStorageMediaService.resolveReferenceLazily(widget.reference);
  }

  @override
  void didUpdateWidget(covariant PrivateStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) {
      _url =
          PrivateStorageMediaService.resolveReferenceLazily(widget.reference);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.error ??
              const Center(child: Icon(Icons.broken_image_outlined));
        }
        final url = snapshot.data;
        if (url == null) {
          return widget.loading ??
              const Center(child: CircularProgressIndicator());
        }
        return Image.network(
          url,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (_, __, ___) =>
              widget.error ??
              const Center(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }
}
