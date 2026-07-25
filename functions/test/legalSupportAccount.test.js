const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('legal consent, support and account deletion', () => {
  const db = __test__.getDb();
  const originalMarketId = process.env.PILOT_MARKET_ID;
  const originalCurrency = process.env.DEFAULT_CURRENCY_CODE;
  const phoneAuth = { uid: 'legal-user', token: { phone_number: '+258840000001' } };
  const anonymousAuth = { uid: 'support-user', token: {} };
  const collections = [
    'users_private',
    'legal_consent_audit',
    'support_tickets',
    'account_deletion_requests',
    'provider_public',
    'provider_dispatch_private',
    'public_profiles',
    'pedidos',
    'pilot_participants',
    'provider_opportunities',
    'provider_acceptance_limits',
    'account_merge_sources',
    'account_merge_audit',
    'account_deletion_audit',
    'adminAuditLogs',
    'security_event_logs',
    'handles',
    'stories',
    'pedido_dispatch',
    'reports',
    'service_moderation_queue',
  ];

  beforeEach(async () => {
    process.env.PILOT_MARKET_ID = 'mz-maputo';
    process.env.DEFAULT_CURRENCY_CODE = 'MZN';
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  it('records both legal consents with an immutable server-side version', async () => {
    await assert.rejects(
      () => __test__.legal.acceptLegalDocumentsCore({
        database: db,
        auth: phoneAuth,
        data: {
          marketId: 'mz-maputo',
          version: 'stale',
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: true,
        },
      }),
      (error) => error.code === 'failed-precondition',
    );

    await assert.rejects(
      () => __test__.legal.acceptLegalDocumentsCore({
        database: db,
        auth: phoneAuth,
        data: {
          marketId: 'mz-maputo',
          version: __test__.legal.LEGAL_DOCUMENT_VERSION,
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: false,
        },
      }),
      (error) => error.code === 'invalid-argument',
    );

    await __test__.legal.acceptLegalDocumentsCore({
      database: db,
      auth: phoneAuth,
      data: {
        marketId: 'mz-maputo',
        version: __test__.legal.LEGAL_DOCUMENT_VERSION,
        locale: 'pt_MZ',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      },
    });
    const privateUser = (await db.collection('users_private').doc(phoneAuth.uid).get()).data();
    assert.strictEqual(privateUser.legalConsent.version, __test__.legal.LEGAL_DOCUMENT_VERSION);
    assert.strictEqual(privateUser.legalConsent.marketId, 'mz-maputo');
    assert.strictEqual(privateUser.legalConsent.termsAccepted, true);
    assert.strictEqual(privateUser.legalConsent.privacyAccepted, true);
    assert.strictEqual(privateUser.legalConsent.ageConfirmed, true);
    const audits = await db.collection('legal_consent_audit').where('uid', '==', phoneAuth.uid).get();
    assert.strictEqual(audits.size, 1);
    assert.strictEqual(audits.docs[0].data().marketId, 'mz-maputo');
  });

  it('stamps the active market on provider records after phone confirmation', async () => {
    await Promise.all([
      db.collection('pilot_participants').doc(phoneAuth.uid).set({
        marketId: 'mz-maputo',
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
      }),
      db.collection('provider_public').doc(phoneAuth.uid).set({
        uid: phoneAuth.uid,
        isSearchable: false,
      }),
      db.collection('provider_dispatch_private').doc(phoneAuth.uid).set({
        providerId: phoneAuth.uid,
        isOnline: false,
      }),
    ]);

    await __test__.auth.syncPhoneIdentityCore({
      database: db,
      auth: phoneAuth,
      authAdmin: {
        getUser: async () => ({
          uid: phoneAuth.uid,
          phoneNumber: '+258840000001',
        }),
      },
    });

    const provider = (
      await db.collection('provider_public').doc(phoneAuth.uid).get()
    ).data();
    const dispatch = (
      await db.collection('provider_dispatch_private').doc(phoneAuth.uid).get()
    ).data();
    assert.strictEqual(provider.marketId, 'mz-maputo');
    assert.strictEqual(provider.countryCode, 'MZ');
    assert.strictEqual(provider.currency, 'MZN');
    assert.strictEqual(dispatch.marketId, 'mz-maputo');
    assert.strictEqual(dispatch.currency, 'MZN');
  });

  it('fails closed when legal documents are unavailable for the active market', async () => {
    process.env.PILOT_MARKET_ID = 'pt-coimbra';
    process.env.DEFAULT_CURRENCY_CODE = 'EUR';
    assert.strictEqual(__test__.legal.legalDocumentsAvailableForMarket(), false);
    await assert.rejects(
      () => __test__.legal.acceptLegalDocumentsCore({
        database: db,
        auth: { uid: phoneAuth.uid, token: { phone_number: '+351910000001' } },
        data: {
          marketId: 'pt-coimbra',
          version: __test__.legal.LEGAL_DOCUMENT_VERSION,
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: true,
        },
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.throws(
      () => __test__.legal.assertCurrentLegalConsent({
        marketId: 'mz-maputo',
        version: __test__.legal.LEGAL_DOCUMENT_VERSION,
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('requires a market on new consent and limits missing-market compatibility to Maputo', async () => {
    await assert.rejects(
      () => __test__.legal.acceptLegalDocumentsCore({
        database: db,
        auth: phoneAuth,
        data: {
          version: __test__.legal.LEGAL_DOCUMENT_VERSION,
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: true,
        },
      }),
      (error) => error.code === 'invalid-argument',
    );
    const legacyConsent = {
      version: __test__.legal.LEGAL_DOCUMENT_VERSION,
      termsAccepted: true,
      privacyAccepted: true,
      ageConfirmed: true,
    };
    assert.strictEqual(__test__.legal.assertCurrentLegalConsent(legacyConsent), legacyConsent);
    assert.throws(
      () => __test__.legal.assertCurrentLegalConsent({
        ...legacyConsent,
        marketId: 'pt-coimbra',
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('creates support state only from authoritative values and keeps support accessible', async () => {
    const result = await __test__.support.createSupportTicketCore({
      database: db,
      auth: anonymousAuth,
      data: {
        category: 'account',
        message: 'Preciso de ajuda para recuperar o acesso a minha conta.',
        userType: 'cliente',
        status: 'resolved',
        uid: 'forged-user',
      },
    });
    const ticket = (await db.collection('support_tickets').doc(result.ticketId).get()).data();
    assert.strictEqual(ticket.uid, anonymousAuth.uid);
    assert.strictEqual(ticket.marketId, 'mz-maputo');
    assert.strictEqual(ticket.status, 'open');
    assert.strictEqual(ticket.subject, 'Conta e acesso');
    assert.strictEqual(ticket.source, 'callable');
  });

  it('hides public data, schedules seven days, and restores state on cancellation', async () => {
    await __test__.legal.acceptLegalDocumentsCore({
      database: db,
      auth: phoneAuth,
      data: {
        marketId: 'mz-maputo',
        version: __test__.legal.LEGAL_DOCUMENT_VERSION,
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      },
    });
    await Promise.all([
      db.collection('provider_public').doc(phoneAuth.uid).set({ isSearchable: true, nome: 'Profissional' }),
      db.collection('provider_dispatch_private').doc(phoneAuth.uid).set({ acceptingRequests: true, isOnline: true }),
      db.collection('public_profiles').doc(phoneAuth.uid).set({ displayName: 'Pessoa publica' }),
    ]);
    const before = Date.now();
    const result = await __test__.accounts.requestAccountDeletionCore({
      database: db,
      auth: phoneAuth,
      data: { confirmation: 'ELIMINAR' },
    });
    const expectedMs = __test__.accounts.ACCOUNT_DELETION_GRACE_DAYS * 24 * 60 * 60 * 1000;
    assert.ok(result.executeAtMillis >= before + expectedMs - 2000);
    assert.strictEqual((await db.collection('public_profiles').doc(phoneAuth.uid).get()).exists, false);
    assert.strictEqual(
      (await db.collection('provider_public').doc(phoneAuth.uid).get()).data().isSearchable,
      false,
    );
    assert.strictEqual(
      (await db.collection('provider_dispatch_private').doc(phoneAuth.uid).get()).data().acceptingRequests,
      false,
    );

    await __test__.accounts.cancelAccountDeletionCore({ database: db, auth: phoneAuth });
    assert.strictEqual(
      (await db.collection('account_deletion_requests').doc(phoneAuth.uid).get()).data().status,
      'cancelled',
    );
    assert.strictEqual(
      (await db.collection('provider_public').doc(phoneAuth.uid).get()).data().isSearchable,
      true,
    );
    assert.strictEqual(
      (await db.collection('public_profiles').doc(phoneAuth.uid).get()).data().displayName,
      'Pessoa publica',
    );
  });

  it('does not schedule deletion while the user has active work', async () => {
    await __test__.legal.acceptLegalDocumentsCore({
      database: db,
      auth: phoneAuth,
      data: {
        marketId: 'mz-maputo',
        version: __test__.legal.LEGAL_DOCUMENT_VERSION,
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      },
    });
    await db.collection('pedidos').doc('active-job').set({
      clienteId: phoneAuth.uid,
      prestadorId: 'provider-2',
      status: 'em_andamento',
    });
    await assert.rejects(
      () => __test__.accounts.requestAccountDeletionCore({
        database: db,
        auth: phoneAuth,
        data: { confirmation: 'ELIMINAR' },
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.strictEqual(
      (await db.collection('account_deletion_requests').doc(phoneAuth.uid).get()).exists,
      false,
    );
  });

  it('executes deletion by removing profiles and pseudonymizing retained transactions', async () => {
    await __test__.legal.acceptLegalDocumentsCore({
      database: db,
      auth: phoneAuth,
      data: {
        marketId: 'mz-maputo',
        version: __test__.legal.LEGAL_DOCUMENT_VERSION,
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      },
    });
    await db.collection('public_profiles').doc(phoneAuth.uid).set({ displayName: 'Eliminar' });
    await db.collection('pedidos').doc('finished-job').set({
      clienteId: phoneAuth.uid,
      prestadorId: 'provider-finished',
      status: 'concluido',
      morada: 'Rua que deve desaparecer',
    });
    await db.collection('pedidos').doc('finished-provider-job').set({
      clienteId: 'client-finished',
      prestadorId: phoneAuth.uid,
      providerAccessGranted: true,
      providerAccessGrantedTo: phoneAuth.uid,
      providerAccessGrantedAt: new Date(),
      status: 'concluido',
    });
    await db.collection('pedidos').doc('inconsistent-provider-grant').set({
      clienteId: 'client-finished',
      prestadorId: 'another-provider',
      providerAccessGranted: true,
      providerAccessGrantedTo: phoneAuth.uid,
      providerAccessGrantedAt: new Date(),
      status: 'concluido',
    });
    await db.collection('chats').doc('private-chat').set({
      clienteId: phoneAuth.uid,
      prestadorId: 'provider-finished',
    });
    await db.collection('support_tickets').doc('private-ticket').set({
      uid: phoneAuth.uid,
      status: 'resolved',
      message: 'Mensagem privada',
    });
    await __test__.accounts.requestAccountDeletionCore({
      database: db,
      auth: phoneAuth,
      data: { confirmation: 'ELIMINAR' },
    });
    await db.collection('account_deletion_requests').doc(phoneAuth.uid).update({
      executeAt: new Date(Date.now() - 1000),
    });

    const result = await __test__.accounts.executeAccountDeletionCore({
      database: db,
      uid: phoneAuth.uid,
      deleteStorage: false,
      deleteAuth: false,
    });
    assert.strictEqual(result.ok, true);
    assert.ok(result.pseudonym.startsWith('deleted:'));
    const retainedOrder = (await db.collection('pedidos').doc('finished-job').get()).data();
    assert.strictEqual(retainedOrder.clienteId, result.pseudonym);
    assert.strictEqual(Object.prototype.hasOwnProperty.call(retainedOrder, 'morada'), false);
    const retainedProviderOrder = (
      await db.collection('pedidos').doc('finished-provider-job').get()
    ).data();
    assert.strictEqual(retainedProviderOrder.prestadorId, result.pseudonym);
    assert.strictEqual(retainedProviderOrder.providerAccessGranted, false);
    assert.strictEqual(
      Object.prototype.hasOwnProperty.call(retainedProviderOrder, 'providerAccessGrantedTo'),
      false,
    );
    assert.strictEqual(
      Object.prototype.hasOwnProperty.call(retainedProviderOrder, 'providerAccessGrantedAt'),
      false,
    );
    const inconsistentGrant = (
      await db.collection('pedidos').doc('inconsistent-provider-grant').get()
    ).data();
    assert.strictEqual(inconsistentGrant.prestadorId, 'another-provider');
    assert.strictEqual(inconsistentGrant.providerAccessGranted, false);
    assert.strictEqual(
      Object.prototype.hasOwnProperty.call(inconsistentGrant, 'providerAccessGrantedTo'),
      false,
    );
    assert.strictEqual(
      Object.prototype.hasOwnProperty.call(inconsistentGrant, 'providerAccessGrantedAt'),
      false,
    );
    assert.strictEqual((await db.collection('users_private').doc(phoneAuth.uid).get()).exists, false);
    assert.strictEqual((await db.collection('chats').doc('private-chat').get()).exists, false);
    assert.strictEqual((await db.collection('support_tickets').doc('private-ticket').get()).exists, false);
    assert.strictEqual(
      (await db.collection('account_deletion_requests').doc(phoneAuth.uid).get()).exists,
      false,
    );
  });

  after(() => {
    if (originalMarketId === undefined) delete process.env.PILOT_MARKET_ID;
    else process.env.PILOT_MARKET_ID = originalMarketId;
    if (originalCurrency === undefined) delete process.env.DEFAULT_CURRENCY_CODE;
    else process.env.DEFAULT_CURRENCY_CODE = originalCurrency;
  });

  it('resumes an interrupted executing deletion and removes every owned storage prefix before Auth', async () => {
    const uid = phoneAuth.uid;
    await Promise.all([
      db.collection('users_private').doc(uid).set({ accountStatus: 'deletion_pending' }),
      db.collection('account_deletion_requests').doc(uid).set({
        uid,
        status: 'pending',
        executeAt: new Date(Date.now() - 1000),
      }),
      db.collection('pilot_participants').doc(uid).set({ uid, status: 'inactive' }),
      db.collection('provider_opportunities').doc(`pedido_${uid}`).set({
        providerId: uid,
        pedidoId: 'pedido',
      }),
      db.collection('provider_acceptance_limits').doc(`${uid}_window`).set({
        providerId: uid,
        count: 1,
      }),
      db.collection('account_merge_sources').doc('anonymous-source').set({
        sourceUid: 'anonymous-source',
        targetUid: uid,
        status: 'complete',
      }),
      db.collection('account_merge_audit').doc('merge-audit').set({
        sourceUid: 'anonymous-source',
        targetUid: uid,
        note: `merged-into:${uid}`,
      }),
      db.collection('legal_consent_audit').doc('legal-audit').set({
        uid,
        version: __test__.legal.LEGAL_DOCUMENT_VERSION,
      }),
      db.collection('adminAuditLogs').doc('admin-audit').set({
        actorUid: 'admin',
        targetId: `${uid}_category`,
        metadata: { providerId: uid },
      }),
      db.collection('security_event_logs').doc('security-audit').set({
        actorUid: uid,
        targetId: uid,
        action: 'kyc.submitted',
      }),
      db.collection('handles').doc('old-handle').set({ uid, previousOwnerUid: uid }),
      db.collection('stories').doc('old-story').set({ prestadorId: uid }),
      db.collection('pedido_dispatch').doc('targeted-dispatch').set({ targetPrestadorId: uid }),
      db.collection('reports').doc('retained-report').set({
        reporterId: uid,
        targetOwnerId: uid,
        details: `report-by:${uid}`,
      }),
      db.collection('service_moderation_queue').doc('old-moderation').set({ requesterId: uid }),
      db.collection('provider_dispatch_private').doc('other-provider').set({
        activeClientIds: ['someone-else', uid],
      }),
    ]);

    const events = [];
    let failOnce = true;
    const bucket = {
      async deleteFiles({ prefix }) {
        events.push(`storage:${prefix}`);
        if (failOnce && prefix === `prestadores/${uid}/`) {
          failOnce = false;
          throw new Error('injected-storage-failure');
        }
      },
    };
    const authAdmin = {
      async deleteUser(deletedUid) {
        events.push(`auth:${deletedUid}`);
      },
    };

    await assert.rejects(
      () => __test__.accounts.executeAccountDeletionCore({
        database: db,
        uid,
        bucket,
        authAdmin,
      }),
      /injected-storage-failure/,
    );
    const interrupted = (
      await db.collection('account_deletion_requests').doc(uid).get()
    ).data();
    assert.strictEqual(interrupted.status, 'executing');
    assert.strictEqual(interrupted.attempt, 1);
    assert.ok(interrupted.lastAttemptAt);
    assert.match(interrupted.lastError, /injected-storage-failure/);
    assert.strictEqual(events.some((event) => event.startsWith('auth:')), false);

    const result = await __test__.accounts.executeAccountDeletionCore({
      database: db,
      uid,
      bucket,
      authAdmin,
    });
    assert.strictEqual(result.ok, true);

    const storageRoots = [
      'users',
      'prestadores',
      'kyc_pending',
      'profile_public',
      'portfolio',
      'stories',
      'temp',
      'kyc',
      'category_evidence',
    ];
    const expectedPrefixes = storageRoots.map((prefix) => `${prefix}/${uid}/`);
    const mergedSourcePrefixes = storageRoots
      .map((prefix) => `${prefix}/anonymous-source/`);
    for (const prefix of expectedPrefixes) {
      assert.ok(events.includes(`storage:${prefix}`), `missing storage cleanup for ${prefix}`);
    }
    for (const prefix of mergedSourcePrefixes) {
      assert.ok(events.includes(`storage:${prefix}`), `missing merged-source cleanup for ${prefix}`);
    }
    const firstAuthIndex = events.findIndex((event) => event.startsWith('auth:'));
    assert.ok(firstAuthIndex > -1);
    assert.ok([...expectedPrefixes, ...mergedSourcePrefixes].every(
      (prefix) => events.lastIndexOf(`storage:${prefix}`) < firstAuthIndex,
    ));
    assert.ok(events.includes('auth:anonymous-source'));
    assert.ok(events.includes(`auth:${uid}`));

    assert.strictEqual((await db.collection('pilot_participants').doc(uid).get()).exists, false);
    assert.strictEqual(
      (await db.collection('provider_opportunities').where('providerId', '==', uid).get()).empty,
      true,
    );
    assert.strictEqual(
      (await db.collection('provider_acceptance_limits').where('providerId', '==', uid).get()).empty,
      true,
    );
    assert.strictEqual(
      (await db.collection('account_merge_sources').where('targetUid', '==', uid).get()).empty,
      true,
    );
    assert.strictEqual((await db.collection('handles').doc('old-handle').get()).exists, false);
    assert.strictEqual((await db.collection('stories').doc('old-story').get()).exists, false);
    assert.strictEqual(
      (await db.collection('pedido_dispatch').doc('targeted-dispatch').get()).exists,
      false,
    );
    assert.strictEqual(
      (await db.collection('service_moderation_queue').doc('old-moderation').get()).exists,
      false,
    );
    assert.deepStrictEqual(
      (await db.collection('provider_dispatch_private').doc('other-provider').get())
        .data().activeClientIds,
      ['someone-else'],
    );
    for (const [collection, id] of [
      ['account_merge_audit', 'merge-audit'],
      ['legal_consent_audit', 'legal-audit'],
      ['adminAuditLogs', 'admin-audit'],
      ['security_event_logs', 'security-audit'],
      ['reports', 'retained-report'],
    ]) {
      const audit = (await db.collection(collection).doc(id).get()).data();
      assert.ok(audit, `${collection}/${id} must be retained`);
      assert.strictEqual(JSON.stringify(audit).includes(uid), false);
      assert.strictEqual(JSON.stringify(audit).includes('anonymous-source'), false);
      assert.ok(JSON.stringify(audit).includes(result.pseudonym));
    }
  });

  it('blocks new public activity while account deletion is pending', async () => {
    await db.collection('users_private').doc(phoneAuth.uid).set({
      accountStatus: 'deletion_pending',
    });
    await assert.rejects(
      () => __test__.auth.syncPhoneIdentityCore({
        database: db,
        auth: phoneAuth,
        authAdmin: {
          getUser: async () => ({ uid: phoneAuth.uid, phoneNumber: '+258840000001' }),
        },
      }),
      (error) => error.code === 'failed-precondition',
    );
    await assert.rejects(
      () => __test__.pedidos.createSecurePedidoCore({
        database: db,
        auth: phoneAuth,
        data: { servicoId: 'cleaning' },
      }),
      (error) => error.code === 'failed-precondition',
    );
    await assert.rejects(
      () => __test__.providers.updateProviderServicesCore({
        database: db,
        auth: phoneAuth,
        data: { serviceIds: ['cleaning'] },
      }),
      (error) => error.code === 'failed-precondition',
    );
    await assert.rejects(
      () => __test__.privateStorage.finalizePrivateStorageUploadCore({
        database: db,
        auth: phoneAuth,
        storage: { bucket: () => { throw new Error('must not reach storage'); } },
        data: { path: `temp/${phoneAuth.uid}/anexos/new.jpg` },
      }),
      (error) => error.code === 'failed-precondition',
    );
    await assert.rejects(
      () => __test__.handles.handleReserveProviderHandleCore({
        database: db,
        auth: phoneAuth,
        data: { handle: 'pending-delete' },
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('recognizes terminal and active order states', () => {
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({ status: 'concluido' }), false);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({ estado: 'cancelado' }), false);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({ status: 'aceito' }), true);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({
      status: 'concluido', estado: 'aceito',
    }), true);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({
      status: 'concluido', estado: 'cancelado',
    }), true);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({}), true);
  });
});
