const assert = require('assert');
const { Timestamp } = require('firebase-admin/firestore');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('anonymous account merge grant invariants', () => {
  const db = __test__.getDb();
  const sourceUid = 'anonymous-provider';
  const targetUid = 'phone-provider';
  let authEvents = [];
  let updateUserCalls = [];
  const authAdmin = {
    getUser: async (uid) => {
      authEvents.push({ type: 'getUser', uid });
      return { uid, phoneNumber: '+351910000010' };
    },
    verifyIdToken: async () => {
      authEvents.push({ type: 'verifyIdToken', uid: sourceUid });
      return {
        uid: sourceUid,
        firebase: { sign_in_provider: 'anonymous' },
      };
    },
    updateUser: async (uid, patch) => {
      authEvents.push({ type: 'updateUser', uid, patch });
      updateUserCalls.push({ uid, patch });

      // Prove that Auth is disabled only after the durable retry boundary,
      // source cleanup, and target phone synchronization have completed.
      const [tombstone, sourcePrivate, sourceFavorite, targetPrivate] = await Promise.all([
        db.collection('account_merge_sources').doc(sourceUid).get(),
        db.collection('users_private').doc(sourceUid).get(),
        db.collection('users_private').doc(sourceUid)
          .collection('favorites').doc('provider-favorite').get(),
        db.collection('users_private').doc(targetUid).get(),
      ]);
      assert.strictEqual(tombstone.exists, true);
      assert.strictEqual(tombstone.data().targetUid, targetUid);
      assert.strictEqual(sourcePrivate.exists, false);
      assert.strictEqual(sourceFavorite.exists, false);
      assert.strictEqual(targetPrivate.data().phoneVerified, true);
      return { uid, disabled: patch.disabled === true };
    },
  };
  const collections = [
    'account_merge_audit',
    'account_merge_sources',
    'chats',
    'pedidos',
    'pilot_participants',
    'provider_dispatch_private',
    'provider_private',
    'provider_public',
    'public_profiles',
    'prestadores',
    'users',
    'users_private',
  ];

  beforeEach(async () => {
    authEvents = [];
    updateUserCalls = [];
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  it('rekeys a valid accepted grant and revokes every malformed grant', async () => {
    const grantedAt = Timestamp.now();
    await Promise.all([
      db.collection('users_private').doc(sourceUid).set({
        uid: sourceUid,
        isAnonymous: true,
      }),
      db.collection('users_private').doc(targetUid).set({
        uid: targetUid,
        isAnonymous: false,
      }),
      db.collection('users_private').doc(sourceUid).collection('favorites').doc('provider-favorite').set({
        providerId: 'provider-favorite',
      }),
      db.collection('public_profiles').doc(sourceUid).set({
        uid: sourceUid,
        displayName: 'Anonymous profile',
      }),
      db.collection('provider_public').doc(sourceUid).set({
        uid: sourceUid,
        displayName: 'Anonymous provider',
      }),
      db.collection('provider_private').doc(sourceUid).set({
        providerId: sourceUid,
        privateMarker: true,
      }),
      db.collection('provider_dispatch_private').doc(sourceUid).set({
        providerId: sourceUid,
        dispatchMarker: true,
      }),
      db.collection('users').doc(sourceUid).set({
        uid: sourceUid,
        legacyUserMarker: true,
      }),
      db.collection('prestadores').doc(sourceUid).set({
        uid: sourceUid,
        legacyProviderMarker: true,
      }),
      db.collection('pedidos').doc('accepted-valid').set({
        clienteId: 'client-1',
        prestadorId: sourceUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: sourceUid,
        providerAccessGrantedAt: grantedAt,
        status: 'aceito',
        estado: 'aceito',
      }),
      db.collection('pedidos').doc('malformed-grant').set({
        clienteId: 'client-2',
        prestadorId: sourceUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: sourceUid,
        providerAccessGrantedAt: 'not-a-timestamp',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
      }),
      db.collection('pedidos').doc('cancelled-valid-marker').set({
        clienteId: 'client-cancelled',
        prestadorId: sourceUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: sourceUid,
        providerAccessGrantedAt: grantedAt,
        status: 'cancelado',
        estado: 'cancelado',
      }),
      db.collection('pedidos').doc('pending-valid-marker').set({
        clienteId: 'client-pending',
        prestadorId: sourceUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: sourceUid,
        providerAccessGrantedAt: grantedAt,
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
      }),
      db.collection('pedidos').doc('merge-self-dealing').set({
        clienteId: targetUid,
        prestadorId: sourceUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: sourceUid,
        providerAccessGrantedAt: grantedAt,
        status: 'aceito',
        estado: 'aceito',
      }),
      db.collection('pedidos').doc('client-merge-self-dealing').set({
        clienteId: sourceUid,
        prestadorId: targetUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: targetUid,
        providerAccessGrantedAt: grantedAt,
        status: 'aceito',
        estado: 'aceito',
      }),
      db.collection('pedidos').doc('legacy-client-alias').set({
        clientId: sourceUid,
        prestadorId: targetUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: targetUid,
        providerAccessGrantedAt: grantedAt,
        status: 'aceito',
        estado: 'aceito',
      }),
      db.collection('pedidos').doc('divergent-client-aliases').set({
        clienteId: sourceUid,
        clientId: 'different-client',
        prestadorId: sourceUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: sourceUid,
        providerAccessGrantedAt: grantedAt,
        status: 'aceito',
        estado: 'aceito',
      }),
      db.collection('chats').doc('accepted-valid').set({
        clienteId: 'client-1',
        prestadorId: sourceUid,
      }),
    ]);

    const result = await __test__.auth.mergeAnonymousDataCore({
      database: db,
      auth: { uid: targetUid },
      sourceIdToken: 'anonymous-source-token',
      authAdmin,
    });

    assert.strictEqual(result.ok, true);
    assert.strictEqual(result.idempotent, false);
    const valid = (await db.collection('pedidos').doc('accepted-valid').get()).data();
    assert.strictEqual(valid.prestadorId, targetUid);
    assert.strictEqual(valid.providerAccessGranted, true);
    assert.strictEqual(valid.providerAccessGrantedTo, targetUid);
    assert.strictEqual(valid.providerAccessGrantedAt.toMillis(), grantedAt.toMillis());

    const malformed = (await db.collection('pedidos').doc('malformed-grant').get()).data();
    assert.strictEqual(malformed.prestadorId, targetUid);
    assert.strictEqual(malformed.providerAccessGranted, false);
    assert.strictEqual(malformed.providerAccessGrantedTo, null);
    assert.strictEqual(malformed.providerAccessGrantedAt, null);
    for (const pedidoId of ['cancelled-valid-marker', 'pending-valid-marker']) {
      const lifecycleUnsafe = (await db.collection('pedidos').doc(pedidoId).get()).data();
      assert.strictEqual(lifecycleUnsafe.prestadorId, targetUid);
      assert.strictEqual(lifecycleUnsafe.providerAccessGranted, false);
      assert.strictEqual(lifecycleUnsafe.providerAccessGrantedTo, null);
      assert.strictEqual(lifecycleUnsafe.providerAccessGrantedAt, null);
    }
    const selfDealing = (
      await db.collection('pedidos').doc('merge-self-dealing').get()
    ).data();
    assert.strictEqual(selfDealing.clienteId, targetUid);
    assert.strictEqual(selfDealing.prestadorId, targetUid);
    assert.strictEqual(selfDealing.providerAccessGranted, false);
    assert.strictEqual(selfDealing.providerAccessGrantedTo, null);
    assert.strictEqual(selfDealing.providerAccessGrantedAt, null);
    const clientSelfDealing = (
      await db.collection('pedidos').doc('client-merge-self-dealing').get()
    ).data();
    assert.strictEqual(clientSelfDealing.clienteId, targetUid);
    assert.strictEqual(clientSelfDealing.prestadorId, targetUid);
    assert.strictEqual(clientSelfDealing.providerAccessGranted, false);
    assert.strictEqual(clientSelfDealing.providerAccessGrantedTo, null);
    assert.strictEqual(clientSelfDealing.providerAccessGrantedAt, null);
    const legacyClientAlias = (
      await db.collection('pedidos').doc('legacy-client-alias').get()
    ).data();
    assert.strictEqual(legacyClientAlias.clientId, targetUid);
    assert.strictEqual(legacyClientAlias.prestadorId, targetUid);
    assert.strictEqual(legacyClientAlias.providerAccessGranted, false);
    assert.strictEqual(legacyClientAlias.providerAccessGrantedTo, null);
    assert.strictEqual(legacyClientAlias.providerAccessGrantedAt, null);
    const divergentAliases = (
      await db.collection('pedidos').doc('divergent-client-aliases').get()
    ).data();
    assert.strictEqual(divergentAliases.clienteId, targetUid);
    assert.strictEqual(divergentAliases.clientId, 'different-client');
    assert.strictEqual(divergentAliases.prestadorId, targetUid);
    assert.strictEqual(divergentAliases.providerAccessGranted, false);
    assert.strictEqual(divergentAliases.providerAccessGrantedTo, null);
    assert.strictEqual(divergentAliases.providerAccessGrantedAt, null);
    assert.strictEqual(
      (await db.collection('chats').doc('accepted-valid').get()).data().prestadorId,
      targetUid,
    );
    assert.strictEqual(
      (
        await db.collection('users_private').doc(targetUid)
          .collection('favorites').doc('provider-favorite').get()
      ).data().providerId,
      'provider-favorite',
    );

    const tombstone = (
      await db.collection('account_merge_sources').doc(sourceUid).get()
    );
    assert.strictEqual(tombstone.exists, true);
    assert.strictEqual(tombstone.data().sourceUid, sourceUid);
    assert.strictEqual(tombstone.data().targetUid, targetUid);
    assert.strictEqual(tombstone.data().rekeyCompleted, true);

    for (const collection of [
      'users_private',
      'public_profiles',
      'provider_public',
      'provider_private',
      'provider_dispatch_private',
      'users',
      'prestadores',
    ]) {
      assert.strictEqual(
        (await db.collection(collection).doc(sourceUid).get()).exists,
        false,
        `${collection}/${sourceUid} must be removed`,
      );
      assert.strictEqual(
        (await db.collection(collection).doc(targetUid).get()).exists,
        true,
        `${collection}/${targetUid} must exist`,
      );
    }
    assert.strictEqual(
      (
        await db.collection('users_private').doc(sourceUid)
          .collection('favorites').doc('provider-favorite').get()
      ).exists,
      false,
    );
    assert.deepStrictEqual(updateUserCalls, [{
      uid: sourceUid,
      patch: { disabled: true },
    }]);
    assert.deepStrictEqual(authEvents[authEvents.length - 1], {
      type: 'updateUser',
      uid: sourceUid,
      patch: { disabled: true },
    });
  });

  it('resumes safely from the tombstone after a late Auth disable failure', async () => {
    const grantedAt = Timestamp.now();
    await Promise.all([
      db.collection('users_private').doc(sourceUid).set({
        uid: sourceUid,
        isAnonymous: true,
      }),
      db.collection('users_private').doc(targetUid).set({
        uid: targetUid,
        isAnonymous: false,
      }),
      db.collection('users_private').doc(sourceUid)
        .collection('favorites').doc('provider-favorite').set({
          providerId: 'provider-favorite',
        }),
      db.collection('pedidos').doc('retry-grant').set({
        clienteId: 'client-retry',
        prestadorId: sourceUid,
        providerAccessGranted: true,
        providerAccessGrantedTo: sourceUid,
        providerAccessGrantedAt: grantedAt,
        status: 'aceito',
        estado: 'aceito',
      }),
    ]);

    let disableAttempts = 0;
    const retryAuthAdmin = {
      getUser: authAdmin.getUser,
      verifyIdToken: authAdmin.verifyIdToken,
      updateUser: async (uid, patch) => {
        disableAttempts += 1;
        assert.strictEqual(uid, sourceUid);
        assert.deepStrictEqual(patch, { disabled: true });
        if (disableAttempts === 1) throw new Error('late-auth-disable-failure');
        return { uid, disabled: true };
      },
    };

    await assert.rejects(
      () => __test__.auth.mergeAnonymousDataCore({
        database: db,
        auth: { uid: targetUid },
        sourceIdToken: 'anonymous-source-token',
        authAdmin: retryAuthAdmin,
      }),
      /late-auth-disable-failure/,
    );
    assert.strictEqual(
      (await db.collection('account_merge_sources').doc(sourceUid).get()).exists,
      true,
    );
    assert.strictEqual(
      (await db.collection('users_private').doc(sourceUid).get()).exists,
      false,
    );

    const retryResult = await __test__.auth.mergeAnonymousDataCore({
      database: db,
      auth: { uid: targetUid },
      sourceIdToken: 'anonymous-source-token',
      authAdmin: retryAuthAdmin,
    });
    assert.strictEqual(retryResult.ok, true);
    assert.strictEqual(retryResult.idempotent, true);
    assert.strictEqual(disableAttempts, 2);
    const migrated = (await db.collection('pedidos').doc('retry-grant').get()).data();
    assert.strictEqual(migrated.prestadorId, targetUid);
    assert.strictEqual(migrated.providerAccessGranted, true);
    assert.strictEqual(migrated.providerAccessGrantedTo, targetUid);
  });

  it('rejects a competing phone account before any source data is moved', async () => {
    const competingTargetUid = 'different-phone-provider';
    await Promise.all([
      db.collection('users_private').doc(sourceUid).set({
        uid: sourceUid,
        isAnonymous: true,
        retainedValue: 'source-must-remain',
      }),
      db.collection('account_merge_sources').doc(sourceUid).set({
        sourceUid,
        targetUid,
        mergeVersion: 'anonymous-data-v3',
        status: 'in_progress',
        rekeyCompleted: false,
      }),
    ]);

    await assert.rejects(
      () => __test__.auth.mergeAnonymousDataCore({
        database: db,
        auth: { uid: competingTargetUid },
        sourceIdToken: 'anonymous-source-token',
        authAdmin,
      }),
      (error) => error && error.code === 'already-exists',
    );

    const source = await db.collection('users_private').doc(sourceUid).get();
    const lock = await db.collection('account_merge_sources').doc(sourceUid).get();
    assert.strictEqual(source.exists, true);
    assert.strictEqual(source.data().retainedValue, 'source-must-remain');
    assert.strictEqual(lock.data().targetUid, targetUid);
    assert.strictEqual(
      (await db.collection('users_private').doc(competingTargetUid).get()).exists,
      false,
    );
    assert.deepStrictEqual(updateUserCalls, []);
  });

  it('resumes from a completed tombstone when disable succeeded but its response was lost', async () => {
    await Promise.all([
      db.collection('users_private').doc(sourceUid).set({
        uid: sourceUid,
        isAnonymous: true,
      }),
      db.collection('users_private').doc(targetUid).set({
        uid: targetUid,
        isAnonymous: false,
      }),
    ]);
    let sourceDisabled = false;
    let disableAttempts = 0;
    const responseLostAuthAdmin = {
      getUser: authAdmin.getUser,
      verifyIdToken: async (_token, checkRevoked) => {
        if (checkRevoked === true && sourceDisabled) {
          const error = new Error('anonymous source is disabled');
          error.code = 'auth/user-disabled';
          throw error;
        }
        return {
          uid: sourceUid,
          firebase: { sign_in_provider: 'anonymous' },
        };
      },
      updateUser: async (uid, patch) => {
        disableAttempts += 1;
        assert.strictEqual(uid, sourceUid);
        assert.deepStrictEqual(patch, { disabled: true });
        sourceDisabled = true;
        if (disableAttempts === 1) throw new Error('disable-response-lost');
        return { uid, disabled: true };
      },
    };

    await assert.rejects(
      () => __test__.auth.mergeAnonymousDataCore({
        database: db,
        auth: { uid: targetUid },
        sourceIdToken: 'anonymous-source-token',
        authAdmin: responseLostAuthAdmin,
      }),
      /disable-response-lost/,
    );
    const completed = await db.collection('account_merge_sources').doc(sourceUid).get();
    assert.strictEqual(completed.data().status, 'complete');
    assert.strictEqual(completed.data().rekeyCompleted, true);

    const retry = await __test__.auth.mergeAnonymousDataCore({
      database: db,
      auth: { uid: targetUid },
      sourceIdToken: 'anonymous-source-token',
      authAdmin: responseLostAuthAdmin,
    });
    assert.strictEqual(retry.ok, true);
    assert.strictEqual(retry.idempotent, true);
    assert.strictEqual(disableAttempts, 2);
  });
});
