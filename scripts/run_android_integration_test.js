const { spawnSync } = require('child_process');

const testFile = process.argv[2];

if (!testFile) {
  console.error('Usage: node scripts/run_android_integration_test.js <integration_test/file.dart>');
  process.exit(2);
}

const requestedDeviceId = process.env.ANDROID_DEVICE_ID;
let deviceId = requestedDeviceId;

if (!deviceId) {
  const devicesResult = spawnSync('flutter', ['devices', '--machine'], {
    encoding: 'utf8',
    shell: process.platform === 'win32',
  });

  if (devicesResult.error) {
    console.error(devicesResult.error.message);
    process.exit(1);
  }

  if (devicesResult.status !== 0) {
    process.stderr.write(devicesResult.stderr || devicesResult.stdout);
    process.exit(devicesResult.status || 1);
  }

  let devices;
  try {
    devices = JSON.parse(devicesResult.stdout);
  } catch (error) {
    console.error(`Could not parse Flutter devices output: ${error.message}`);
    process.exit(1);
  }

  const androidDevice = devices.find(
    (device) =>
      device.isSupported &&
      typeof device.targetPlatform === 'string' &&
      device.targetPlatform.startsWith('android-')
  );

  if (!androidDevice) {
    console.error('No supported Android device found. Start an emulator or connect an Android device.');
    process.exit(1);
  }

  deviceId = androidDevice.id;
}

const result = spawnSync(
  'flutter',
  [
    'test',
    '--ignore-timeouts',
    testFile,
    '-d',
    deviceId,
    '--dart-define=RUN_FIREBASE_EMULATOR_TESTS=true',
  ],
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
