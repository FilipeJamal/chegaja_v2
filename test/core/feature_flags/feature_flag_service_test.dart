import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_service.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_snapshot.dart';

void main() {
  final now = DateTime.utc(2026, 7, 24, 12);

  FeatureFlagSnapshot remoteSnapshot({
    required Map<FeatureFlag, bool> values,
    int contractVersion = FeatureFlagContract.version,
    bool globalKillSwitch = false,
    DateTime? fetchedAt,
  }) {
    return FeatureFlagSnapshot(
      contractVersion: contractVersion,
      releaseId: 'u1-test',
      source: FeatureFlagSnapshotSource.remote,
      fetchStatus: FeatureFlagFetchStatus.success,
      fetchedAt: fetchedAt ?? now,
      globalKillSwitch: globalKillSwitch,
      remoteValues: values,
    );
  }

  test('all flags are disabled before a remote snapshot is applied', () {
    final service = FeatureFlagService(clock: () => now);

    for (final flag in FeatureFlag.values) {
      expect(service.isEnabled(flag), isFalse, reason: flag.name);
    }
  });

  test('standard rollout can be enabled remotely without hidden gates', () {
    final service = FeatureFlagService(
      initialSnapshot: remoteSnapshot(
        values: const {FeatureFlag.u1NavigationV2: true},
      ),
      clock: () => now,
    );

    expect(service.isEnabled(FeatureFlag.u1NavigationV2), isTrue);
    expect(
      service.evaluate(FeatureFlag.u1NavigationV2).reason,
      FeatureFlagDecisionReason.enabled,
    );
  });

  test('critical capability requires local, remote, backend and platform', () {
    final snapshot = remoteSnapshot(
      values: const {FeatureFlag.kyc: true},
    );
    final service = FeatureFlagService(
      initialSnapshot: snapshot,
      clock: () => now,
    );

    expect(
      service.evaluate(FeatureFlag.kyc).reason,
      FeatureFlagDecisionReason.localGateClosed,
    );

    service.updateGates(
      FeatureFlagGateState(
        localGates: const {FeatureFlag.kyc: true},
      ),
    );
    expect(
      service.evaluate(FeatureFlag.kyc).reason,
      FeatureFlagDecisionReason.backendCapabilityMissing,
    );

    service.updateGates(
      FeatureFlagGateState(
        localGates: const {FeatureFlag.kyc: true},
        backendCapabilities: const {FeatureFlag.kyc: true},
      ),
    );
    expect(
      service.evaluate(FeatureFlag.kyc).reason,
      FeatureFlagDecisionReason.platformUnsupported,
    );

    service.updateGates(
      FeatureFlagGateState(
        localGates: const {FeatureFlag.kyc: true},
        backendCapabilities: const {FeatureFlag.kyc: true},
        platformCapabilities: const {FeatureFlag.kyc: true},
      ),
    );
    expect(service.isEnabled(FeatureFlag.kyc), isTrue);
  });

  test('remote false blocks even when all other critical gates are open', () {
    final service = FeatureFlagService(
      initialSnapshot: remoteSnapshot(
        values: const {FeatureFlag.kyc: false},
      ),
      initialGates: FeatureFlagGateState(
        localGates: const {FeatureFlag.kyc: true},
        backendCapabilities: const {FeatureFlag.kyc: true},
        platformCapabilities: const {FeatureFlag.kyc: true},
      ),
      clock: () => now,
    );

    expect(
      service.evaluate(FeatureFlag.kyc).reason,
      FeatureFlagDecisionReason.remoteDisabled,
    );
  });

  test('kill switches override a fully enabled decision', () {
    final openGates = FeatureFlagGateState(
      localGates: const {FeatureFlag.kyc: true},
      backendCapabilities: const {FeatureFlag.kyc: true},
      platformCapabilities: const {FeatureFlag.kyc: true},
      killSwitches: const {FeatureFlag.kyc},
    );
    final service = FeatureFlagService(
      initialSnapshot: remoteSnapshot(
        values: const {FeatureFlag.kyc: true},
      ),
      initialGates: openGates,
      clock: () => now,
    );

    expect(
      service.evaluate(FeatureFlag.kyc).reason,
      FeatureFlagDecisionReason.flagKillSwitch,
    );

    service.updateGates(
      FeatureFlagGateState(
        localGates: const {FeatureFlag.kyc: true},
        backendCapabilities: const {FeatureFlag.kyc: true},
        platformCapabilities: const {FeatureFlag.kyc: true},
        globalKillSwitch: true,
      ),
    );
    expect(
      service.evaluate(FeatureFlag.kyc).reason,
      FeatureFlagDecisionReason.globalKillSwitch,
    );
  });

  test('stale critical snapshot fails closed but standard rollout remains', () {
    final oldFetch = now.subtract(const Duration(hours: 25));
    final service = FeatureFlagService(
      initialSnapshot: remoteSnapshot(
        values: const {
          FeatureFlag.kyc: true,
          FeatureFlag.u1NavigationV2: true,
        },
        fetchedAt: oldFetch,
      ),
      initialGates: FeatureFlagGateState(
        localGates: const {FeatureFlag.kyc: true},
        backendCapabilities: const {FeatureFlag.kyc: true},
        platformCapabilities: const {FeatureFlag.kyc: true},
      ),
      clock: () => now,
    );

    expect(
      service.evaluate(FeatureFlag.kyc).reason,
      FeatureFlagDecisionReason.staleRemoteSnapshot,
    );
    expect(service.isEnabled(FeatureFlag.u1NavigationV2), isTrue);
  });

  test('incompatible remote contract fails closed', () {
    final service = FeatureFlagService(
      initialSnapshot: remoteSnapshot(
        values: const {FeatureFlag.u1NavigationV2: true},
        contractVersion: FeatureFlagContract.version + 1,
      ),
      clock: () => now,
    );

    expect(
      service.evaluate(FeatureFlag.u1NavigationV2).reason,
      FeatureFlagDecisionReason.incompatibleContract,
    );
  });

  test('notifies listeners only when snapshot or gates change', () {
    final service = FeatureFlagService(clock: () => now);
    var notifications = 0;
    service.addListener(() => notifications += 1);

    final defaults = FeatureFlagSnapshot.defaults();
    service.applySnapshot(defaults);
    service.updateGates(FeatureFlagGateState.closed());
    expect(notifications, 0);

    service.applySnapshot(
      remoteSnapshot(
        values: const {FeatureFlag.u1NavigationV2: true},
      ),
    );
    expect(notifications, 1);

    service.updateGates(
      FeatureFlagGateState(
        killSwitches: const {FeatureFlag.u1NavigationV2},
      ),
    );
    expect(notifications, 2);
  });
}
