import 'package:chegaja_v2/core/handles/handle_validator.dart';

class PublicProfileLinkService {
  const PublicProfileLinkService._();

  static const String defaultBaseUrl = 'https://chegaja-ac88d.web.app';

  static String publicPathForHandle(String handle) {
    final normalized = _validHandle(handle);
    return '/p/$normalized';
  }

  static String publicUrlForHandle(
    String handle, {
    String baseUrl = defaultBaseUrl,
  }) {
    final root = _trimTrailingSlash(baseUrl);
    return '$root${publicPathForHandle(handle)}';
  }

  static String displayUrlForHandle(String handle) {
    return publicUrlForHandle(handle).replaceFirst(RegExp(r'^https?://'), '');
  }

  static String shareTextForProvider({
    required String displayName,
    required String handle,
    String? url,
  }) {
    final publicUrl = url ?? publicUrlForHandle(handle);
    final cleanName = displayName.trim();
    if (cleanName.isEmpty) {
      return 'Conhece este perfil no ChegaJa: $publicUrl';
    }
    return 'Conhece o perfil de $cleanName no ChegaJa: $publicUrl';
  }

  static Uri whatsAppShareUri(String text) {
    return Uri.https('wa.me', '/', <String, String>{'text': text});
  }

  static Uri facebookShareUri(String url) {
    return Uri.https(
      'www.facebook.com',
      '/sharer/sharer.php',
      <String, String>{'u': url},
    );
  }

  static String _validHandle(String handle) {
    final validation = HandleValidator.validate(handle);
    if (!validation.isValid) {
      throw ArgumentError.value(handle, 'handle', 'Handle publico invalido.');
    }
    return validation.normalizedHandle;
  }

  static String _trimTrailingSlash(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return defaultBaseUrl;
    return clean.replaceFirst(RegExp(r'/+$'), '');
  }
}
