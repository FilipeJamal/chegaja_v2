const assert = require('assert');

const {
  AUDIT_COLLECTION,
  MIGRATION_VERSION,
  POST_ACCEPT_STATES,
  acceptedQuoteRangeIsValid,
  auditDocumentId,
  buildReconciliationEvidence,
  buildMigrationPlan,
  classifyProviderAccessGrant,
  commitWrites,
  decodeFirestoreFields,
  readPedidos,
  resolveOptions,
} = require('../admin/migrate_provider_access_grants');

const timestamp = new Date('2026-07-20T12:00:00.000Z');

assert.throws(() => resolveOptions([]), /--project is required/);
assert.throws(
  () => resolveOptions(['--project=test-project', '--confirm']),
  /confirm-project/,
);
assert.throws(
  () => resolveOptions(['--project=test-project', '--confirm-project=test-project']),
  /only valid together/,
);
assert.throws(
  () => resolveOptions(['--project=test-project', '--limit=0']),
  /positive integer/,
);
assert.throws(
  () => resolveOptions([
    '--project=test-project',
    '--confirm',
    '--confirm-project=test-project',
    '--limit=10',
  ]),
  /forbidden with --confirm/,
);
const dryRun = resolveOptions(['--project=test-project']);
assert.strictEqual(dryRun.dryRun, true);
const confirmed = resolveOptions([
  '--project=test-project',
  '--confirm',
  '--confirm-project=test-project',
]);
assert.strictEqual(confirmed.dryRun, false);

for (const state of POST_ACCEPT_STATES) {
  const result = classifyProviderAccessGrant({
    status: state,
    clienteId: 'client-1',
    prestadorId: 'provider-1',
    updatedAt: timestamp,
  });
  assert.strictEqual(result.action, 'backfill', state);
  assert.strictEqual(result.patch.providerAccessGranted, true);
  assert.strictEqual(result.patch.providerAccessGrantedTo, 'provider-1');
  assert.strictEqual(result.patch.providerAccessGrantedAt.getTime(), timestamp.getTime());
}

const derivedFromAcceptance = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-1',
  prestadorId: 'provider-1',
  acceptedAt: new Date('2026-07-19T11:00:00.000Z'),
  updatedAt: timestamp,
});
assert.strictEqual(derivedFromAcceptance.reason, 'derived_from_acceptedAt');

const legacyWithoutGrantMarkerFields = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-legacy',
  prestadorId: 'provider-legacy',
  updatedAt: timestamp,
});
assert.strictEqual(legacyWithoutGrantMarkerFields.action, 'backfill');

for (const [description, clientFields] of [
  ['missing client', {}],
  ['blank clienteId', { clienteId: '   ' }],
  ['blank clientId', { clientId: '\t' }],
]) {
  const missingCanonicalClient = classifyProviderAccessGrant({
    status: 'aceito',
    prestadorId: 'provider-client-check',
    updatedAt: timestamp,
    ...clientFields,
  });
  assert.strictEqual(missingCanonicalClient.action, 'quarantine', description);
  assert.strictEqual(
    missingCanonicalClient.reason,
    'post_accept_without_client',
    description,
  );
}

const matchingClientAliases = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: ' client-alias ',
  clientId: 'client-alias',
  prestadorId: 'provider-alias',
  updatedAt: timestamp,
});
assert.strictEqual(matchingClientAliases.action, 'backfill');

for (const unsafeModerationStatus of [
  null,
  '',
  'pending_review',
  'rejected',
  'blocked',
  'legacy_unknown',
  'APPROVED',
]) {
  const unsafeLegacyModeration = classifyProviderAccessGrant({
    status: 'aceito',
    clienteId: 'client-moderation',
    prestadorId: 'provider-moderation',
    moderationStatus: unsafeModerationStatus,
    updatedAt: timestamp,
  });
  assert.strictEqual(unsafeLegacyModeration.action, 'quarantine');
  assert.strictEqual(
    unsafeLegacyModeration.reason,
    'post_accept_moderation_not_approved',
  );

  const unsafeExistingModeration = classifyProviderAccessGrant({
    status: 'aceito',
    clienteId: 'client-moderation',
    prestadorId: 'provider-moderation',
    moderationStatus: unsafeModerationStatus,
    providerAccessGranted: true,
    providerAccessGrantedTo: 'provider-moderation',
    providerAccessGrantedAt: timestamp,
  });
  assert.strictEqual(unsafeExistingModeration.action, 'quarantine');
  assert.strictEqual(
    unsafeExistingModeration.reason,
    'post_accept_moderation_not_approved',
  );
}

