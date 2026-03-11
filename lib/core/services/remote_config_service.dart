import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 12),
      ),);

      await _remoteConfig.setDefaults(const {
        'default_commission_rate': 0.15,
        'min_android_version': 21,
        'maintenance_mode': false,
      });

      await _remoteConfig.fetchAndActivate();
      debugPrint('[RemoteConfig] Initialized');
    } catch (e) {
      debugPrint('[RemoteConfig] Error initializing: $e');
    }
  }

  double getCommissionRate() {
    return _remoteConfig.getDouble('default_commission_rate');
  }

  int getMinAndroidVersion() {
    return _remoteConfig.getInt('min_android_version');
  }

  bool getMaintenanceMode() {
    return _remoteConfig.getBool('maintenance_mode');
  }
}
