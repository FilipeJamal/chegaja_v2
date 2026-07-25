import 'feature_flag_snapshot.dart';

abstract interface class FeatureFlagSnapshotProvider {
  Future<FeatureFlagSnapshot> initialize();

  Stream<FeatureFlagSnapshot> get snapshots;
}
