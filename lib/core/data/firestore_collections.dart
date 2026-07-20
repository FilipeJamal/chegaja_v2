/// Canonical Firestore collection names for the P1 security boundary.
///
/// Public documents contain only fields that may be disclosed to any viewer.
/// Private and dispatch documents are protected by Firestore Rules and must
/// never be used as a source for public profile or discovery screens.
abstract final class FirestoreCollections {
  static const usersPrivate = 'users_private';
  static const publicProfiles = 'public_profiles';
  static const providerPrivate = 'provider_private';
  static const providerPublic = 'provider_public';
  static const providerDispatchPrivate = 'provider_dispatch_private';
  static const kycSubmissions = 'kyc_submissions';

  static const serviceRequests = 'pedidos';
  static const serviceRequestDispatch = 'pedido_dispatch';

  /// Read-only migration sources. New application code must not write here.
  static const legacyUsers = 'users';
  static const legacyProviders = 'prestadores';
}
