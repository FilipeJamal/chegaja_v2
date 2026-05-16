class StoragePathPolicy {
  StoragePathPolicy._();

  static const int maxPedidoAttachmentBytes = 20 * 1024 * 1024;

  static String tempPedidoAttachmentFolder({required String userId}) {
    final uid = userId.trim();
    if (uid.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id cannot be blank');
    }
    return 'temp/$uid/anexos';
  }

  static String safeFileName(String name) {
    final baseName = name.trim().split(RegExp(r'[\\/]')).last.trim();
    if (baseName.isEmpty) return 'file';

    final safe = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final normalized = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    return trimmed.isEmpty ? 'file' : trimmed;
  }

  static String? attachmentContentTypeForFileName(String fileName) {
    final lower = safeFileName(fileName).toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    return null;
  }
}
