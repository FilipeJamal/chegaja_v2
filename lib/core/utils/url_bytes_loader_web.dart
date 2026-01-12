import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> loadBytesFromUrl(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw Exception('Failed to load $url (HTTP ${response.status})');
  }
  final buffer = await response.arrayBuffer().toDart;
  return Uint8List.view(buffer.toDart);
}

void revokeObjectUrl(String url) {
  web.URL.revokeObjectURL(url);
}
