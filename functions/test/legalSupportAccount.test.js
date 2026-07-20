const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('legal consent, support and account deletion', () => {
  const db = __test__.getDb();
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
  ];

  beforeEach(async () => {
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
        version: __test__.legal.LEGAL_DOCUMENT_VERSION,
        locale: 'pt_MZ',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      },
    });
    const privateUser = (await db.collection('users_private').doc(phoneAuth.uid).get()).data();
    assert.strictEqual(privateUser.legalConsent.version, __test__.legal.LEGAL_DOCUMENT_VERSION);
    assert.strictEqual(privateUser.legalConsent.termsAccepted, true);
    assert.strictEqual(privateUser.legalConsent.privacyAccepted, true);
    assert.strictEqual(privateUser.legalConsent.ageConfirmed, true);
    const audits = await db.collection('legal_consent_audit').where('uid', '==', phoneAuth.uid).get();
    assert.strictEqual(audits.size, 1);
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
    assert.strictEqual(ticket.status, 'open');
    assert.strictEqual(ticket.subject, 'Conta e acesso');
    assert.strictEqual(ticket.source, 'callable');
  });

  it('hides public data, schedules seven days, and restores state on cancellation', async () => {
    await __test__.legal.acceptLegalDocumentsCore({
      database: db,
      auth: phoneAuth,
      data: {
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
    assert.strictEqual((await db.collection('users_private').doc(phoneAuth.uid).get()).exists, false);
    assert.strictEqual((await db.collection('chats').doc('private-chat').get()).exists, false);
    assert.strictEqual((await db.collection('support_tickets').doc('private-ticket').get()).exists, false);
    assert.strictEqual(
      (await db.collection('account_deletion_requests').doc(phoneAuth.uid).get()).exists,
      false,
    );
  });

  it('recognizes terminal and active order states', () => {
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({ status: 'concluido' }), false);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({ estado: 'cancelado' }), false);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({ status: 'aceito' }), true);
    assert.strictEqual(__test__.accounts.isActiveAccountOrder({}), true);
  });
});
