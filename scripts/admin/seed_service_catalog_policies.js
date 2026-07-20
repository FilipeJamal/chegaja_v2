const fs = require('fs');
const path = require('path');

function optionsFrom(argv) {
  const options = {
    projectId: process.env.FIREBASE_PROJECT_ID || 'chegaja-ac88d',
    confirm: false,
    confirmProject: '',
  };
  argv.forEach((arg) => {
    if (arg === '--confirm') options.confirm = true;
    else if (arg.startsWith('--project=')) options.projectId = arg.slice(10);
    else if (arg.startsWith('--confirm-project=')) options.confirmProject = arg.slice(18);
    else if (arg !== '--dry-run') throw new Error(`Unknown argument: ${arg}`);
  });
  if (options.confirm && options.confirmProject !== options.projectId) {
    throw new Error('--confirm-project must match --project exactly.');
  }
  return options;
}

function exportPolicies() {
  const root = path.resolve(__dirname, '..', '..');
  const source = fs.readFileSync(
    path.join(root, 'lib', 'core', 'catalog', 'service_taxonomy_catalog.dart'),
    'utf8',
  );
  const blocks = [];
  const marker = 'ServiceTaxonomySubcategory(';
  let cursor = 0;
  while ((cursor = source.indexOf(marker, cursor)) >= 0) {
    const start = cursor + marker.length;
    let depth = 1;
    let quote = '';
    let escaped = false;
    let end = start;
    for (; end < source.length && depth > 0; end += 1) {
      const char = source[end];
      if (quote) {
        if (escaped) escaped = false;
        else if (char === '\\') escaped = true;
        else if (char === quote) quote = '';
        continue;
      }
      if (char === "'" || char === '"') quote = char;
      else if (char === '(') depth += 1;
      else if (char === ')') depth -= 1;
    }
    blocks.push(source.slice(start, end - 1));
    cursor = end;
  }
  const field = (block, name) => {
    const match = block.match(new RegExp(`${name}:\\s*'([^']*)'`));
    return match ? match[1] : '';
  };
  const intentMode = { now: 'IMEDIATO', scheduled: 'AGENDADO', quote: 'POR_PROPOSTA' };
  return blocks.map((block) => {
    const id = field(block, 'id');
    const allowedBlock = (block.match(/allowedIntents:\s*\[([\s\S]*?)\]/) || [])[1] || '';
    const intents = [...allowedBlock.matchAll(/ServiceIntent\.(\w+)/g)]
      .map((match) => intentMode[match[1]])
      .filter(Boolean);
    const riskMatch = block.match(/riskLevel:\s*CategoryRiskLevel\.(\w+)/);
    const requirementId = field(block, 'sensitiveRequirementId');
    return {
      id,
      name: field(block, 'label'),
      description: field(block, 'description'),
      isActive: true,
      riskLevel: riskMatch ? riskMatch[1] : 'normal',
      approvalRequired: /requiresApproval:\s*true/.test(block),
      ...(requirementId ? { sensitiveRequirementId: requirementId } : {}),
      allowedIntents: intents,
      parentCategoryId: field(block, 'parentCategoryId'),
    };
  }).filter((policy) => policy.id && policy.name);
}

function firestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(firestoreValue) } };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, child]) => [key, firestoreValue(child)]),
        ),
      },
    };
  }
  throw new Error(`Unsupported Firestore value type: ${typeof value}`);
}

function firestoreFields(value) {
  return Object.fromEntries(
    Object.entries(value).map(([key, child]) => [key, firestoreValue(child)]),
  );
}

async function firestoreRestClient(projectId) {
  const root = path.resolve(__dirname, '..', '..');
  const auth = require(path.join(root, 'node_modules', 'firebase-tools', 'lib', 'auth'));
  const { requireAuth } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'requireAuth'),
  );
  const { Client } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'apiv2'),
  );
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Run firebase login before seeding the catalog.');
  await requireAuth({ project: projectId, nonInteractive: true, ...account });
  return new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
}

async function commitWrites(client, projectId, writes) {
  const database = `projects/${projectId}/databases/(default)`;
  for (let start = 0; start < writes.length; start += 400) {
    const batch = writes.slice(start, start + 400).map(([collection, id, data]) => {
      const fields = firestoreFields(data);
      return {
        update: {
          name: `${database}/documents/${collection}/${id}`,
          fields,
        },
        updateMask: { fieldPaths: Object.keys(fields) },
      };
    });
    await client.post(`/${database}/documents:commit`, { writes: batch });
  }
}

async function seed(options, policies) {
  const summary = {
    projectId: options.projectId,
    dryRun: !options.confirm,
    policies: policies.length,
    sensitiveRequirements: policies.filter((policy) => policy.approvalRequired).length,
  };
  if (!options.confirm) return summary;

  const client = await firestoreRestClient(options.projectId);
  const now = new Date();
  const writes = [];
  for (const policy of policies) {
    writes.push(['service_catalog_policies', policy.id, { ...policy, updatedAt: now }]);
    if (policy.approvalRequired) {
      const requirementId = policy.sensitiveRequirementId || policy.id;
      writes.push(['categoryRequirements', requirementId, {
        categoryId: requirementId,
        categoryName: policy.name,
        riskLevel: policy.riskLevel || 'sensitive',
        approvalRequired: true,
        evidenceTypes: ['certificate', 'license', 'work_experience', 'portfolio_reference'],
        description: `A categoria ${policy.name} exige analise adicional antes de receber trabalhos.`,
        userMessage: 'Submete comprovativos verdadeiros para analise da equipa.',
        isActive: true,
        updatedAt: now,
      }]);
    }
  }
  await commitWrites(client, options.projectId, writes);
  return summary;
}

async function main() {
  const options = optionsFrom(process.argv.slice(2));
  const policies = exportPolicies();
  const summary = await seed(options, policies);
  console.log(JSON.stringify(summary, null, 2));
  console.log(options.confirm ? 'CATALOG_POLICIES_WRITTEN' : 'DRY_RUN_ONLY');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[seed_service_catalog_policies] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = { exportPolicies, firestoreFields, firestoreValue, optionsFrom, seed };
