import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';

void main() {
  test('versioned Remote Config template matches typed safe defaults', () {
    final raw = File('remoteconfig.template.json').readAsStringSync();
    final template = jsonDecode(raw) as Map<String, dynamic>;
    final parameters = Map<String, dynamic>.from(template['parameters'] as Map);
    final expected = FeatureFlagContract.remoteDefaults;

    expect(parameters.keys.toSet(), expected.keys.toSet());
    for (final entry in expected.entries) {
      final parameter = Map<String, dynamic>.from(parameters[entry.key] as Map);
      final defaultValue =
          Map<String, dynamic>.from(parameter['defaultValue'] as Map);
      expect(
        defaultValue['value'],
        entry.value.toString(),
        reason: entry.key,
      );
    }
  });
}
