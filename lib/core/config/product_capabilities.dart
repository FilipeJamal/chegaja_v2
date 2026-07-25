import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../feature_flags/feature_flag.dart';
import '../feature_flags/feature_flag_service.dart';
import '../utils/platform_caps.dart';

typedef EnvironmentValueReader = String? Function(String key);

class ProductCapabilities {
  const ProductCapabilities._();

  static FeatureFlagGateState resolve({
    EnvironmentValueReader? environment,
    Map<FeatureFlag, bool> backendCapabilities = const {},
    Map<FeatureFlag, bool>? platformCapabilities,
  }) {
    final read = environment ?? _readEnvironment;
    return FeatureFlagGateState(
      globalKillSwitch: _readBool(read('GLOBAL_KILL_SWITCH')),
      localGates: {
        FeatureFlag.kyc: _readBool(read('ENABLE_KYC')),
        FeatureFlag.stripePayments: _readBool(read('ENABLE_STRIPE')),
        FeatureFlag.mpesaPayments: _readBool(read('ENABLE_MPESA')),
        FeatureFlag.emolaPayments: _readBool(read('ENABLE_EMOLA')),
        FeatureFlag.stories: _readBool(read('ENABLE_STORIES')),
        FeatureFlag.calls: _readBool(read('ENABLE_CALLS')),
        FeatureFlag.noShowReporting:
            _readBool(read('ENABLE_NO_SHOW_REPORTING')),
        FeatureFlag.subscriptions: _readBool(read('ENABLE_SUBSCRIPTIONS')),
        FeatureFlag.advancedRanking: _readBool(read('ENABLE_ADVANCED_RANKING')),
        FeatureFlag.windowsPublic: _readBool(read('ENABLE_WINDOWS_PUBLIC')),
        FeatureFlag.u6PaymentsV2: _readBool(read('ENABLE_U6_PAYMENTS_V2')),
        FeatureFlag.u11AnalyticsExperiments:
            _readBool(read('ENABLE_ANALYTICS')),
        FeatureFlag.u12InternationalizationV2:
            _readBool(read('ENABLE_U12_INTERNATIONALIZATION_V2')),
      },
      backendCapabilities: backendCapabilities,
      platformCapabilities: platformCapabilities ?? _platformCapabilities(),
      killSwitches: {
        for (final flag in FeatureFlag.values)
          if (_readBool(read('KILL_${_environmentSuffix(flag)}'))) flag,
      },
    );
  }

  static Map<FeatureFlag, bool> _platformCapabilities() {
    final supportsFirebaseClient =
        PlatformCaps.supportsCloudFunctions && !PlatformCaps.isTestMode;
    return {
      FeatureFlag.kyc: supportsFirebaseClient,
      FeatureFlag.stripePayments:
          PlatformCaps.supportsStripe && !PlatformCaps.isTestMode,
      FeatureFlag.mpesaPayments: supportsFirebaseClient,
      FeatureFlag.emolaPayments: supportsFirebaseClient,
      FeatureFlag.stories: (PlatformCaps.isAndroid ||
          PlatformCaps.isIOS ||
          PlatformCaps.isMacOS),
      FeatureFlag.calls: PlatformCaps.supportsCalls,
      FeatureFlag.subscriptions: supportsFirebaseClient,
      FeatureFlag.windowsPublic: PlatformCaps.isWindows,
      FeatureFlag.u6PaymentsV2: supportsFirebaseClient,
      FeatureFlag.u11AnalyticsExperiments: PlatformCaps.supportsAnalytics,
      FeatureFlag.u12InternationalizationV2: true,
    };
  }

  static String? _readEnvironment(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  static bool _readBool(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'true' || '1' || 'yes' => true,
      _ => false,
    };
  }

  static String _environmentSuffix(FeatureFlag flag) {
    return flag.name
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toUpperCase();
  }
}
