import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_provider.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_service.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_snapshot.dart';

enum RemoteConfigClientFetchStatus {
  notFetched,
  success,
  failure,
  throttled,
}

class RemoteConfigClientSettings {
  const RemoteConfigClientSettings({
    required this.fetchTimeout,
    required this.minimumFetchInterval,
  });

  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
}

abstract interface class RemoteConfigClient {
  Future<void> configure(RemoteConfigClientSettings settings);

  Future<void> setDefaults(Map<String, Object> defaults);

  Future<bool> fetchAndActivate();

  Future<bool> activate();

  String valueAsString(String key);

  DateTime? get lastFetchTime;

  RemoteConfigClientFetchStatus get lastFetchStatus;

  Stream<void> get updates;
}

class FirebaseRemoteConfigClient implements RemoteConfigClient {
  FirebaseRemoteConfigClient(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> configure(RemoteConfigClientSettings settings) {
    return _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: settings.fetchTimeout,
        minimumFetchInterval: settings.minimumFetchInterval,
      ),
    );
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) {
    return _remoteConfig.setDefaults(defaults);
  }

  @override
  Future<bool> fetchAndActivate() => _remoteConfig.fetchAndActivate();

  @override
  Future<bool> activate() => _remoteConfig.activate();

  @override
  String valueAsString(String key) {
    return _remoteConfig.getValue(key).asString();
  }

  @override
  DateTime? get lastFetchTime {
    final value = _remoteConfig.lastFetchTime;
    return value.millisecondsSinceEpoch <= 0 ? null : value;
  }

  @override
  RemoteConfigClientFetchStatus get lastFetchStatus {
    return switch (_remoteConfig.lastFetchStatus) {
      RemoteConfigFetchStatus.noFetchYet =>
        RemoteConfigClientFetchStatus.notFetched,
      RemoteConfigFetchStatus.success => RemoteConfigClientFetchStatus.success,
      RemoteConfigFetchStatus.failure => RemoteConfigClientFetchStatus.failure,
      RemoteConfigFetchStatus.throttle =>
        RemoteConfigClientFetchStatus.throttled,
    };
  }

  @override
  Stream<void> get updates {
    return _remoteConfig.onConfigUpdated.map((_) {});
  }
}

class RemoteConfigService implements FeatureFlagSnapshotProvider {
  RemoteConfigService({
    RemoteConfigClient? client,
    FeatureFlagService? featureFlags,
    bool debugMode = kDebugMode,
  })  : _client =
            client ?? FirebaseRemoteConfigClient(FirebaseRemoteConfig.instance),
        _featureFlags = featureFlags ?? FeatureFlagService.instance,
        _debugMode = debugMode;

  static final RemoteConfigService instance = RemoteConfigService();

  final RemoteConfigClient _client;
  final FeatureFlagService _featureFlags;
  final bool _debugMode;
  final StreamController<FeatureFlagSnapshot> _snapshots =
      StreamController<FeatureFlagSnapshot>.broadcast(sync: true);

  StreamSubscription<void>? _updatesSubscription;
  FeatureFlagSnapshot _lastSnapshot = FeatureFlagSnapshot.defaults();

  @override
  Stream<FeatureFlagSnapshot> get snapshots => _snapshots.stream;

  FeatureFlagSnapshot get lastSnapshot => _lastSnapshot;

  Future<FeatureFlagSnapshot> init() => initialize();