const approvedLegacyModeration = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-moderation',
  prestadorId: 'provider-moderation',
  moderationStatus: 'approved',
  updatedAt: timestamp,
});
assert.strictEqual(approvedLegacyModeration.action, 'backfill');

const approvedExistingModeration = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-moderation',
  prestadorId: 'provider-moderation',
  moderationStatus: 'approved',
  providerAccessGranted: true,
  providerAccessGrantedTo: 'provider-moderation',
  providerAccessGrantedAt: timestamp,
});
assert.strictEqual(approvedExistingModeration.action, 'keep');

const explicitlyRevokedPostAccept = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-revoked',
  prestadorId: 'provider-revoked',
  providerAccessGranted: false,
  providerAccessGrantedTo: null,
  providerAccessGrantedAt: null,
  updatedAt: timestamp,
});
assert.strictEqual(explicitlyRevokedPostAccept.action, 'quarantine');
assert.strictEqual(
  explicitlyRevokedPostAccept.reason,
  'inconsistent_existing_grant',
);
assert.strictEqual(explicitlyRevokedPostAccept.inconsistentGrant, true);

const revokedAfterQuarantine = classifyProviderAccessGrant({
  ...explicitlyRevokedPostAccept.patch,
  status: 'aceito',
  clienteId: 'client-revoked',
  prestadorId: 'provider-revoked',
  updatedAt: timestamp,
});
assert.strictEqual(revokedAfterQuarantine.action, 'quarantine');
assert.strictEqual(revokedAfterQuarantine.reason, 'inconsistent_existing_grant');

const validExisting = classifyProviderAccessGrant({
  status: 'em_andamento',
  estado: 'em_andamento',
  clienteId: 'client-1',
  prestadorId: 'provider-1',
  providerAccessGranted: true,
  providerAccessGrantedTo: 'provider-1',
  providerAccessGrantedAt: timestamp,
});
assert.strictEqual(validExisting.action, 'keep');
assert.strictEqual(validExisting.patch, null);

const validExistingTimestampObject = classifyProviderAccessGrant({
  status: 'em_andamento',
  clienteId: 'client-1',
  prestadorId: 'provider-1',
  providerAccessGranted: true,
  providerAccessGrantedTo: 'provider-1',
  providerAccessGrantedAt: {
    toMillis: () => timestamp.getTime(),
    toDate: () => timestamp,
  },
});
assert.strictEqual(validExistingTimestampObject.action, 'keep');

for (const [description, malformedTimestamp] of [
  ['ISO string', timestamp.toISOString()],
  ['millisecond number', timestamp.getTime()],
  ['seconds map', { seconds: timestamp.getTime() / 1000, nanoseconds: 0 }],
]) {
  const malformedExisting = classifyProviderAccessGrant({
    status: 'em_andamento',
    clienteId: 'client-1',
    prestadorId: 'provider-1',
    providerAccessGranted: true,
    providerAccessGrantedTo: 'provider-1',
    providerAccessGrantedAt: malformedTimestamp,
    updatedAt: timestamp,
  });
  assert.strictEqual(malformedExisting.action, 'quarantine', description);
  assert.strictEqual(
    malformedExisting.reason,
    'inconsistent_existing_grant',
    description,
  );
  assert.strictEqual(malformedExisting.inconsistentGrant, true, description);
}

const invite = classifyProviderAccessGrant({
  status: 'aguarda_resposta_prestador',
  prestadorId: 'provider-1',
  updatedAt: timestamp,
});
assert.strictEqual(invite.action, 'unchanged');

const inviteWithGrant = classifyProviderAccessGrant({
  status: 'aguarda_resposta_prestador',
  prestadorId: 'provider-1',
  providerAccessGranted: true,
  providerAccessGrantedTo: 'provider-1',
  providerAccessGrantedAt: timestamp,
});
assert.strictEqual(inviteWithGrant.action, 'revoke');
assert.strictEqual(inviteWithGrant.inconsistentGrant, true);
assert.strictEqual(inviteWithGrant.patch.providerAccessGranted, false);

