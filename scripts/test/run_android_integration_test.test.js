const assert = require('assert');

const { buildFlutterTestArgs } = require('../run_android_integration_test');

const args = buildFlutterTestArgs({
  testFile: 'integration_test/android_functions_flow_test.dart',
  deviceId: 'emulator-5554',
  useFunctionsEmulator: true,
});

assert.deepStrictEqual(args, [
  'test',
  '--ignore-timeouts',
  'integration_test/android_functions_flow_test.dart',
  '-d',
  'emulator-5554',
  '--dart-define=RUN_FIREBASE_EMULATOR_TESTS=true',
  '--dart-define=RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS=true',
]);

console.log('run_android_integration_test args ok');
