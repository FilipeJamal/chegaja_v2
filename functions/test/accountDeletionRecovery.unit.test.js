const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('account deletion recovery primitives', () => {
  it('enumerates every UID-owned storage prefix', () => {
    assert.deepStrictEqual(
      __test__.accounts.accountDeletionStoragePrefixes('person-1'),
      [
        'users/person-1/',
        'prestadores/person-1/',
        'kyc_pending/person-1/',
        'profile_public/person-1/',
        'portfolio/person-1/',
        'stories/person-1/',
        'temp/person-1/',
        'kyc/person-1/',
        'category_evidence/person-1/',
      ],
    );
  });

  it('permits an expired executing lease to resume but not a live lease', () => {
    const nowMillis = 10_000;
    assert.strictEqual(__test__.accounts.accountDeletionRequestCanExecute({
      status: 'executing',
      executeAt: { toMillis: () => 1_000 },
      leaseUntil: { toMillis: () => 9_999 },
    }, nowMillis), true);
    assert.strictEqual(__test__.accounts.accountDeletionRequestCanExecute({
      status: 'executing',
      executeAt: { toMillis: () => 1_000 },
      leaseUntil: { toMillis: () => 10_001 },
    }, nowMillis), false);
  });

  it('replaces raw UIDs recursively without mutating Firestore value objects', () => {
    const timestamp = { toMillis: () => 123 };
    const result = __test__.accounts.pseudonymizeUidInValue({
      targetId: 'person-1_category',
      metadata: { providerId: 'person-1', roles: ['provider', 'person-1'] },
      acceptedAt: timestamp,
    }, 'person-1', 'deleted:hash');
    assert.strictEqual(result.changed, true);
    assert.deepStrictEqual(result.value.targetId, 'deleted:hash_category');
    assert.strictEqual(result.value.metadata.providerId, 'deleted:hash');
    assert.strictEqual(result.value.metadata.roles[1], 'deleted:hash');
    assert.strictEqual(result.value.acceptedAt, timestamp);
  });

  it('denies new work for deletion-pending accounts', () => {
    assert.strictEqual(
      __test__.accounts.accountAllowsNewWork({ accountStatus: 'deletion_pending' }),
      false,
    );
    assert.strictEqual(
      __test__.accounts.accountAllowsNewWork({ accountStatus: 'active' }),
      true,
    );
  });
});
