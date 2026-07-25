const assert = require('assert');

const {
  ALLOWED_DISPATCH_FIELDS,
  SERVER_TIMESTAMP,
  buildPedidoDispatchProjection,
  buildReconciliationEvidence,
  buildReconciliationPlan,
  commitReconciliationPlan,
  readCollection,
  reconcileWithClient,
  resolveOptions,
} = require('../admin/reconcile_pedido_dispatch');

process.env.PILOT_MARKET_ID = 'mz-maputo';
process.env.DEFAULT_CURRENCY_CODE = 'MZN';
process.env.RECONCILE_ALLOW_LEGACY_MAPUTO = 'true';

function record(id, updateTime, data) {
  return { id, updateTime, data };
}

function restDocument(collection, item) {
  return {
    name: `projects/test-project/databases/(default)/documents/${collection}/${item.id}`,
    updateTime: item.updateTime,
    fields: Object.fromEntries(Object.entries(item.data).map(([key, value]) => {
      if (value === null) return [key, { nullValue: null }];
      if (typeof value === 'boolean') return [key, { booleanValue: value }];
      if (typeof value === 'number') return [key, { doubleValue: value }];
      if (value instanceof Date) return [key, { timestampValue: value.toISOString() }];
      return [key, { stringValue: value }];
    })),
  };
}