const pendingProposalInAcceptedState = classifyProviderAccessGrant({
  status: 'aceito',
  prestadorId: 'provider-1',
  statusProposta: 'pendente_cliente',
  updatedAt: timestamp,
});
assert.strictEqual(pendingProposalInAcceptedState.action, 'quarantine');
assert.strictEqual(
  pendingProposalInAcceptedState.reason,
  'post_accept_state_with_pending_relation',
);

const targetOnly = classifyProviderAccessGrant({
  status: 'aguarda_resposta_prestador',
  targetProviderId: 'provider-1',
  updatedAt: timestamp,
});
assert.strictEqual(targetOnly.action, 'unchanged');
assert.strictEqual(targetOnly.patch, null);

const missingProvider = classifyProviderAccessGrant({
  status: 'concluido',
  updatedAt: timestamp,
});
assert.strictEqual(missingProvider.action, 'quarantine');
assert.strictEqual(missingProvider.reason, 'post_accept_without_provider');

const missingTimestamp = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-1',
  prestadorId: 'provider-1',
  createdAt: timestamp,
});
assert.strictEqual(missingTimestamp.action, 'quarantine');
assert.strictEqual(missingTimestamp.reason, 'post_accept_without_positive_timestamp');

const partialGrant = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-1',
  prestadorId: 'provider-1',
  providerAccessGranted: true,
  providerAccessGrantedTo: 'different-provider',
  providerAccessGrantedAt: timestamp,
  updatedAt: timestamp,
});
assert.strictEqual(partialGrant.action, 'quarantine');
assert.strictEqual(partialGrant.reason, 'inconsistent_existing_grant');
assert.strictEqual(partialGrant.inconsistentGrant, true);

for (const [description, malformedTarget] of [
  ['empty string', ''],
  ['whitespace string', '   '],
  ['number', 123],
  ['map', { uid: 'provider-1' }],
  ['array', ['provider-1']],
]) {
  const malformedGrantTarget = classifyProviderAccessGrant({
    status: 'aceito',
    clienteId: 'client-1',
    prestadorId: 'provider-1',
    providerAccessGrantedTo: malformedTarget,
    updatedAt: timestamp,
  });
  assert.strictEqual(malformedGrantTarget.action, 'quarantine', description);
  assert.strictEqual(
    malformedGrantTarget.reason,
    'inconsistent_existing_grant',
    description,
  );
  assert.strictEqual(malformedGrantTarget.inconsistentGrant, true, description);
}

const providerConflict = classifyProviderAccessGrant({
  status: 'aceito',
  prestadorId: 'provider-1',
  targetProviderId: 'provider-2',
  updatedAt: timestamp,
});
assert.strictEqual(providerConflict.action, 'quarantine');
assert.strictEqual(providerConflict.reason, 'provider_target_conflict');

const stateConflict = classifyProviderAccessGrant({
  status: 'aceito',
  estado: 'aguarda_resposta_prestador',
  prestadorId: 'provider-1',
  updatedAt: timestamp,
});
assert.strictEqual(stateConflict.action, 'quarantine');
assert.strictEqual(stateConflict.reason, 'status_estado_conflict');

for (const invalidAliases of [
  { status: '', estado: 'aceito' },
  { status: null, estado: 'aceito' },
  { status: 7, estado: 'aceito' },
  { status: 'aceito', estado: '' },
  { status: 'aceito', estado: null },
  { status: 'aceito', estado: 7 },
]) {
  const invalidAlias = classifyProviderAccessGrant({
    ...invalidAliases,
    clienteId: 'client-invalid-alias',
    prestadorId: 'provider-invalid-alias',
    updatedAt: timestamp,
  });
  assert.strictEqual(invalidAlias.action, 'quarantine');
  assert.strictEqual(invalidAlias.reason, 'invalid_status_estado_alias');
}

const legacyPostAcceptWithoutCanonicalStatus = classifyProviderAccessGrant({
  estado: 'aceito',
  clienteId: 'client-legacy-status',
  prestadorId: 'provider-legacy-status',
  updatedAt: timestamp,
});
assert.strictEqual(legacyPostAcceptWithoutCanonicalStatus.action, 'quarantine');
assert.strictEqual(
  legacyPostAcceptWithoutCanonicalStatus.reason,
  'post_accept_without_canonical_status',
);

