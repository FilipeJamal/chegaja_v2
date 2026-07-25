import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/repositories/pedido_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('open dispatch query returns only the requested market and currency',
      () async {
    final firestore = FakeFirebaseFirestore();
    final dispatch = firestore.collection('pedido_dispatch');
    final createdAt = Timestamp.fromDate(DateTime.utc(2026, 7, 25));

    await dispatch.doc('coimbra-eur').set({
      'marketId': 'pt-coimbra',
      'currency': 'EUR',
      'status': 'criado',
      'prestadorId': null,
      'targetProviderId': null,
      'createdAt': createdAt,
    });
    await dispatch.doc('maputo-mzn').set({
      'marketId': 'mz-maputo',
      'currency': 'MZN',
      'status': 'criado',
      'prestadorId': null,
      'targetProviderId': null,
      'createdAt': createdAt,
    });
    await dispatch.doc('coimbra-wrong-currency').set({
      'marketId': 'pt-coimbra',
      'currency': 'MZN',
      'status': 'criado',
      'prestadorId': null,
      'targetProviderId': null,
      'createdAt': createdAt,
    });
    await dispatch.doc('legacy-missing-market').set({
      'status': 'criado',
      'prestadorId': null,
      'targetProviderId': null,
      'createdAt': createdAt,
    });

    final snapshot = await PedidosRepo.availableDispatchQuery(
      firestore,
      marketId: 'pt-coimbra',
      currency: 'EUR',
    ).get();

    expect(snapshot.docs.map((doc) => doc.id), ['coimbra-eur']);
  });

  test('targeted dispatch query excludes other and legacy markets', () async {
    final firestore = FakeFirebaseFirestore();
    final dispatch = firestore.collection('pedido_dispatch');

    Future<void> seed(
      String id, {
      String? marketId,
      String? currency,
      String targetProviderId = 'provider-1',
    }) {
      return dispatch.doc(id).set({
        if (marketId != null) 'marketId': marketId,
        if (currency != null) 'currency': currency,
        'status': 'aguarda_resposta_prestador',
        'prestadorId': null,
        'targetProviderId': targetProviderId,
      });
    }

    await seed(
      'coimbra-target',
      marketId: 'pt-coimbra',
      currency: 'EUR',
    );
    await seed(
      'maputo-target',
      marketId: 'mz-maputo',
      currency: 'MZN',
    );
    await seed(
      'wrong-provider',
      marketId: 'pt-coimbra',
      currency: 'EUR',
      targetProviderId: 'provider-2',
    );
    await seed('legacy-target');

    final snapshot = await PedidosRepo.targetedDispatchQuery(
      firestore,
      'provider-1',
      marketId: 'pt-coimbra',
      currency: 'EUR',
    ).get();

    expect(snapshot.docs.map((doc) => doc.id), ['coimbra-target']);
  });
}
