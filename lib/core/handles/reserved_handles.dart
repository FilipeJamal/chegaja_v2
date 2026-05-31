import 'handle_normalizer.dart';

class ReservedHandles {
  const ReservedHandles._();

  static bool contains(String rawHandle) {
    final normalized = HandleNormalizer.normalize(rawHandle);
    return values.contains(normalized);
  }

  static const Set<String> values = {
    'admin',
    'administrador',
    'administrator',
    'support',
    'suporte',
    'help',
    'ajuda',
    'chegaja',
    'chegajaoficial',
    'chegajaapp',
    'oficial',
    'official',
    'verified',
    'verificado',
    'certificado',
    'pagamento',
    'pagamentos',
    'payment',
    'seguranca',
    'security',
    'termos',
    'terms',
    'privacidade',
    'privacy',
    'login',
    'logout',
    'register',
    'signup',
    'api',
    'app',
    'root',
    'null',
    'undefined',
    'system',
    'moderator',
    'moderador',
    'moderacao',
    'moderation',
    'staff',
    'team',
  };
}
