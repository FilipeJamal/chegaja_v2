const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
const { __test__ } = require('../index');

describe('KYC security helpers', () => {
  it('accepts only unique internal paths from the active submission', () => {
    const paths = __test__.kyc.normalizeKycDocumentPaths({
      uid: 'provider1',
      submissionId: 'submission1',
      documentPaths: [
        'kyc_pending/provider1/submission1/front.jpg',
        'kyc_pending/provider1/submission1/back.jpg',
      ],
    });
    assert.deepStrictEqual(paths, [
      'kyc_pending/provider1/submission1/front.jpg',
      'kyc_pending/provider1/submission1/back.jpg',
    ]);
  });

  it('rejects another user, another submission, traversal and duplicates', () => {
    const invalidSets = [
      ['kyc_pending/attacker/submission1/front.jpg'],
      ['kyc_pending/provider1/other/front.jpg'],
      ['kyc_pending/provider1/submission1/../secret.jpg'],
      [
        'kyc_pending/provider1/submission1/front.jpg',
        'kyc_pending/provider1/submission1/front.jpg',
      ],
    ];
    invalidSets.forEach((documentPaths) => {
      assert.throws(() => __test__.kyc.normalizeKycDocumentPaths({
        uid: 'provider1',
        submissionId: 'submission1',
        documentPaths,
      }));
    });
  });

  it('uses explicit review decisions and a versioned consent', () => {
    assert.strictEqual(__test__.kyc.normalizeKycDecision('APPROVED'), 'approved');
    assert.strictEqual(__test__.kyc.KYC_CONSENT_VERSION, 'kyc-consent-2026-07-20');
    assert.throws(() => __test__.kyc.normalizeKycDecision('verified'));
  });
});