const selfDealing = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'same-user',
  prestadorId: 'same-user',
  updatedAt: timestamp,
});
assert.strictEqual(selfDealing.action, 'quarantine');
assert.strictEqual(selfDealing.reason, 'client_provider_self_dealing');

const conflictingClientAliases = classifyProviderAccessGrant({
  status: 'aceito',
  clienteId: 'client-primary',
  clientId: 'client-legacy',
  prestadorId: 'provider-1',
  updatedAt: timestamp,
});
assert.strictEqual(conflictingClientAliases.action, 'quarantine');
assert.strictEqual(conflictingClientAliases.reason, 'client_alias_conflict');

for (const clientAlias of ['clienteId', 'clientId']) {
  const aliasedSelfDealing = classifyProviderAccessGrant({
    status: 'aceito',
    clienteId: clientAlias === 'clienteId' ? 'same-user' : 'different-client',
    clientId: clientAlias === 'clientId' ? 'same-user' : '',
    prestadorId: 'same-user',
    updatedAt: timestamp,
  });
  assert.strictEqual(aliasedSelfDealing.action, 'quarantine', clientAlias);
  assert.strictEqual(
    aliasedSelfDealing.reason,
    'client_provider_self_dealing',
    clientAlias,
  );
}

for (const quoteShape of [
  { tipoPreco: 'por_orcamento' },
  { tipoPreco: 'orcamento' },
  { tipoPreco: 'por_proposta' },
  { modo: 'POR_PROPOSTA' },
  { modo: 'POR_ORCAMENTO' },
  { mode: 'ORCAMENTO' },
]) {
  for (const proposalStatus of [undefined, 'nenhuma', 'pendente_cliente', 'legacy_unknown']) {
    const unsafeQuote = classifyProviderAccessGrant({
      status: 'aceito',
      clienteId: 'client-quote',
      prestadorId: 'provider-quote',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider-quote',
      providerAccessGrantedAt: timestamp,
      ...quoteShape,
      ...(proposalStatus === undefined ? {} : { statusProposta: proposalStatus }),
    });
    assert.strictEqual(unsafeQuote.action, 'quarantine');
    assert.ok([
      'quote_without_client_acceptance',
      'post_accept_state_with_pending_relation',
    ].includes(unsafeQuote.reason));
  }

  const acceptedQuote = classifyProviderAccessGrant({
    status: 'aceito',
    clienteId: 'client-quote',
    prestadorId: 'provider-quote',
    providerAccessGranted: true,
    providerAccessGrantedTo: 'provider-quote',
    providerAccessGrantedAt: timestamp,
    statusProposta: 'aceita_cliente',
    valorMinEstimadoPrestador: 100,
    valorMaxEstimadoPrestador: 150,
    ...quoteShape,
  });
  assert.strictEqual(acceptedQuote.action, 'keep');

  const acceptedLegacyQuote = classifyProviderAccessGrant({
    status: 'aceito',
    clienteId: 'client-quote',
    prestadorId: 'provider-quote',
    statusProposta: 'aceita_cliente',
    valorMinEstimadoPrestador: 100,
    valorMaxEstimadoPrestador: 150,
    acceptedAt: timestamp,
    ...quoteShape,
  });
  assert.strictEqual(acceptedLegacyQuote.action, 'backfill');

  for (const [description, invalidRange] of [
    ['missing range', {}],
    ['zero minimum', {
      valorMinEstimadoPrestador: 0,
      valorMaxEstimadoPrestador: 100,
    }],
    ['negative minimum', {
      valorMinEstimadoPrestador: -1,
      valorMaxEstimadoPrestador: 100,
    }],
    ['zero maximum', {
      valorMinEstimadoPrestador: 10,
      valorMaxEstimadoPrestador: 0,
    }],
    ['maximum below minimum', {
      valorMinEstimadoPrestador: 101,
      valorMaxEstimadoPrestador: 100,
    }],
    ['non-finite minimum', {
      valorMinEstimadoPrestador: Number.POSITIVE_INFINITY,
      valorMaxEstimadoPrestador: 100,
    }],
    ['non-finite maximum', {
      valorMinEstimadoPrestador: 100,
      valorMaxEstimadoPrestador: Number.NaN,
    }],
    ['transient callable aliases only', {
      valorMin: 100,
      valorMax: 150,
    }],
  ]) {
    const invalidAcceptedQuote = classifyProviderAccessGrant({
      status: 'aceito',
      clienteId: 'client-quote',
      prestadorId: 'provider-quote',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider-quote',
      providerAccessGrantedAt: timestamp,
      statusProposta: 'aceita_cliente',
      ...quoteShape,
      ...invalidRange,
    });
    assert.strictEqual(invalidAcceptedQuote.action, 'quarantine', description);
    assert.strictEqual(
      invalidAcceptedQuote.reason,
      'quote_without_valid_positive_range',
      description,
    );
  }
}

