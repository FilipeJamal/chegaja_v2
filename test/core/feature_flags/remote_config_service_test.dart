import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_service.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_snapshot.dart';
import 'package:chegaja_v2/core/services/remote_config_service.dart';

class _FakeRemoteConfigClient implements RemoteConfigClient {
  _FakeRemoteConfigClient({
    Map<String, String>? values,
    this.fetchStatus = RemoteConfigClientFetchStatus.success,
    this.fetchedAt,
    this.fetchError,
  }) : values = {...?values};

  final Map<String, String> values;
  final RemoteConfigClientFetchStatus fetchStatus;
  final DateTime? fetchedAt;
  final Object? fetchError;
  final StreamController<void> updatesController =
      StreamController<void>.broadcast(sync: true);

  RemoteConfigClientSettings? settings;
  Map<String, Object>? configuredDefaults;
  var activateCalls = 0;

  @override
  Future<void> configure(RemoteConfigClientSettings value) async {
    settings = value;
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    configuredDefaults = {...defaults};
    for (final entry in defaults.entries) {
      values.putIfAbsent(entry.key, () => entry.value.toString());
    }
  }

  @override
  Future<bool> fetchAndActivate() async {
    final error = fetchError;
    if (error != null) throw error;
    return true;
  }

  @override
  Future<bool> activate() async {
    activateCalls += 1;
    return true;
  }

  @override
  String valueAsString(String key) => values[key] ?? '';

  @override
  DateTime? get lastFetchTime => fetchedAt;

  @override
  RemoteConfigClientFetchStatus get lastFetchStatus => fetchStatus;

  @override
  Stream<void> get updates => updatesController.stream;

  void emitUpdate() => updatesController.add(null);

  Future<void> dispose() => updatesController.close();
}

void main() {
  final fetchedAt = DateTime.utc(2026, 7, 24, 12);

  test('applies a typed remote snapshot without a Firebase instance', () async {
    final client = _FakeRemoteConfigClient(
      values: {
        FeatureFlagContract.contractVersionKey:
            FeatureFlagContract.version.toString(),
        FeatureFlagContract.releaseIdKey: 'u1-remote-test',
        FeatureFlagContract.definitionFor(FeatureFlag.u1NavigationV2).remoteKey:
            'true',
      },
      fetchedAt: fetchedAt,
    );
    final flags = FeatureFlagService(clock: () => fetchedAt);
    final service = RemoteConfigService(
      client: client,
      featureFlags: flags,
      debugMode: false,
    );

    final snapshot = await service.initialize();

    expect(snapshot.source, FeatureFlagSnapshotSource.remote);
    expect(snapshot.fetchStatus, FeatureFlagFetchStatus.success);
    expect(snapshot.releaseId, 'u1-remote-test');
    expect(flags.isEnabled(FeatureFlag.u1NavigationV2), isTrue);
    expect(client.settings?.fetchTimeout, const Duration(minutes: 1));
    expect(
      client.settings?.minimumFetchInterval,
      const Duration(hours: 12),
    );
    expect(
      client.configuredDefaults,
      FeatureFlagContract.remoteDefaults,
    );

    await service.dispose();
    await client.dispose();
  });

  test('malformed values and a failed first fetch remain closed', () async {
    final client = _FakeRemoteConfigClient(
      values: {
        FeatureFlagContract.contractVersionKey:
            FeatureFlagContract.version.toString(),
        FeatureFlagContract.definitionFor(FeatureFlag.u1NavigationV2).remoteKey:
            'yes',
      },
      fetchStatus: RemoteConfigClientFetchStatus.failure,
      fetchError: StateError('offline'),
    );
    final flags = FeatureFlagService(clock: () => fetchedAt);
    final service = RemoteConfigService(
      client: client,
      featureFlags: flags,
      debugMode: false,
    );

    final snapshot = await service.initialize();

    expect(snapshot.source, FeatureFlagSnapshotSource.fetchFailed);
    expect(snapshot.fetchStatus, FeatureFlagFetchStatus.failure);
    expect(flags.isEnabled(FeatureFlag.u1NavigationV2), isFalse);

    await service.dispose();
    await client.dispose();
  });

  test('maintenance mode is applied as a global kill switch', () async {
    final client = _FakeRemoteConfigClient(
      values: {
        FeatureFlagContract.contractVersionKey:
            FeatureFlagContract.version.toString(),
        FeatureFlagContract.maintenanceModeKey: 'true',
        FeatureFlagContract.definitionFor(FeatureFlag.u1NavigationV2).remoteKey:
            'true',
      },
      fetchedAt: fetchedAt,
    );
    final flags = FeatureFlagService(clock: () => fetchedAt);
    final service = RemoteConfigService(
      client: client,
      featureFlags: flags,
      debugMode: false,
    );

    await service.initialize();

    expect(
      flags.evaluate(FeatureFlag.u1NavigationV2).reason,
      FeatureFlagDecisionReason.globalKillSwitch,
    );
    expect(service.getMaintenanceMode(), isTrue);

    await service.dispose();
    await client.dispose();
  });

  test('real-time update activates and publishes a new snapshot', () async {
    final navigationKey =
        FeatureFlagContract.definitionFor(FeatureFlag.u1NavigationV2).remoteKey;
    final client = _FakeRemoteConfigClient(
      values: {
        FeatureFlagContract.contractVersionKey:
            FeatureFlagContract.version.toString(),
        FeatureFlagContract.releaseIdKey: 'before',
        navigationKey: 'false',
      },
      fetchedAt: fetchedAt,
    );
    final flags = FeatureFlagService(clock: () => fetchedAt);
    final service = RemoteConfigService(
      client: client,
      featureFlags: flags,
      debugMode: false,
    );
    await service.initialize();
    expect(flags.isEnabled(FeatureFlag.u1NavigationV2), isFalse);

    final nextSnapshot = service.snapshots.first;
    client.values[FeatureFlagContract.releaseIdKey] = 'after';
    client.values[navigationKey] = 'true';
    client.emitUpdate();
    final snapshot = await nextSnapshot;

    expect(client.activateCalls, 1);
    expect(snapshot.releaseId, 'after');
    expect(flags.isEnabled(FeatureFlag.u1NavigationV2), isTrue);

    await service.dispose();
    await client.dispose();
  });
}