  @override
  Future<FeatureFlagSnapshot> initialize() async {
    var fetchFailed = false;

    try {
      await _client.configure(
        RemoteConfigClientSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: _debugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 12),
        ),
      );
      await _client.setDefaults(FeatureFlagContract.remoteDefaults);
      await _client.fetchAndActivate();
    } catch (error, stack) {
      fetchFailed = true;
      if (_debugMode) {
        debugPrint('[RemoteConfig] Fetch indisponivel: $error\n$stack');
      }
    }

    FeatureFlagSnapshot snapshot;
    try {
      snapshot = _readSnapshot(fetchFailed: fetchFailed);
    } catch (error, stack) {
      if (_debugMode) {
        debugPrint(
          '[RemoteConfig] Snapshot invalido; defaults seguros aplicados: '
          '$error\n$stack',
        );
      }
      snapshot = FeatureFlagSnapshot.defaults(
        source: FeatureFlagSnapshotSource.fetchFailed,
        fetchStatus: FeatureFlagFetchStatus.failure,
      );
    }
    _applySnapshot(snapshot);
    _subscribeToRealtimeUpdates();
    return snapshot;
  }

  void _subscribeToRealtimeUpdates() {
    _updatesSubscription ??= _client.updates.listen(
      (_) => unawaited(_activateRealtimeUpdate()),
      onError: (Object error, StackTrace stack) {
        if (_debugMode) {
          debugPrint('[RemoteConfig] Listener indisponivel: $error\n$stack');
        }
      },
    );
  }

  Future<void> _activateRealtimeUpdate() async {
    try {
      await _client.activate();
      _applySnapshot(_readSnapshot(fetchFailed: false));
    } catch (error, stack) {
      if (_debugMode) {
        debugPrint(
          '[RemoteConfig] Nao foi possivel ativar a atualizacao: '
          '$error\n$stack',
        );
      }
    }
  }

  FeatureFlagSnapshot _readSnapshot({required bool fetchFailed}) {
    final fetchedAt = _client.lastFetchTime;
    final clientStatus = _client.lastFetchStatus;
    final fetchStatus = fetchFailed
        ? FeatureFlagFetchStatus.failure
        : _mapFetchStatus(clientStatus);
    final source = _snapshotSource(
      fetchFailed: fetchFailed,
      clientStatus: clientStatus,
      fetchedAt: fetchedAt,
    );
    final contractVersion = int.tryParse(
          _client.valueAsString(FeatureFlagContract.contractVersionKey).trim(),
        ) ??
        0;
    final releaseId = _normalizedReleaseId(
      _client.valueAsString(FeatureFlagContract.releaseIdKey),
    );
    final globalKillSwitch = _strictBool(
          _client.valueAsString(FeatureFlagContract.globalKillSwitchKey),
        ) ==
        true;
    final maintenanceMode = _strictBool(
          _client.valueAsString(FeatureFlagContract.maintenanceModeKey),
        ) ==
        true;

    return FeatureFlagSnapshot(
      contractVersion: contractVersion,
      releaseId: releaseId,
      source: source,
      fetchStatus: fetchStatus,
      fetchedAt: fetchedAt,
      globalKillSwitch: globalKillSwitch || maintenanceMode,
      remoteValues: {
        for (final definition in FeatureFlagContract.definitions.values)
          definition.flag:
              _strictBool(_client.valueAsString(definition.remoteKey)) ??
                  definition.defaultValue,
      },
    );
  }

  void _applySnapshot(FeatureFlagSnapshot snapshot) {
    _lastSnapshot = snapshot;
    _featureFlags.applySnapshot(snapshot);
    if (!_snapshots.isClosed) _snapshots.add(snapshot);
  }

  FeatureFlagFetchStatus _mapFetchStatus(
    RemoteConfigClientFetchStatus status,
  ) {
    return switch (status) {
      RemoteConfigClientFetchStatus.notFetched =>
        FeatureFlagFetchStatus.notFetched,
      RemoteConfigClientFetchStatus.success => FeatureFlagFetchStatus.success,
      RemoteConfigClientFetchStatus.failure => FeatureFlagFetchStatus.failure,
      RemoteConfigClientFetchStatus.throttled =>
        FeatureFlagFetchStatus.throttled,
    };
  }

  FeatureFlagSnapshotSource _snapshotSource({
    required bool fetchFailed,
    required RemoteConfigClientFetchStatus clientStatus,
    required DateTime? fetchedAt,
  }) {
    if (fetchFailed) {
      return fetchedAt == null
          ? FeatureFlagSnapshotSource.fetchFailed
          : FeatureFlagSnapshotSource.cachedRemote;
    }
    if (clientStatus == RemoteConfigClientFetchStatus.success) {
      return FeatureFlagSnapshotSource.remote;
    }
    if (fetchedAt != null) return FeatureFlagSnapshotSource.cachedRemote;
    return FeatureFlagSnapshotSource.bundledDefaults;
  }

  String _normalizedReleaseId(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return 'remote-unknown-v${FeatureFlagContract.version}';
    }
    return normalized.length <= 80 ? normalized : normalized.substring(0, 80);
  }

  bool? _strictBool(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    };
  }

  int getMinAndroidVersion() {
    return int.tryParse(
          _client
              .valueAsString(FeatureFlagContract.legacyMinAndroidVersionKey)
              .trim(),
        ) ??
        21;
  }

  bool getMaintenanceMode() {
    return _strictBool(
          _client.valueAsString(FeatureFlagContract.maintenanceModeKey),
        ) ==
        true;
  }

  Future<void> dispose() async {
    await _updatesSubscription?.cancel();
    await _snapshots.close();
  }
}