assert.strictEqual(acceptedQuoteRangeIsValid({
  statusProposta: 'aceita_cliente',
  valorMinEstimadoPrestador: '100',
  valorMaxEstimadoPrestador: 100,
}), true);
assert.strictEqual(acceptedQuoteRangeIsValid({
  statusProposta: 'ACEITA_CLIENTE',
  valorMinEstimadoPrestador: 100,
  valorMaxEstimadoPrestador: 150,
}), false);

const cancelledGrant = classifyProviderAccessGrant({
  status: 'cancelado',
  prestadorId: 'provider-1',
  providerAccessGranted: true,
  providerAccessGrantedTo: 'provider-1',
  providerAccessGrantedAt: timestamp,
});
assert.strictEqual(cancelledGrant.action, 'revoke');

const unknownLegacyGrant = classifyProviderAccessGrant({
  status: 'finalizado_legacy',
  prestadorId: 'provider-1',
  providerAccessGranted: true,
  providerAccessGrantedTo: 'provider-1',
  providerAccessGrantedAt: timestamp,
});
assert.strictEqual(unknownLegacyGrant.action, 'quarantine');
assert.strictEqual(unknownLegacyGrant.reason, 'unknown_legacy_state');

const decoded = decodeFirestoreFields({
  status: { stringValue: 'aceito' },
  prestadorId: { stringValue: 'provider-1' },
  providerAccessGranted: { booleanValue: false },
  updatedAt: { timestampValue: timestamp.toISOString() },
});
assert.strictEqual(decoded.status, 'aceito');
assert.strictEqual(decoded.providerAccessGranted, false);
assert.strictEqual(decoded.updatedAt.getTime(), timestamp.getTime());

const records = [
  { id: 'keep', data: {
    status: 'aceito',
    clienteId: 'client-1',
    prestadorId: 'provider-1',
    providerAccessGranted: true,
    providerAccessGrantedTo: 'provider-1',
    providerAccessGrantedAt: timestamp,
  } },
  { id: 'backfill', updateTime: '2026-07-20T12:01:00.000000Z', data: {
    status: 'em_andamento', clienteId: 'client-2',
    prestadorId: 'provider-2', serviceStartedAt: timestamp,
  } },
  { id: 'revoke', data: {
    status: 'aguarda_resposta_cliente',
    prestadorId: 'provider-3',
    providerAccessGranted: true,
    providerAccessGrantedTo: 'provider-3',
    providerAccessGrantedAt: timestamp,
    providerAccessMigrationVersion: 'provider-access-grants-v1',
    providerAccessMigrationResult: 'quarantine',
    providerAccessMigrationReason: 'provider_target_conflict',
  } },
  { id: 'quarantine', data: {
    status: 'concluido', clienteId: 'client-4', prestadorId: 'provider-4',
  } },
  { id: 'unchanged', data: { status: 'criado' } },
];
const plan = buildMigrationPlan(records);
assert.deepStrictEqual(plan.counts, {
  scanned: 5,
  keep: 1,
  backfill: 1,
  revoke: 1,
  quarantine: 1,
  unchanged: 1,
  inconsistentGrants: 1,
  writesPlanned: 3,
});
assert.strictEqual(plan.writes.every((write) => write.patch.providerAccessMigrationVersion
  === MIGRATION_VERSION), true);
