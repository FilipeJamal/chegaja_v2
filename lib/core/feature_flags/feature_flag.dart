enum FeatureFlagRisk {
  standard,
  sensitive,
  critical,
}

enum FeatureFlagStalePolicy {
  keepLastKnownGood,
  failClosed,
}

enum FeatureFlag {
  kyc,
  stripePayments,
  mpesaPayments,
  emolaPayments,
  stories,
  calls,
  noShowReporting,
  subscriptions,
  advancedRanking,
  windowsPublic,
  u1NavigationV2,
  u2AdaptiveRequest,
  u3MatchingV2,
  u4PricingV2,
  u5JobOrchestrationV2,
  u6PaymentsV2,
  u7TrustPassportV2,
  u8SafetySupportV2,
  u9ProviderOperatingSystemV2,
  u10GrowthV2,
  u11AnalyticsExperiments,
  u12InternationalizationV2,
}

class FeatureFlagDefinition {
  const FeatureFlagDefinition({
    required this.flag,
    required this.remoteKey,
    required this.introducedIn,
    this.defaultValue = false,
    this.risk = FeatureFlagRisk.standard,
    this.stalePolicy = FeatureFlagStalePolicy.keepLastKnownGood,
    this.requiresLocalGate = false,
    this.requiresBackendCapability = false,
    this.requiresPlatformCapability = false,
  });

  final FeatureFlag flag;
  final String remoteKey;
  final String introducedIn;
  final bool defaultValue;
  final FeatureFlagRisk risk;
  final FeatureFlagStalePolicy stalePolicy;
  final bool requiresLocalGate;
  final bool requiresBackendCapability;
  final bool requiresPlatformCapability;

  bool get isCritical => risk == FeatureFlagRisk.critical;
}

class FeatureFlagContract {
  const FeatureFlagContract._();

  static const int version = 1;
  static const String contractVersionKey = 'feature_contract_version';
  static const String releaseIdKey = 'feature_release_id';
  static const String globalKillSwitchKey = 'global_kill_switch';
  static const String maintenanceModeKey = 'maintenance_mode';
  static const String legacyMinAndroidVersionKey = 'min_android_version';

  static const Map<FeatureFlag, FeatureFlagDefinition> definitions = {
    FeatureFlag.kyc: FeatureFlagDefinition(
      flag: FeatureFlag.kyc,
      remoteKey: 'feature_kyc_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.stripePayments: FeatureFlagDefinition(
      flag: FeatureFlag.stripePayments,
      remoteKey: 'feature_stripe_payments_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.mpesaPayments: FeatureFlagDefinition(
      flag: FeatureFlag.mpesaPayments,
      remoteKey: 'feature_mpesa_payments_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.emolaPayments: FeatureFlagDefinition(
      flag: FeatureFlag.emolaPayments,
      remoteKey: 'feature_emola_payments_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.stories: FeatureFlagDefinition(
      flag: FeatureFlag.stories,
      remoteKey: 'feature_stories_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.calls: FeatureFlagDefinition(
      flag: FeatureFlag.calls,
      remoteKey: 'feature_calls_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.noShowReporting: FeatureFlagDefinition(
      flag: FeatureFlag.noShowReporting,
      remoteKey: 'feature_no_show_reporting_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
    ),
    FeatureFlag.subscriptions: FeatureFlagDefinition(
      flag: FeatureFlag.subscriptions,
      remoteKey: 'feature_subscriptions_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.advancedRanking: FeatureFlagDefinition(
      flag: FeatureFlag.advancedRanking,
      remoteKey: 'feature_advanced_ranking_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
    ),
    FeatureFlag.windowsPublic: FeatureFlagDefinition(
      flag: FeatureFlag.windowsPublic,
      remoteKey: 'feature_windows_public_enabled',
      introducedIn: 'P1',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.u1NavigationV2: FeatureFlagDefinition(
      flag: FeatureFlag.u1NavigationV2,
      remoteKey: 'feature_u1_navigation_v2',
      introducedIn: 'U1',
    ),
    FeatureFlag.u2AdaptiveRequest: FeatureFlagDefinition(
      flag: FeatureFlag.u2AdaptiveRequest,
      remoteKey: 'feature_u2_adaptive_request',
      introducedIn: 'U2',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u3MatchingV2: FeatureFlagDefinition(
      flag: FeatureFlag.u3MatchingV2,
      remoteKey: 'feature_u3_matching_v2',
      introducedIn: 'U3',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u4PricingV2: FeatureFlagDefinition(
      flag: FeatureFlag.u4PricingV2,
      remoteKey: 'feature_u4_pricing_v2',
      introducedIn: 'U4',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u5JobOrchestrationV2: FeatureFlagDefinition(
      flag: FeatureFlag.u5JobOrchestrationV2,
      remoteKey: 'feature_u5_job_orchestration_v2',
      introducedIn: 'U5',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u6PaymentsV2: FeatureFlagDefinition(
      flag: FeatureFlag.u6PaymentsV2,
      remoteKey: 'feature_u6_payments_v2',
      introducedIn: 'U6',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.u7TrustPassportV2: FeatureFlagDefinition(
      flag: FeatureFlag.u7TrustPassportV2,
      remoteKey: 'feature_u7_trust_passport_v2',
      introducedIn: 'U7',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u8SafetySupportV2: FeatureFlagDefinition(
      flag: FeatureFlag.u8SafetySupportV2,
      remoteKey: 'feature_u8_safety_support_v2',
      introducedIn: 'U8',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u9ProviderOperatingSystemV2: FeatureFlagDefinition(
      flag: FeatureFlag.u9ProviderOperatingSystemV2,
      remoteKey: 'feature_u9_provider_operating_system_v2',
      introducedIn: 'U9',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u10GrowthV2: FeatureFlagDefinition(
      flag: FeatureFlag.u10GrowthV2,
      remoteKey: 'feature_u10_growth_v2',
      introducedIn: 'U10',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresBackendCapability: true,
    ),
    FeatureFlag.u11AnalyticsExperiments: FeatureFlagDefinition(
      flag: FeatureFlag.u11AnalyticsExperiments,
      remoteKey: 'feature_u11_analytics_experiments',
      introducedIn: 'U11',
      risk: FeatureFlagRisk.sensitive,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
      requiresPlatformCapability: true,
    ),
    FeatureFlag.u12InternationalizationV2: FeatureFlagDefinition(
      flag: FeatureFlag.u12InternationalizationV2,
      remoteKey: 'feature_u12_internationalization_v2',
      introducedIn: 'U12',
      risk: FeatureFlagRisk.critical,
      stalePolicy: FeatureFlagStalePolicy.failClosed,
      requiresLocalGate: true,
      requiresBackendCapability: true,
    ),
  };

  static FeatureFlagDefinition definitionFor(FeatureFlag flag) {
    return definitions[flag]!;
  }

  static Map<String, Object> get remoteDefaults {
    return <String, Object>{
      contractVersionKey: version,
      releaseIdKey: 'bundled-defaults-v$version',
      globalKillSwitchKey: false,
      maintenanceModeKey: false,
      legacyMinAndroidVersionKey: 21,
      for (final definition in definitions.values)
        definition.remoteKey: definition.defaultValue,
    };
  }
}
