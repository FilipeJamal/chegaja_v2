'use strict';

const fs = require('fs');
const path = require('path');
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

function projectIdFromFirebaseRc() {
  const firebaseRcPath = path.resolve(__dirname, '..', '..', '.firebaserc');
  const firebaseRc = JSON.parse(fs.readFileSync(firebaseRcPath, 'utf8'));
  const projectId = firebaseRc?.projects?.default;
  if (typeof projectId !== 'string' || projectId.trim() === '') {
    throw new Error('Projeto Firebase default ausente em .firebaserc.');
  }
  return projectId.trim();
}

async function waitForDispatch(database, pedidoId) {
  const deadline = Date.now() + 30000;
  while (Date.now() < deadline) {
    const snapshot = await database.collection('pedido_dispatch').doc(pedidoId).get();
    if (snapshot.exists) {
      const dispatch = snapshot.data() || {};
      const forbiddenFields = [
        'clienteId',
        'clientId',
        'clienteNome',
        'telefone',
        'phone',
        'email',
        'morada',
        'address',
        'mensagemPropostaPrestador',
      ];
      const exposedField = forbiddenFields.find(
        (field) => Object.prototype.hasOwnProperty.call(dispatch, field),
      );
      if (exposedField) {
        throw new Error(`Projecao ${pedidoId} expos o campo privado ${exposedField}.`);
      }
      if (dispatch.enderecoTexto !== dispatch.zoneLabel) {
        throw new Error(`Projecao ${pedidoId} expos endereco diferente da zona sanitizada.`);
      }
      if (dispatch.pedidoId !== pedidoId
        || dispatch.marketId !== 'pt-coimbra'
        || dispatch.currency !== 'EUR'
        || dispatch.status !== 'criado'
        || dispatch.prestadorId !== null
        || dispatch.targetProviderId !== null) {
        throw new Error(`Projecao ${pedidoId} nao cumpre o contrato sanitizado.`);
      }
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(`Trigger onPedidoCreated nao criou a projecao ${pedidoId}.`);
}

async function validateCallable({ host, projectId, region }) {
  const functionName = 'admin_listReports';
  const url = `http://${host}/${projectId}/${region}/${functionName}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ data: { limit: 1 } }),
    signal: AbortSignal.timeout(15000),
  });
  const body = await response.text();

  if (response.status === 404 || response.status >= 500) {
    throw new Error(
      `Callable ${functionName} indisponivel: HTTP ${response.status} ${body.slice(0, 300)}`,
    );
  }

  let payload;
  try {
    payload = JSON.parse(body);
  } catch (_) {
    throw new Error(
      `Callable ${functionName} devolveu resposta nao JSON: HTTP ${response.status}`,
    );
  }

  const controlledError = [400, 401, 403].includes(response.status)
    && payload?.error
    && ['INVALID_ARGUMENT', 'UNAUTHENTICATED', 'PERMISSION_DENIED']
      .includes(payload.error.status);
  const callableResult = response.ok
    && payload
    && Object.prototype.hasOwnProperty.call(payload, 'result');

  if (!controlledError && !callableResult) {
    throw new Error(
      `Callable ${functionName} devolveu resposta inesperada: HTTP ${response.status} ${body.slice(0, 300)}`,
    );
  }

  return `${functionName}=HTTP ${response.status}`;
}

async function main() {
  const projectId = process.env.GCLOUD_PROJECT
    || process.env.GOOGLE_CLOUD_PROJECT
    || projectIdFromFirebaseRc();
  const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
  const region = process.env.FUNCTIONS_REGION || 'europe-west1';
  if (getApps().length === 0) initializeApp({ projectId });
  const database = getFirestore();
  const pedidoId = `ci-functions-smoke-${Date.now()}`;
  const pedidoRef = database.collection('pedidos').doc(pedidoId);
  const dispatchRef = database.collection('pedido_dispatch').doc(pedidoId);

  try {
    await pedidoRef.set({
      clienteId: 'ci-client',
      marketId: 'pt-coimbra',
      currency: 'EUR',
      status: 'criado',
      estado: 'criado',
      prestadorId: null,
      moderationStatus: 'approved',
      servicoId: 'ci-smoke-service',
      servicoNome: 'Servico de teste CI',
      city: 'Coimbra',
      bairro: 'Coimbra',
      dispatchZoneId: 'coimbra',
      latitude: 40.2056,
      longitude: -8.4196,
    });

    await waitForDispatch(database, pedidoId);
    const callableResult = await validateCallable({
      host: functionsHost,
      projectId,
      region,
    });

    console.log(
      `Functions discovery ok: onPedidoCreated criou pedido_dispatch sanitizado; ${callableResult}.`,
    );
  } finally {
    await Promise.all([
      dispatchRef.delete(),
      pedidoRef.delete(),
    ]);
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
