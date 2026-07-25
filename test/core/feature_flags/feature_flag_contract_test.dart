import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_snapshot.dart';

void main() {
  group('FeatureFlagContract', () {
    test('declares every flag once with a safe remote key', () {
      expect(
        FeatureFlagContract.definitions.keys.toSet(),
        FeatureFlag.values.toSet(),
      );

      final keys = FeatureFlagContract.definitions.values
          .map((definition) => definition.remoteKey)
          .toList(growable: false);
      expect(keys.toSet(), hasLength(keys.length));
      for (final key in keys) {
        expect(key, matches(RegExp(r'^feature_[a-z0-9_]+$')));
      }
    });

    test('all rollout defaults are disabled', () {
      for (final definition in FeatureFlagContract.definitions.values) {
        expect(
          definition.defaultValue,
          isFalse,
          reason: '${definition.remoteKey} must fail closed',
        );
      }
    });

    test('critical flags fail closed when their remote snapshot is stale', () {
      final critical = FeatureFlagContract.definitions.values.where(
        (definition) => definition.risk == FeatureFlagRisk.critical,
      );
      expect(critical, isNotEmpty);
      for (final definition in critical) {
        expect(
          definition.stalePolicy,
          FeatureFlagStalePolicy.failClosed,
          reason: definition.remoteKey,
        );
      }
    });

    test('remote defaults stay synchronized with typed definitions', () {
      final defaults = FeatureFlagContract.remoteDefaults;
      expect(
        defaults[FeatureFlagContract.contractVersionKey],
        FeatureFlagContract.version,
      );
      expect(
        defaults[FeatureFlagContract.globalKillSwitchKey],
        isFalse,
      );
      for (final definition in FeatureFlagContract.definitions.values) {
        expect(
          defaults[definition.remoteKey],
          definition.defaultValue,
          reason: definition.remoteKey,
        );
      }
    });
  });

  group('FeatureFlagSnapshot', () {
    test('bundled snapshot is compatible, immutable and never stale', () {
      final snapshot = FeatureFlagSnapshot.defaults();
      expect(snapshot.isCompatible, isTrue);
      expect(
        snapshot.isStaleAt(
          DateTime.utc(2030),
          const Duration(seconds: 1),
        ),
        isFalse,
      );
      expect(
        () => snapshot.remoteValues[FeatureFlag.kyc] = true,
        throwsUnsupportedError,
      );
    });

    test('remote snapshot without a successful fetch is stale', () {
      final snapshot = FeatureFlagSnapshot(
        contractVersion: FeatureFlagContract.version,
        releaseId: 'test',
        source: FeatureFlagSnapshotSource.fetchFailed,
        fetchStatus: FeatureFlagFetchStatus.failure,
        remoteValues: const {},
      );

      expect(
        snapshot.isStaleAt(
          DateTime.utc(2026, 7, 24),
          const Duration(hours: 24),
        ),
        isTrue,
      );
    });
  });
}
