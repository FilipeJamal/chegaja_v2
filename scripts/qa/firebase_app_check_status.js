/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');

const auth = require('firebase-tools/lib/auth');
const { Client } = require('firebase-tools/lib/apiv2');
const { requireAuth } = require('firebase-tools/lib/requireAuth');

const root = path.resolve(__dirname, '../..');

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

async function main() {
  const googleServices = JSON.parse(read('android/app/google-services.json'));
  const gradle = read('android/app/build.gradle.kts');
  const packageMatch = gradle.match(/applicationId\s*=\s*"([^"]+)"/);
  const packageId = packageMatch ? packageMatch[1] : '';
  const clientConfig = googleServices.client.find(
    (item) => item.client_info.android_client_info.package_name === packageId,
  );
  if (!clientConfig) throw new Error(`Firebase Android app não encontrada para ${packageId}.`);

  const projectId = googleServices.project_info.project_id;
  const projectNumber = googleServices.project_info.project_number;
  const appId = clientConfig.client_info.mobilesdk_app_id;
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Execute firebase login antes de consultar o App Check.');
  await requireAuth({ project: projectId, nonInteractive: true, ...account });

  const appCheck = new Client({
    urlPrefix: 'https://firebaseappcheck.googleapis.com',
    apiVersion: 'v1',
  });
  const serviceResponse = await appCheck.get(`/projects/${projectNumber}/services`);
  const serviceItems = serviceResponse.body.services || [];
  const serviceMode = (id) => serviceItems.find((item) => item.name.endsWith(`/services/${id}`))
    ?.enforcementMode || 'OFF';
  const integrityResponse = await appCheck.get(
    `/projects/${projectNumber}/apps/${appId}/playIntegrityConfig`,
  );
  const integrity = integrityResponse.body;
  const functionsSource = read('functions/index.js');

  console.log(JSON.stringify({
    capturedAt: new Date().toISOString(),
    projectId,
    projectNumber,
    appId,
    packageId,
    services: {
      firestore: serviceMode('firestore.googleapis.com'),
      storage: serviceMode('firebasestorage.googleapis.com'),
      authentication: serviceMode('identitytoolkit.googleapis.com'),
    },
    playIntegrity: {
      tokenTtl: integrity.tokenTtl || '3600s',
      allowUnrecognizedVersion: integrity.appIntegrity?.allowUnrecognizedVersion === true,
      minDeviceRecognitionLevel:
        integrity.deviceIntegrity?.minDeviceRecognitionLevel || 'NO_INTEGRITY',
      requireLicensed: integrity.accountDetails?.requireLicensed === true,
    },
    sourceCallableEnforcement: functionsSource.includes('enforceAppCheck: !useEmulators'),
  }, null, 2));
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
