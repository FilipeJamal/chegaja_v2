const assert = require('assert');

const { __test__ } = require('../index');

const {
  PRIVATE_STORAGE_SIGNED_URL_TTL_MS,
  authorizePrivateStoragePath,
  finalizePrivateStorageUploadCore,
  getPrivateStorageReadUrlCore,
  normalizePrivateStoragePath,
} = __test__.privateStorage;
const { promotePedidoAttachments } = __test__.pedidos;

function fakeDatabase(pedidoData) {
  return {
    collection(name) {
      assert.strictEqual(name, 'pedidos');
      return {
        doc() {
          return {
            async get() {
              return pedidoData
                ? { exists: true, data: () => pedidoData }
                : { exists: false, data: () => undefined };
            },
          };
        },
      };
    },
  };
}

function fakeStorage() {
  const calls = { setMetadata: null, signedUrlOptions: null };
  return {
    calls,
    bucket() {
      return {
        file(path) {
          return {
            async getMetadata() {
              return [{ size: '1024', metadata: { firebaseStorageDownloadTokens: 'old' } }];
            },
            async setMetadata(value) {
              calls.setMetadata = { path, value };
            },
            async getSignedUrl(options) {
              calls.signedUrlOptions = { path, options };
              return ['https://signed.invalid/private'];
            },
          };
        },
      };
    },
  };
}

assert.deepStrictEqual(
  normalizePrivateStoragePath('chats/p1/images/photo.jpg'),
  {
    storagePath: 'chats/p1/images/photo.jpg',
    scope: 'chats',
    ownerId: '',
    pedidoId: 'p1',
  },
);
assert.throws(() => normalizePrivateStoragePath('../secret'), /Caminho/);
assert.throws(() => normalizePrivateStoragePath('portfolio/u1/photo.jpg'), /areas privadas/);

async function run() {
  const database = fakeDatabase({ clienteId: 'client', prestadorId: 'provider' });
  assert.strictEqual(
    (await authorizePrivateStoragePath({
      database,
      auth: { uid: 'client', token: {} },
      storagePath: 'chats/p1/files/file.pdf',
    })).pedidoId,
    'p1',
  );
  await assert.rejects(
    authorizePrivateStoragePath({
      database,
      auth: { uid: 'attacker', token: {} },
      storagePath: 'chats/p1/files/file.pdf',
    }),
    /Sem acesso/,
  );
  await assert.rejects(
    authorizePrivateStoragePath({
      database,
      auth: { uid: 'u2', token: {} },
      storagePath: 'temp/u1/anexos/file.pdf',
    }),
    /Sem acesso/,
  );

  const storage = fakeStorage();
  const finalized = await finalizePrivateStorageUploadCore({
    database,
    storage,
    auth: { uid: 'client', token: {} },
    data: { path: 'chats/p1/files/file.pdf' },
  });
  assert.strictEqual(finalized.persistentDownloadTokenRemoved, true);
  assert.strictEqual(
    storage.calls.setMetadata.value.metadata.firebaseStorageDownloadTokens,
    null,
  );
  assert.strictEqual(storage.calls.setMetadata.value.cacheControl, 'private, no-store, max-age=0');

  const before = Date.now();
  const signed = await getPrivateStorageReadUrlCore({
    database,
    storage,
    auth: { uid: 'provider', token: {} },
    data: { path: 'chats/p1/files/file.pdf' },
  });
  assert.strictEqual(signed.url, 'https://signed.invalid/private');
  assert.ok(signed.expiresAtMillis >= before + PRIVATE_STORAGE_SIGNED_URL_TTL_MS - 1000);
  assert.ok(signed.expiresAtMillis <= before + PRIVATE_STORAGE_SIGNED_URL_TTL_MS + 1000);

  const promotedCalls = { copy: null, metadata: null };
  const promotedStorage = {
    bucket() {
      return {
        file(path) {
          return {
            async getMetadata() {
              return [{ size: '2048', metadata: { chegajaPrivateAccess: 'authenticated' } }];
            },
            async copy(destinationFile) {
              promotedCalls.copy = { source: path, destination: destinationFile.path };
            },
            async setMetadata(value) {
              promotedCalls.metadata = { path, value };
            },
            path,
          };
        },
      };
    },
  };
  const promoted = await promotePedidoAttachments({
    storage: promotedStorage,
    uid: 'client',
    pedidoId: 'p1',
    attachments: ['temp/client/anexos/photo.jpg'],
  });
  assert.deepStrictEqual(promoted, ['pedidos/p1/anexos/photo.jpg']);
  assert.deepStrictEqual(promotedCalls.copy, {
    source: 'temp/client/anexos/photo.jpg',
    destination: 'pedidos/p1/anexos/photo.jpg',
  });
  assert.strictEqual(
    promotedCalls.metadata.value.metadata.firebaseStorageDownloadTokens,
    null,
  );
  await assert.rejects(
    promotePedidoAttachments({
      storage: promotedStorage,
      uid: 'attacker',
      pedidoId: 'p1',
      attachments: ['temp/client/anexos/photo.jpg'],
    }),
    /fora da area autorizada/,
  );
}

run()
  .then(() => console.log('private storage token and access safeguards ok'))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