assert.strictEqual(plan.writes.every((write) => (
  !Object.prototype.hasOwnProperty.call(write.patch, 'providerAccessMigrationResult')
  && !Object.prototype.hasOwnProperty.call(write.patch, 'providerAccessMigrationReason')
)), true);
const revokeWrite = plan.writes.find((write) => write.id === 'revoke');
assert.deepStrictEqual(revokeWrite.deleteFields, [
  'providerAccessMigrationResult',
  'providerAccessMigrationReason',
]);
assert.strictEqual(revokeWrite.audit.id, auditDocumentId('revoke'));
assert.strictEqual(revokeWrite.audit.fields.action, 'revoke');
assert.strictEqual(
  revokeWrite.audit.fields.reason,
  'pending_relation_must_not_have_grant',
);
assert.strictEqual(revokeWrite.audit.fields.internalMetadataRemoved, true);
assert.strictEqual(
  plan.writes.find((write) => write.id === 'backfill').updateTime,
  '2026-07-20T12:01:00.000000Z',
);
const reconciliationEvidence = buildReconciliationEvidence(plan, {
  executed: true,
  dryRun: false,
  afterPlan: { counts: { inconsistentGrants: 0 } },
});
assert.deepStrictEqual({
  ...reconciliationEvidence,
  executionOutputSha256: '<redacted-hash>',
}, {
  schemaVersion: 'pedido-grant-reconciliation-v1',
  executed: true,
  dryRun: false,
  scanned: 5,
  collectionTotalObserved: 5,
  backfilled: 1,
  revoked: 1,
  unchanged: 2,
  manualReview: 1,
  inconsistentAfter: 0,
  deletesPerformed: 0,
  executionOutputSha256: '<redacted-hash>',
});
assert.match(reconciliationEvidence.executionOutputSha256, /^[a-f0-9]{64}$/);
assert.strictEqual(
  reconciliationEvidence.executionOutputSha256,
  buildReconciliationEvidence(plan, {
    executed: true,
    dryRun: false,
    afterPlan: { counts: { inconsistentGrants: 0 } },
  }).executionOutputSha256,
);
assert.strictEqual(buildReconciliationEvidence(plan, {
  executed: true,
  dryRun: false,
  afterPlan: { counts: { inconsistentGrants: 0, writesPlanned: 1 } },
}).inconsistentAfter, 1);

// Applying the deterministic patches twice must not schedule a second write.
const applied = records.map((record) => {
  const write = plan.writes.find((candidate) => candidate.id === record.id);
  if (!write) return record;
  const nextData = { ...record.data, ...write.patch };
  for (const field of write.deleteFields) delete nextData[field];
  return { ...record, data: nextData };
});
const secondPlan = buildMigrationPlan(applied);
assert.strictEqual(secondPlan.counts.writesPlanned, 0);

const privacyCleanupPlan = buildMigrationPlan([{
  id: 'valid-grant-with-public-internal-reason',
  updateTime: '2026-07-20T12:02:00.000000Z',
  data: {
    status: 'aceito',
    clienteId: 'client-cleanup',
    prestadorId: 'provider-cleanup',
    providerAccessGranted: true,
    providerAccessGrantedTo: 'provider-cleanup',
    providerAccessGrantedAt: timestamp,
    providerAccessMigrationVersion: 'provider-access-grants-v1',
    providerAccessMigrationResult: 'quarantine',
    providerAccessMigrationReason: 'client_provider_self_dealing',
  },
}]);
assert.strictEqual(privacyCleanupPlan.counts.keep, 1);
assert.strictEqual(privacyCleanupPlan.counts.writesPlanned, 1);
assert.deepStrictEqual(privacyCleanupPlan.writes[0].patch, {
  providerAccessMigrationVersion: MIGRATION_VERSION,
});
assert.deepStrictEqual(privacyCleanupPlan.writes[0].deleteFields, [
  'providerAccessMigrationResult',
  'providerAccessMigrationReason',
]);
assert.strictEqual(
  privacyCleanupPlan.writes[0].audit.fields.reason,
  'valid_existing_grant',
);

