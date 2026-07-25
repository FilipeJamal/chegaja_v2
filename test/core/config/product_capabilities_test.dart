import 'package:chegaja_v2/core/config/product_capabilities.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local gates are closed when configuration is missing', () {
    final gates = ProductCapabilities.resolve(
      environment: (_) => null,
      platformCapabilities: const {},
    );

    expect(gates.localAllows(FeatureFlag.kyc), isFalse);
    expect(gates.localAllows(FeatureFlag.stripePayments), isFalse);
    expect(gates.localAllows(FeatureFlag.u11AnalyticsExperiments), isFalse);
    expect(gates.globalKillSwitch, isFalse);
  });

  test('reads explicit local gates without inventing backend approval', () {
    const values = {
      'ENABLE_KYC': 'true',
      'ENABLE_ANALYTICS': '1',
      'GLOBAL_KILL_SWITCH': 'false',
    };
    final gates = ProductCapabilities.resolve(
      environment: (key) => values[key],
      platformCapabilities: const {
        FeatureFlag.kyc: true,
        FeatureFlag.u11AnalyticsExperiments: true,
      },
    );

    expect(gates.localAllows(FeatureFlag.kyc), isTrue);
    expect(
      gates.localAllows(FeatureFlag.u11AnalyticsExperiments),
      isTrue,
    );
    expect(gates.backendAllows(FeatureFlag.kyc), isFalse);
  });

  test('global and per-feature kill switches take precedence', () {
    const values = {
      'GLOBAL_KILL_SWITCH': 'yes',
      'KILL_KYC': 'true',
    };
    final gates = ProductCapabilities.resolve(
      environment: (key) => values[key],
      platformCapabilities: const {},
    );

    expect(gates.globalKillSwitch, isTrue);
    expect(gates.killSwitches, contains(FeatureFlag.kyc));
  });
}
