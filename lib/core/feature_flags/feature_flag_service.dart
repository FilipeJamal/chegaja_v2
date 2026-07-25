import 'package:flutter/foundation.dart';

import 'feature_flag.dart';
import 'feature_flag_snapshot.dart';

enum FeatureFlagDecisionReason {
  enabled,
  globalKillSwitch,
  flagKillSwitch,
  incompatibleContract,
  localGateClosed,
  staleRemoteSnapshot,
  remoteDisabled,
  backendCapabilityMissing,
  platformUnsupported,
}

class FeatureFlagGateState {
  FeatureFlagGateState({
    Map<FeatureFlag, bool> localGates = const {},
    Map<FeatureFlag, bool> backendCapabilities = const {},
    Map<FeatureFlag, bool> platformCapabilities = const {},
    Set<FeatureFlag> killSwitches = const {},
    this.globalKillSwitch = false,
  })  : localGates = Map<FeatureFlag, bool>.unmodifiable(localGates),
        backendCapabilities =
            Map<FeatureFlag, bool>.unmodifiable(backendCapabilities),
        platformCapabilities =
            Map<FeatureFlag, bool>.unmodifiable(platformCapabilities),
        killSwitches = Set<FeatureFlag>.unmodifiable(killSwitches);

  factory FeatureFlagGateState.closed() => FeatureFlagGateState();

  final Map<FeatureFlag, bool> localGates;
  final Map<FeatureFlag, bool> backendCapabilities;
  final Map<FeatureFlag, bool> platformCapabilities;
  final Set<FeatureFlag> killSwitches;
  final bool globalKillSwitch;

  bool localAllows(FeatureFlag flag) => localGates[flag] == true;

  bool backendAllows(FeatureFlag flag) => backendCapabilities[flag] == true;

  bool platformAllows(FeatureFlag flag) => platformCapabilities[flag] == true;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeatureFlagGateState &&
            globalKillSwitch == other.globalKillSwitch &&
            mapEquals(localGates, other.localGates) &&
            mapEquals(backendCapabilities, other.backendCapabilities) &&
            mapEquals(platformCapabilities, other.platformCapabilities) &&
            setEquals(killSwitches, other.killSwitches);
  }

  @override
  int get hashCode => Object.hash(
        globalKillSwitch,
        Object.hashAll(
          FeatureFlag.values.map(
            (flag) => Object.hash(flag, localGates[flag]),
          ),
        ),
        Object.hashAll(
          FeatureFlag.values.map(
            (flag) => Object.hash(flag, backendCapabilities[flag]),
          ),
        ),
        Object.hashAll(
          FeatureFlag.values.map(
            (flag) => Object.hash(flag, platformCapabilities[flag]),
          ),
        ),
        Object.hashAllUnordered(killSwitches),
      );
}

class FeatureFlagDecision {
  const FeatureFlagDecision({
    required this.flag,
    required this.enabled,
    required this.reason,
    required this.remoteValue,
    required this.snapshotReleaseId,
  });

  final FeatureFlag flag;
  final bool enabled;
  final FeatureFlagDecisionReason reason;
  final bool remoteValue;
  final String snapshotReleaseId;
}

class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService({
    FeatureFlagSnapshot? initialSnapshot,
    FeatureFlagGateState? initialGates,
    Duration criticalSnapshotMaxAge = const Duration(hours: 24),
    DateTime Function()? clock,
  })  : _snapshot = initialSnapshot ?? FeatureFlagSnapshot.defaults(),
        _gates = initialGates ?? FeatureFlagGateState.closed(),
        _criticalSnapshotMaxAge = criticalSnapshotMaxAge,
        _clock = clock ?? DateTime.now;

  static final FeatureFlagService instance = FeatureFlagService();

  FeatureFlagSnapshot _snapshot;
  FeatureFlagGateState _gates;
  final Duration _criticalSnapshotMaxAge;
  final DateTime Function() _clock;

  FeatureFlagSnapshot get snapshot => _snapshot;
  FeatureFlagGateState get gates => _gates;

  bool isEnabled(FeatureFlag flag) => evaluate(flag).enabled;

  FeatureFlagDecision evaluate(FeatureFlag flag) {
    final definition = FeatureFlagContract.definitionFor(flag);
    final remoteValue = _snapshot.remoteValueFor(flag);

    FeatureFlagDecision blocked(FeatureFlagDecisionReason reason) {
      return FeatureFlagDecision(
        flag: flag,
        enabled: false,
        reason: reason,
        remoteValue: remoteValue,
        snapshotReleaseId: _snapshot.releaseId,
      );
    }

    // A kill switch tem precedencia absoluta sobre todas as fontes.
    if (_snapshot.globalKillSwitch || _gates.globalKillSwitch) {
      return blocked(FeatureFlagDecisionReason.globalKillSwitch);
    }
    if (_gates.killSwitches.contains(flag)) {
      return blocked(FeatureFlagDecisionReason.flagKillSwitch);
    }
    if (!_snapshot.isCompatible) {
      return blocked(FeatureFlagDecisionReason.incompatibleContract);
    }

    // Para capacidades protegidas a ordem e local -> remoto -> backend ->
    // plataforma. Uma capacidade ausente nunca e interpretada como aprovada.
    if (definition.requiresLocalGate && !_gates.localAllows(flag)) {
      return blocked(FeatureFlagDecisionReason.localGateClosed);
    }
    if (definition.stalePolicy == FeatureFlagStalePolicy.failClosed &&
        _snapshot.isStaleAt(_clock(), _criticalSnapshotMaxAge)) {
      return blocked(FeatureFlagDecisionReason.staleRemoteSnapshot);
    }
    if (!remoteValue) {
      return blocked(FeatureFlagDecisionReason.remoteDisabled);
    }
    if (definition.requiresBackendCapability && !_gates.backendAllows(flag)) {
      return blocked(FeatureFlagDecisionReason.backendCapabilityMissing);
    }
    if (definition.requiresPlatformCapability && !_gates.platformAllows(flag)) {
      return blocked(FeatureFlagDecisionReason.platformUnsupported);
    }

    return FeatureFlagDecision(
      flag: flag,
      enabled: true,
      reason: FeatureFlagDecisionReason.enabled,
      remoteValue: true,
      snapshotReleaseId: _snapshot.releaseId,
    );
  }

  void applySnapshot(FeatureFlagSnapshot snapshot) {
    if (_snapshot == snapshot) return;
    _snapshot = snapshot;
    notifyListeners();
  }

  void updateGates(FeatureFlagGateState gates) {
    if (_gates == gates) return;
    _gates = gates;
    notifyListeners();
  }
}