async function verifyReadAndWriteConcurrencySafeguards() {
  const updateTime = '2026-07-20T12:34:56.123456Z';
  const decodedRecords = await readPedidos({
    async get() {
      return {
        body: {
          documents: [{
            name: 'projects/test-project/databases/(default)/documents/pedidos/pedido-rest',
            updateTime,
            fields: {
              status: { stringValue: 'aceito' },
              prestadorId: { stringValue: 'provider-rest' },
              updatedAt: { timestampValue: timestamp.toISOString() },
            },
          }],
        },
      };
    },
  }, 'test-project', null);
  assert.strictEqual(decodedRecords[0].updateTime, updateTime);

  const commits = [];
  const fakeClient = {
    async post(path, body) {
      commits.push({ path, body });
    },
  };
  const writes = Array.from({ length: 401 }, (_, index) => ({
    id: `pedido-${index}`,
    updateTime: `2026-07-20T12:${String(index % 60).padStart(2, '0')}:00.000000Z`,
    patch: {
      providerAccessGranted: false,
      providerAccessGrantedTo: null,
      providerAccessGrantedAt: null,
      providerAccessMigrationVersion: MIGRATION_VERSION,
    },
    deleteFields: index === 0 ? [
      'providerAccessMigrationResult',
      'providerAccessMigrationReason',
    ] : [],
    audit: {
      id: auditDocumentId(`pedido-${index}`),
      fields: {
        pedidoId: `pedido-${index}`,
        migrationVersion: MIGRATION_VERSION,
        action: 'revoke',
        reason: 'test',
        sourceUpdateTime: `2026-07-20T12:${String(index % 60).padStart(2, '0')}:00.000000Z`,
        internalMetadataRemoved: index === 0,
      },
    },
  }));
  const result = await commitWrites(fakeClient, 'test-project', writes);
  assert.deepStrictEqual(result, {
    writesCommitted: 401,
    auditWritesCommitted: 401,
    batchesCommitted: 3,
  });
  assert.strictEqual(commits[0].body.writes.length, 400);
  assert.strictEqual(commits[1].body.writes.length, 400);
  assert.strictEqual(commits[2].body.writes.length, 2);
  for (const commit of commits) {
    for (let index = 0; index < commit.body.writes.length; index += 2) {
      const write = commit.body.writes[index];
      const auditWrite = commit.body.writes[index + 1];
      assert.ok(write.update);
      assert.ok(write.updateMask);
      assert.ok(write.currentDocument);
      assert.strictEqual(
        write.currentDocument.updateTime,
        writes.find(({ id }) => write.update.name.endsWith(`/${id}`)).updateTime,
      );
      assert.strictEqual(Object.prototype.hasOwnProperty.call(write, 'delete'), false);
      assert.strictEqual(
        Object.prototype.hasOwnProperty.call(write.update.fields, 'providerAccessMigrationResult'),
        false,
      );
      assert.strictEqual(
        Object.prototype.hasOwnProperty.call(write.update.fields, 'providerAccessMigrationReason'),
        false,
      );

      assert.ok(auditWrite.update.name.includes(`/documents/${AUDIT_COLLECTION}/`));
      assert.deepStrictEqual(auditWrite.currentDocument, { exists: false });
      assert.strictEqual(
        auditWrite.update.fields.reason.stringValue,
        'test',
      );
    }
  }
  assert.ok(commits[0].body.writes[0].updateMask.fieldPaths.includes(
    'providerAccessMigrationReason',
  ));
  assert.strictEqual(
    Object.prototype.hasOwnProperty.call(
      commits[0].body.writes[0].update.fields,
      'providerAccessMigrationReason',
    ),
    false,
  );

  const missingPreconditionClient = { async post() { throw new Error('must not commit'); } };
  await assert.rejects(
    () => commitWrites(missingPreconditionClient, 'test-project', [{
      id: 'missing-update-time',
      patch: writes[0].patch,
    }]),
    /updateTime precondition/,
  );
  await assert.rejects(
    () => commitWrites(missingPreconditionClient, 'test-project', [{
      id: 'missing-audit',
      updateTime,
      patch: writes[0].patch,
    }]),
    /deterministic audit record/,
  );

  let conflictAttempts = 0;
  const conflictClient = {
    async post() {
      conflictAttempts += 1;
      throw new Error('ABORTED: currentDocument.updateTime mismatch');
    },
  };
  await assert.rejects(
    () => commitWrites(conflictClient, 'test-project', writes),
    /ABORTED/,
  );
  assert.strictEqual(conflictAttempts, 1);
}

verifyReadAndWriteConcurrencySafeguards()
  .then(() => console.log('migrate_provider_access_grants safeguards ok'))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
