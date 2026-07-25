import 'package:flutter/foundation.dart';

import 'feature_flag.dart';

enum FeatureFlagSnapshotSource {
  bundledDefaults,
  remote,
  cachedRemote,
  fetchFailed,
}

enum FeatureFlagFetchStatus {
  notFetched,
  success,
  failure,
  throttled,
}

class FeatureFlagSnapshot {
  FeatureFlagSnapshot({
    required this.contractVersion,
    required this.releaseId,
    required this.source,
    required this.fetchStatus,
    required Map<FeatureFlag, bool> remoteValues,
    this.globalKillSwitch = false,
    this.fetchedAt,
  }) : remoteValues = Map<FeatureFlag, bool>.unmodifiable(remoteValues);

  factory FeatureFlagSnapshot.defaults({
    FeatureFlagSnapshotSource source =
        FeatureFlagSnapshotSource.bundledDefaults,
    FeatureFlagFetchStatus fetchStatus = FeatureFlagFetchStatus.notFetched,
    DateTime? fetchedAt,
  }) {
    return FeatureFlagSnapshot(
      contractVersion: FeatureFlagContract.version,
      releaseId: 'bundled-defaults-v${FeatureFlagContract.version}',
      source: source,
      fetchStatus: fetchStatus,
      fetchedAt: fetchedAt,
      remoteValues: {
        for (final definition in FeatureFlagContract.definitions.values)
          definition.flag: definition.defaultValue,
      },
    );
  }

  final int contractVersion;
  final String releaseId;
  final FeatureFlagSnapshotSource source;
  final FeatureFlagFetchStatus fetchStatus;
  final Map<FeatureFlag, bool> remoteValues;
  final bool globalKillSwitch;
  final DateTime? fetchedAt;

  bool get isCompatible => contractVersion == FeatureFlagContract.version;

  bool remoteValueFor(FeatureFlag flag) {
    return remoteValues[flag] ??
        FeatureFlagContract.definitionFor(flag).defaultValue;
  }

  bool isStaleAt(DateTime now, Duration maxAge) {
    if (source == FeatureFlagSnapshotSource.bundledDefaults) return false;
    final lastFetch = fetchedAt;
    if (lastFetch == null) return true;
    return now.toUtc().difference(lastFetch.toUtc()) > maxAge;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeatureFlagSnapshot &&
            contractVersion == other.contractVersion &&
            releaseId == other.releaseId &&
            source == other.source &&
            fetchStatus == other.fetchStatus &&
            globalKillSwitch == other.globalKillSwitch &&
            fetchedAt == other.fetchedAt &&
            mapEquals(remoteValues, other.remoteValues);
  }

  @override
  int get hashCode => Object.hash(
        contractVersion,
        releaseId,
        source,
        fetchStatus,
        globalKillSwitch,
        fetchedAt,
        Object.hashAll(
          FeatureFlag.values.map(
            (flag) => Object.hash(flag, remoteValues[flag]),
          ),
        ),
      );
}
