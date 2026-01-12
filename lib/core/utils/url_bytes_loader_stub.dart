import 'dart:typed_data';

Future<Uint8List> loadBytesFromUrl(String url) {
  throw UnsupportedError('loadBytesFromUrl is only supported on web.');
}

void revokeObjectUrl(String url) {
  // no-op on non-web platforms
}