async function main() {
  assert.throws(() => resolveOptions([]), /--project is required/);
  assert.throws(
    () => resolveOptions([
      '--project=test-project',
      '--market=mz-maputo',
      '--confirm',
    ]),
    /--confirm-project/,
  );
  assert.throws(
    () => resolveOptions([
      '--project=test-project',
      '--market=mz-maputo',
      '--confirm',
      '--confirm-project=other-project',
    ]),
    /must match --project exactly/,
  );
  assert.throws(
    () => resolveOptions(['--project=test-project']),
    /--market is required/,
  );
  assert.throws(
    () => resolveOptions([
      '--project=test-project',
      '--market=pt-coimbra',
      '--allow-legacy-maputo',
    ]),
    /only valid with --market=mz-maputo/,
  );
  assert.strictEqual(resolveOptions([
    '--project=test-project',
    '--market=mz-maputo',
  ]).dryRun, true);
  assert.strictEqual(resolveOptions([
    '--project=test-project',
    '--market=mz-maputo',
  ]).allowLegacyMaputo, false);
  assert.strictEqual(resolveOptions([
    '--project=test-project',
    '--market=mz-maputo',
    '--confirm',
    '--confirm-project=test-project',
  ]).dryRun, false);
  await assert.rejects(
    reconcileWithClient({}, {
      projectId: 'test-project',
      marketId: 'mz-maputo',
      allowLegacyMaputo: true,
      confirmProject: 'wrong-project',
      confirm: true,
      dryRun: false,
      pageSize: 500,
    }, {
      async readState() {
        return { pedidos: [], dispatchDocuments: [] };
      },
    }),
    /must match --project exactly/,
  );

  const openProjection = buildPedidoDispatchProjection('open-order', {
    status: 'criado',
    moderationStatus: 'approved',
    servicoId: 'canalizacao',
    servicoNome: 'Canalização +258 84 123 4567',
    bairro: 'Rua 12, Casa 44, Coimbra',
    latitude: 40.20561,
    longitude: -8.41392,
    createdAt: new Date('2026-07-20T10:00:00.000Z'),
  });
  assert.deepStrictEqual(
    Object.keys(openProjection).sort(),
    [...ALLOWED_DISPATCH_FIELDS].sort(),
  );
  assert.strictEqual(openProjection.prestadorId, null);
  assert.strictEqual(openProjection.targetProviderId, null);
  assert.strictEqual(openProjection.servicoNome.includes('84 123 4567'), false);
  assert.strictEqual(openProjection.enderecoTexto, openProjection.zoneLabel);
  assert.strictEqual(openProjection.zoneLabel.includes('Casa'), false);
  assert.strictEqual(openProjection.latitude, 40.21);
  assert.strictEqual(openProjection.longitude, -8.41);
  assert.strictEqual(openProjection.updatedAt, SERVER_TIMESTAMP);
  assert.strictEqual(openProjection.marketId, 'mz-maputo');
  assert.strictEqual(openProjection.currency, 'MZN');

  const targetedProjection = buildPedidoDispatchProjection('targeted-order', {
    status: 'aguarda_resposta_prestador',
    estado: 'aguarda_resposta_prestador',
    prestadorId: 'provider-1',
    moderationStatus: 'approved',
    modo: 'POR_PROPOSTA',
    tipoPreco: 'por_orcamento',
    valorMinEstimadoPrestador: 100,
    valorMaxEstimadoPrestador: 150,
    statusProposta: 'pendente_prestador',
    propostaExpiresAt: new Date('2026-07-20T13:00:00.000Z'),
  });
  assert.strictEqual(targetedProjection.prestadorId, null);
  assert.strictEqual(targetedProjection.targetProviderId, 'provider-1');
  assert.strictEqual(targetedProjection.valorMinEstimadoPrestador, 100);
  assert.strictEqual(targetedProjection.valorMaxEstimadoPrestador, 150);

  const previousMarketId = process.env.PILOT_MARKET_ID;
  const previousCurrency = process.env.DEFAULT_CURRENCY_CODE;
  try {
    process.env.PILOT_MARKET_ID = 'pt-coimbra';
    process.env.DEFAULT_CURRENCY_CODE = 'EUR';
    const marketPlan = buildReconciliationPlan([
      record('active-market', '2026-07-20T10:00:00.000000Z', {
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'criado',
        moderationStatus: 'approved',
      }),
      record('other-market', '2026-07-20T10:00:00.000000Z', {
        marketId: 'mz-maputo',
        currency: 'MZN',
        status: 'criado',
        moderationStatus: 'approved',
      }),
      record('legacy-missing-market', '2026-07-20T10:00:00.000000Z', {
        status: 'criado',
        moderationStatus: 'approved',
      }),
    ], [
      record('other-market', '2026-07-20T10:01:00.000000Z', {
        pedidoId: 'other-market',
      }),
      record('legacy-missing-market', '2026-07-20T10:01:00.000000Z', {
        pedidoId: 'legacy-missing-market',
      }),
    ]);
    assert.strictEqual(marketPlan.counts.eligibleOpen, 1);
    assert.strictEqual(marketPlan.counts.upserts, 1);
    assert.strictEqual(marketPlan.counts.deletesTerminalOrStale, 2);
    const activeProjection = marketPlan.mutations.find(
      ({ pedidoId }) => pedidoId === 'active-market',
    ).projection;
    assert.strictEqual(activeProjection.marketId, 'pt-coimbra');
    assert.strictEqual(activeProjection.currency, 'EUR');
    assert(marketPlan.mutations
      .filter(({ action }) => action === 'delete')
      .every(({ reason }) => reason === 'terminal_or_stale'));
  } finally {
    if (previousMarketId === undefined) delete process.env.PILOT_MARKET_ID;
    else process.env.PILOT_MARKET_ID = previousMarketId;
    if (previousCurrency === undefined) delete process.env.DEFAULT_CURRENCY_CODE;
    else process.env.DEFAULT_CURRENCY_CODE = previousCurrency;
  }

  const conflictingLifecyclePlan = buildReconciliationPlan([record(
    'conflicting-lifecycle',
    '2026-07-20T10:00:00.000000Z',
    {
      status: 'criado',
      estado: 'cancelado',
      moderationStatus: 'approved',
    },
  )], [record(
    'conflicting-lifecycle',
    '2026-07-20T10:01:00.000000Z',
    { pedidoId: 'conflicting-lifecycle' },
  )]);
  assert.strictEqual(conflictingLifecyclePlan.counts.eligibleOpen, 0);
  assert.strictEqual(conflictingLifecyclePlan.counts.deletesTerminalOrStale, 1);
  assert.strictEqual(conflictingLifecyclePlan.mutations[0].action, 'delete');

  const pedidos = [
    record('open-order', '2026-07-20T10:01:00.000000Z', {
      status: 'criado',
      moderationStatus: 'approved',
      servicoNome: 'Canalização',
      createdAt: new Date('2026-07-20T10:00:00.000Z'),
    }),
    record('targeted-order', '2026-07-20T10:02:00.000000Z', {
      status: 'aguarda_resposta_prestador',
      moderationStatus: 'approved',
      prestadorId: 'provider-1',
      servicoNome: 'Pintura',
      createdAt: new Date('2026-07-20T10:00:00.000Z'),
    }),
    record('terminal-order', '2026-07-20T10:03:00.000000Z', {
      status: 'concluido',
      prestadorId: 'provider-2',
    }),
  ];
  const dispatchDocuments = [
    record('terminal-order', '2026-07-20T11:03:00.000000Z', {
      pedidoId: 'terminal-order',
      clienteId: 'must-be-removed',
    }),
    record('orphan-order', '2026-07-20T11:04:00.000000Z', {
      pedidoId: 'orphan-order',
      telefone: '+351900000000',
    }),
  ];
  const plan = buildReconciliationPlan(pedidos, dispatchDocuments);
  assert.deepStrictEqual(plan.counts, {
    pedidosScanned: 3,
    dispatchScanned: 2,
    eligibleOpen: 1,
    eligibleTargeted: 1,
    upserts: 2,
    deletesTerminalOrStale: 1,
    deletesOrphan: 1,
    unchanged: 0,
    inconsistencies: 4,
  });
  assert.strictEqual(plan.mutations.filter(({ action }) => action === 'upsert').length, 2);
  assert.strictEqual(plan.mutations.filter(({ reason }) => reason === 'terminal_or_stale').length, 1);
  assert.strictEqual(plan.mutations.filter(({ reason }) => reason === 'orphan').length, 1);

  const alreadyReconciled = buildReconciliationPlan(
    pedidos.slice(0, 2),
    pedidos.slice(0, 2).map((pedido) => record(
      pedido.id,
      '2026-07-20T11:00:00.000000Z',
      {
        ...buildPedidoDispatchProjection(pedido.id, pedido.data),
        updatedAt: new Date('2026-07-20T11:00:00.000Z'),
      },
    )),
  );
  assert.strictEqual(alreadyReconciled.counts.inconsistencies, 0);
  assert.deepStrictEqual(alreadyReconciled.mutations, []);

  const pagedRecords = Array.from({ length: 501 }, (_, index) => record(
    `order-${String(index).padStart(3, '0')}`,
    '2026-07-20T12:00:00.000000Z',
    { status: 'concluido' },
  ));
  const pageCalls = [];
  const pagedClient = {
    async get(_path, { queryParams }) {
      pageCalls.push({ ...queryParams });
      const start = queryParams.pageToken ? Number(queryParams.pageToken) : 0;
      const end = Math.min(start + Number(queryParams.pageSize), pagedRecords.length);
      return {
        body: {
          documents: pagedRecords.slice(start, end).map((item) => restDocument('pedidos', item)),
          ...(end < pagedRecords.length ? { nextPageToken: String(end) } : {}),
        },
      };
    },
  };
  const allRecords = await readCollection(
    pagedClient,
    'test-project',
    'pedidos',
    { pageSize: 250 },
  );
  assert.strictEqual(allRecords.length, 501);
  assert.strictEqual(pageCalls.length, 3);
  assert(pageCalls.every(({ pageSize }) => pageSize === 250));

  const commitBodies = [];
  const transactionReads = [];
  let transactionsBegun = 0;
  const commitClient = {
    async post(path, body) {
      if (path.endsWith(':beginTransaction')) {
        transactionsBegun += 1;
        return { body: { transaction: 'transaction-1' } };
      }
      if (path.endsWith(':rollback')) return { body: {} };
      commitBodies.push({ path, body });
      throw new Error('ABORTED: source changed after transactional read');
    },
    async get(path, options) {
      transactionReads.push({ path, options });
      if (path.includes('/pedidos/open-order')) {
        return {
          body: restDocument('pedidos', pedidos[0]),
        };
      }
      const error = new Error('NOT_FOUND');
      error.status = 404;
      throw error;
    },
  };
  await assert.rejects(
    commitReconciliationPlan(commitClient, 'test-project', {
      mutations: [plan.mutations.find(({ action }) => action === 'upsert')],
    }),
    /ABORTED/,
  );
  assert.strictEqual(transactionsBegun, 1);
  assert.strictEqual(transactionReads.length, 2);
  assert(transactionReads.every(({ options }) => (
    options.queryParams.transaction === 'transaction-1'
  )));
  assert.strictEqual(commitBodies[0].body.transaction, 'transaction-1');
  const concurrentWrites = commitBodies[0].body.writes;
  assert.strictEqual(concurrentWrites.length, 1);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(concurrentWrites[0], 'verify'), false);
  assert.deepStrictEqual(concurrentWrites[0].currentDocument, { exists: false });

  const afterPlan = buildReconciliationPlan(
    pedidos.slice(0, 2),
    pedidos.slice(0, 2).map((pedido) => record(
      pedido.id,
      '2026-07-20T11:00:00.000000Z',
      {
        ...buildPedidoDispatchProjection(pedido.id, pedido.data),
        updatedAt: new Date('2026-07-20T11:00:00.000Z'),
      },
    )),
  );
  let stateReads = 0;
  let commits = 0;
  const confirmed = await reconcileWithClient({}, {
    projectId: 'test-project',
    marketId: 'mz-maputo',
    allowLegacyMaputo: true,
    confirmProject: 'test-project',
    confirm: true,
    dryRun: false,
    pageSize: 500,
  }, {
    async readState() {
      stateReads += 1;
      return stateReads === 1
        ? { pedidos, dispatchDocuments }
        : { pedidos: pedidos.slice(0, 2), dispatchDocuments: afterPlan.dispatchDocuments || [] };
    },
    async commitPlan(_client, _projectId, receivedPlan) {
      commits += 1;
      assert.strictEqual(receivedPlan.counts.inconsistencies, 4);
      return { batchesCommitted: 1, mutationsCommitted: 4 };
    },
    buildPlan(receivedPedidos, receivedDispatch) {
      if (stateReads === 2) return afterPlan;
      return buildReconciliationPlan(receivedPedidos, receivedDispatch);
    },
  });
  assert.strictEqual(stateReads, 2, 'confirm mode must re-read both collections');
  assert.strictEqual(commits, 1);
  assert.strictEqual(confirmed.pedidoDispatchReconciliation.scanned, 3);
  assert.strictEqual(confirmed.pedidoDispatchReconciliation.inconsistentAfter, 0);
  assert.match(
    confirmed.pedidoDispatchReconciliation.executionOutputSha256,
    /^[a-f0-9]{64}$/,
  );
  const evidenceText = JSON.stringify(confirmed.pedidoDispatchReconciliation);
  assert.strictEqual(evidenceText.includes('open-order'), false);
  assert.strictEqual(evidenceText.includes('provider-1'), false);
  assert.strictEqual(evidenceText.includes('must-be-removed'), false);

  const evidence = buildReconciliationEvidence(plan, {
    executed: false,
    dryRun: true,
    afterPlan: plan,
  });
  assert.strictEqual(evidence.scanned, 3);
  assert.strictEqual(evidence.inconsistentAfter, 4);
  assert.strictEqual(evidence.documentIdsIncluded, false);
  assert.strictEqual(evidence.hashAlgorithm, 'sha256-canonical-json-v1');

  const concurrentEvidence = buildReconciliationEvidence(plan, {
    executed: true,
    dryRun: false,
    afterPlan,
    execution: {
      upsertsCommitted: 1,
      deletesCommitted: 1,
      deletesTerminalOrStaleCommitted: 0,
      deletesOrphanCommitted: 1,
    },
  });
  assert.strictEqual(concurrentEvidence.upserted, 1);
  assert.strictEqual(concurrentEvidence.deletedTerminalOrStale, 0);
  assert.strictEqual(concurrentEvidence.deletedOrphan, 1);

  await assert.rejects(
    reconcileWithClient({}, {
      projectId: 'test-project',
      marketId: 'mz-maputo',
      allowLegacyMaputo: true,
      confirmProject: 'test-project',
      confirm: true,
      dryRun: false,
      pageSize: 500,
    }, {
      async readState() {
        return { pedidos: [], dispatchDocuments: [] };
      },
      async commitPlan() {
        throw new Error('must not commit empty scans');
      },
    }),
    /refusing confirmed reconciliation with zero pedidos/i,
  );

  console.log('reconcile_pedido_dispatch safeguards ok');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
