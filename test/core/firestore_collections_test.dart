import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/data/firestore_collections.dart';

void main() {
  test('public and private collection names cannot overlap', () {
    const publicCollections = {
      FirestoreCollections.publicProfiles,
      FirestoreCollections.providerPublic,
      FirestoreCollections.serviceRequestDispatch,
    };
    const privateCollections = {
      FirestoreCollections.usersPrivate,
      FirestoreCollections.providerPrivate,
      FirestoreCollections.providerDispatchPrivate,
      FirestoreCollections.kycSubmissions,
      FirestoreCollections.serviceRequests,
    };

    expect(publicCollections.intersection(privateCollections), isEmpty);
  });

  test('legacy collections are explicit migration-only sources', () {
    expect(FirestoreCollections.legacyUsers, 'users');
    expect(FirestoreCollections.legacyProviders, 'prestadores');
  });
}
