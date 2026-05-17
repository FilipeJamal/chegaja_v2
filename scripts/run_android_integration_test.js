const { spawnSync } = require('child_process');

function parseArgs(argv) {
  let useFunctionsEmulator = false;
  let testFile = null;

  for (const arg of argv) {
    if (arg === '--functions-emulator') {
      useFunctionsEmulator = true;
    } else if (!testFile) {
      testFile = arg;
    } else {
      throw new Error(`Unexpected argument: ${arg}`);
    }
  }

  return { testFile, useFunctionsEmulator };
}

function buildFlutterTestArgs({
  testFile,
  deviceId,
  useFunctionsEmulator = false,
}) {
  const args = [
    'test',
    '--ignore-timeouts',
    testFile,
    '-d',
    deviceId,
    '--dart-define=RUN_FIREBASE_EMULATOR_TESTS=true',
  ];

  if (useFunctionsEmulator) {
    args.push('--dart-define=RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS=true');
  }

  return args;
}

function findAndroidDeviceId() {
  const devicesResult = spawnSync('flutter', ['devices', '--machine'], {
    encoding: 'utf8',
    shell: process.platform === 'win32',
  });

  if (devicesResult.error) {
    throw new Error(devicesResult.error.message);
  }

  if (devicesResult.status !== 0) {
    const error = devicesResult.stderr || devicesResult.stdout;
    const e = new Error(error);
    e.status = devicesResult.status || 1;
    throw e;
  }

  let devices;
  try {
    devices = JSON.parse(devicesResult.stdout);
  } catch (error) {
    throw new Error(`Could not parse Flutter devices output: ${error.message}`);
  }

  const androidDevice = devices.find(
    (device) =>
      device.isSupported &&
      typeof device.targetPlatform === 'string' &&
      device.targetPlatform.startsWith('android-')
  );

  if (!androidDevice) {
    throw new Error('No supported Android device found. Start an emulator or connect an Android device.');
  }

  return androidDevice.id;
}

function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exit(2);
  }

  const { testFile, useFunctionsEmulator } = parsed;
  if (!testFile) {
    console.error('Usage: node scripts/run_android_integration_test.js [--functions-emulator] <integration_test/file.dart>');
    process.exit(2);
  }

  let deviceId = process.env.ANDROID_DEVICE_ID;
  if (!deviceId) {
    try {
      deviceId = findAndroidDeviceId();
    } catch (error) {
      console.error(error.message);
      process.exit(error.status || 1);
    }
  }

  const result = spawnSync(
    'flutter',
    buildFlutterTestArgs({ testFile, deviceId, useFunctionsEmulator }),
    {
      stdio: 'inherit',
      shell: process.platform === 'win32',
    }
  );

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  process.exit(result.status ?? 1);
}

if (require.main === module) {
  main();
}

module.exports = {
  buildFlutterTestArgs,
  parseArgs,
};
