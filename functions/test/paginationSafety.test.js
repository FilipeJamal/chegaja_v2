const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

function fakeDatabase(collections) {
  return {
    collection(name) {
      return {
        where(field, operator, value) {
          assert.strictEqual(operator, '==');
          let resultLimit = Number.MAX_SAFE_INTEGER;
          let afterId = null;
          const query = {
            orderBy() {
              return query;
            },
            limit(limit) {
              resultLimit = limit;
              return query;
            },
            startAfter(cursor) {
              afterId = cursor.id;
              return query;
            },
            async get() {
              const records = (collections[name] || [])
                .filter((record) => !record.deleted && record.data[field] === value)
                .sort((left, right) => left.id.localeCompare(right.id))
                .filter((record) => afterId === null || record.id > afterId)
                .slice(0, resultLimit);
              const docs = records.map((record) => ({
                id: record.id,
                data: () => ({ ...record.data }),
                ref: { record },
              }));
              return { docs, empty: docs.length === 0, size: docs.length };
            },
          };
          return query;
        },
      };
    },
    bulkWriter() {
      const updates = [];
      return {
        update(ref, patch) {
          updates.push({ ref, patch });
        },
        async close() {
          updates.forEach(({ ref, patch }) => Object.assign(ref.record.data, patch));
        },
      };
    },
    async recursiveDelete(ref) {
      ref.record.deleted = true;
    },
  };
}

describe('authoritative pagination safety', () => {
  it('updates and recursively deletes every matching record beyond 500 documents', async () => {
    const sourceUid = 'source-user';
    const targetUid = 'target-user';
    const collections = {
      retained: Array.from({ length: 501 }, (_, index) => ({
        id: String(index),
        data: { ownerId: sourceUid },
        deleted: false,
      })),
      ephemeral: Array.from({ length: 501 }, (_, index) => ({
        id: String(index),
        data: { ownerId: sourceUid },
        deleted: false,
      })),
    };
    const database = fakeDatabase(collections);

    const updated = await __test__.accounts.updateMatchingDocuments({
      database,
      collection: 'retained',
      field: 'ownerId',
      uid: sourceUid,
      update: { ownerId: targetUid },
    });
    const deleted = await __test__.accounts.deleteMatchingDocuments({
      database,
      collection: 'ephemeral',
      field: 'ownerId',
      uid: sourceUid,
    });

    assert.strictEqual(updated, 501);
    assert.strictEqual(deleted, 501);
    assert.strictEqual(
      collections.retained.filter((record) => record.data.ownerId === targetUid).length,
      501,
    );
    assert.strictEqual(collections.ephemeral.filter((record) => record.deleted).length, 501);
  });

  it('finds active work after the first page and treats lifecycle conflicts as active', async () => {
    const uid = 'account-owner';
    const pedidos = Array.from({ length: 205 }, (_, index) => ({
      id: String(index).padStart(4, '0'),
      data: {
        clienteId: uid,
        status: index === 203 ? 'concluido' : (index === 204 ? 'aceito' : 'concluido'),
        estado: index === 203 ? 'cancelado' : (index === 204 ? 'aceito' : 'concluido'),
      },
      deleted: false,
    }));

    const active = await __test__.accounts.findActiveAccountOrders({
      database: fakeDatabase({ pedidos }),
      uid,
      pageSize: 50,
    });

    assert.deepStrictEqual(active.map((doc) => doc.id).sort(), ['0203', '0204']);
  });
});
