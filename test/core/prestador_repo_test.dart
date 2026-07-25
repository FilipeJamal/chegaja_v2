import 'package:chegaja_v2/core/repositories/prestador_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrestadorRepo discovery', () {
    test('returns only searchable providers from the active market', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = PrestadorRepo(firestore: firestore);

      await firestore.collection('provider_public').doc('coimbra').set({
        'displayName': 'Prestador Coimbra',
        'marketId': 'pt-coimbra',
        'isSearchable': true,
        'ratingAvg': 4.8,
      });
      await firestore.collection('provider_public').doc('maputo').set({
        'displayName': 'Prestador Maputo',
        'marketId': 'mz-maputo',
        'isSearchable': true,
        'ratingAvg': 5,
      });
      await firestore.collection('provider_public').doc('hidden').set({
        'displayName': 'Prestador Oculto',
        'marketId': 'pt-coimbra',
        'isSearchable': false,
      });

      final providers = await repo.buscaPrestadores();

      expect(providers.map((provider) => provider.uid), ['coimbra']);
    });
  });

  group('PrestadorRepo agenda', () {
    test('reads schedule exclusively from provider_dispatch_private', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = PrestadorRepo(firestore: firestore);

      await firestore.collection('provider_public').doc('provider-1').set({
        'workingHours': {
          'monday': ['06:00', '07:00'],
        },
      });
      await firestore
          .collection('provider_dispatch_private')
          .doc('provider-1')
          .set({
        'workingHours': {
          'tuesday': ['09:00', '18:00'],
        },
        'blockedDates': [Timestamp.fromDate(DateTime.utc(2026, 7, 30))],
      });

      final agenda = await repo.getAgenda('provider-1');

      expect(agenda.workingHours, {
        'tuesday': ['09:00', '18:00'],
      });
      expect(agenda.workingHours, isNot(contains('monday')));
      expect(
        agenda.blockedDates.map((date) => date.toUtc()).toList(),
        [DateTime.utc(2026, 7, 30)],
      );
    });

    test('returns an empty schedule when private document does not exist',
        () async {
      final repo = PrestadorRepo(firestore: FakeFirebaseFirestore());

      final agenda = await repo.getAgenda('provider-missing');

      expect(agenda.workingHours, isEmpty);
      expect(agenda.blockedDates, isEmpty);
    });

    test('normalizes the legacy single range representation', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = PrestadorRepo(firestore: firestore);
      await firestore
          .collection('provider_dispatch_private')
          .doc('provider-legacy')
          .set({
        'workingHours': {
          'monday': ['08:00-17:00'],
          'tuesday': ['invalid'],
        },
      });

      final agenda = await repo.getAgenda('provider-legacy');

      expect(agenda.workingHours, {
        'monday': ['08:00', '17:00'],
      });
    });

    test('updates schedule with merge and preserves dispatch state', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = PrestadorRepo(firestore: firestore);
      final ref =
          firestore.collection('provider_dispatch_private').doc('provider-1');
      await ref.set({
        'providerId': 'provider-1',
        'isOnline': false,
        'radiusKm': 12,
      });

      await repo.updateAgenda(
        'provider-1',
        workingHours: {
          'friday': ['10:00', '16:00'],
        },
      );

      final data = (await ref.get()).data()!;
      expect(data['providerId'], 'provider-1');
      expect(data['isOnline'], isFalse);
      expect(data['radiusKm'], 12);
      expect(data['workingHours'], {
        'friday': ['10:00', '16:00'],
      });
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('rejects an empty provider id', () async {
      final repo = PrestadorRepo(firestore: FakeFirebaseFirestore());

      expect(
        () => repo.getAgenda('  '),
        throwsArgumentError,
      );
    });
  });
}
