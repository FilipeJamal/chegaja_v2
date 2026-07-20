import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';

class PrivateStorageReadUrl {
  const PrivateStorageReadUrl({
    required this.path,
    required this.url,
    required this.expiresAt,
  });

  final String path;
  final String url;
  final DateTime expiresAt;
}

class PrivateStorageMediaService {
  PrivateStorageMediaService._({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  static final PrivateStorageMediaService instance =
      PrivateStorageMediaService._();

  final FirebaseFunctions _functions;
  final Map<String, PrivateStorageReadUrl> _cache = {};

  static bool isPrivatePath(String? value) {
    final path = (value ?? '').trim();
    if (path.isEmpty || path.startsWith('/') || path.contains('\\')) {
      return false;
    }
    final segments = path.split('/');
    if (segments.any(
        (segment) => segment.isEmpty || segment == '.' || segment == '..')) {
      return false;
    }
    if (segments.length < 4) return false;
    if (segments[0] == 'temp' && segments[2] == 'anexos') return true;
    if (segments[0] == 'pedidos' && segments[2] == 'anexos') return true;
    return segments[0] == 'chats' &&
        const {'images', 'files', 'audio'}.contains(segments[2]);
  }

  static Future<String> resolveReferenceLazily(String reference) {
    final normalized = reference.trim();
    if (!isPrivatePath(normalized)) {
      if (normalized.startsWith('https://') ||
          normalized.startsWith('http://')) {
        return Future<String>.value(normalized);
      }
      return Future<String>.error(
        ArgumentError.value(
          reference,
          'reference',
          'Referencia de media invalida',
        ),
      );
    }
    return instance.resolve(path: normalized);
  }

  Future<void> finalizeUpload(String path) async {
    final normalized = path.trim();
    if (!isPrivatePath(normalized)) {
      throw ArgumentError.value(path, 'path', 'Caminho privado invalido');
    }
    final response = await _functions
        .httpsCallable('storage_finalizePrivateUpload')
        .call(<String, dynamic>{'path': normalized});
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['ok'] != true || data['persistentDownloadTokenRemoved'] != true) {
      throw StateError('O servidor nao confirmou a protecao do anexo.');
    }
    _cache.remove(normalized);
  }

  Future<String> resolve({
    String? path,
    String? legacyUrl,
  }) async {
    final normalizedPath = (path ?? '').trim();
    if (normalizedPath.isEmpty) {
      final fallback = (legacyUrl ?? '').trim();
      if (fallback.startsWith('https://') || fallback.startsWith('http://')) {
        return fallback;
      }
      throw ArgumentError('Nenhuma referencia de media valida.');
    }
    if (!isPrivatePath(normalizedPath)) {
      throw ArgumentError.value(path, 'path', 'Caminho privado invalido');
    }
    final cached = _cache[normalizedPath];
    if (cached != null &&
        cached.expiresAt
            .isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      return cached.url;
    }
    final response = await _functions
        .httpsCallable('storage_getPrivateReadUrl')
        .call(<String, dynamic>{'path': normalizedPath});
    final data = Map<String, dynamic>.from(response.data as Map);
    final url = (data['url'] as String?)?.trim() ?? '';
    final returnedPath = (data['path'] as String?)?.trim() ?? '';
    final expiresAtMillis = (data['expiresAtMillis'] as num?)?.toInt() ?? 0;
    if (url.isEmpty || returnedPath != normalizedPath || expiresAtMillis <= 0) {
      throw StateError('Resposta de media privada invalida.');
    }
    _cache[normalizedPath] = PrivateStorageReadUrl(
      path: normalizedPath,
      url: url,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMillis),
    );
    return url;
  }

  Future<String> resolveReference(String reference) {
    return resolveReferenceLazily(reference);
  }
}
