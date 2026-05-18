const { spawnSync } = require('child_process');
const path = require('path');

const EXPECTED_PROJECT = process.env.FIREBASE_PROJECT_ID || 'chegaja-ac88d';
const EXPECTED_RUNTIME = process.env.FIREBASE_FUNCTIONS_RUNTIME || 'nodejs22';
const EXPECTED_FUNCTION_COUNT = Number(process.env.FIREBASE_EXPECTED_FUNCTION_COUNT || 27);

function parseJson(text, label) {
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error(`Failed to parse ${label} JSON: ${error.message}`);
  }
}

function parseFunctionsList(text) {
  const parsed = parseJson(text, 'functions:list');
  const items = Array.isArray(parsed.result) ? parsed.result : [];
  const runtimes = {};
  for (const item of items) {
    const runtime = item && item.runtime ? String(item.runtime) : 'unknown';
    runtimes[runtime] = (runtimes[runtime] || 0) + 1;
  }
  return {
    functionCount: items.length,
    runtimes,
  };
}

function validateFunctionsHealth(summary, {
  expectedRuntime = EXPECTED_RUNTIME,
  expectedFunctionCount = EXPECTED_FUNCTION_COUNT,
} = {}) {
  if (summary.functionCount !== expectedFunctionCount) {
    throw new Error(`Expected ${expectedFunctionCount} Functions, got ${summary.functionCount}.`);
  }
  const runtimeNames = Object.keys(summary.runtimes);
  const unexpected = runtimeNames.filter((runtime) => runtime !== expectedRuntime);
  if (unexpected.length > 0) {
    throw new Error(`Unexpected Function runtimes: ${unexpected.join(',')}.`);
  }
  if (summary.runtimes[expectedRuntime] !== expectedFunctionCount) {
    throw new Error(
      `Expected ${expectedFunctionCount} Functions in ${expectedRuntime}, ` +
      `got ${summary.runtimes[expectedRuntime] || 0}.`,
    );
  }
}

function parseAuditSummary(text) {
  const parsed = parseJson(text, 'npm audit');
  const vulnerabilities = parsed.metadata && parsed.metadata.vulnerabilities
    ? parsed.metadata.vulnerabilities
    : {};
  return {
    critical: Number(vulnerabilities.critical || 0),
    high: Number(vulnerabilities.high || 0),
    moderate: Number(vulnerabilities.moderate || 0),
    low: Number(vulnerabilities.low || 0),
    info: Number(vulnerabilities.info || 0),
  };
}

function validateAuditSummary(summary) {
  if (summary.critical > 0 || summary.high > 0 || summary.moderate > 0) {
    throw new Error(
      `npm audit has critical/high/moderate vulnerabilities: ` +
      `critical=${summary.critical} high=${summary.high} moderate=${summary.moderate}.`,
    );
  }
}

function formatRuntimes(runtimes) {
  return Object.entries(runtimes)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([runtime, count]) => `${runtime}=${count}`)
    .join(',');
}

function buildHealthReport({
  firebaseLogin,
  project,
  functionCount,
  runtimes,
  audit,
}) {
  return [
    `[health:firebase:production] firebaseLogin=${firebaseLogin}`,
    `[health:firebase:production] project=${project}`,
    `[health:firebase:production] functionCount=${functionCount}`,
    `[health:firebase:production] runtimes=${formatRuntimes(runtimes)}`,
    `[health:firebase:production] auditCritical=${audit.critical}`,
    `[health:firebase:production] auditHigh=${audit.high}`,
    `[health:firebase:production] auditModerate=${audit.moderate}`,
    `[health:firebase:production] auditLow=${audit.low}`,
    `[health:firebase:production] status=OK`,
  ].join('\n');
}

function quoteWindowsArg(value) {
  const text = String(value);
  if (/^[A-Za-z0-9_./:=+-]+$/.test(text)) return text;
  return `"${text.replace(/"/g, '\\"')}"`;
}

function runCommand(command, args, { cwd = process.cwd(), allowAuditExit = false } = {}) {
  const spawnCommand = process.platform === 'win32' ? 'cmd.exe' : command;
  const spawnArgs = process.platform === 'win32'
    ? ['/d', '/s', '/c', [command, ...args].map(quoteWindowsArg).join(' ')]
    : args;
  const result = spawnSync(spawnCommand, spawnArgs, {
    cwd,
    encoding: 'utf8',
    shell: false,
  });
  const stdout = result.stdout || '';
  const stderr = result.stderr || '';
  const status = result.status == null ? 1 : result.status;
  if (result.error) {
    throw result.error;
  }
  if (status !== 0 && !(allowAuditExit && stdout.trim())) {
    throw new Error(`${command} ${args.join(' ')} failed (${status}): ${stderr || stdout}`);
  }
  return stdout;
}

function parseFirebaseUseOutput(text) {
  const lines = text.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const activeLine = lines.find((line) => line.includes('Active Project:'));
  if (activeLine) {
    const match = activeLine.match(/Active Project:\s*([^\s(]+)/);
    if (match) return match[1];
  }
  const aliasLine = lines.find((line) => line.includes('Project:'));
  if (aliasLine) {
    const match = aliasLine.match(/Project:\s*([^\s(]+)/);
    if (match) return match[1];
  }
  if (text.includes(EXPECTED_PROJECT)) return EXPECTED_PROJECT;
  return '';
}

async function runHealthCheck({
  expectedProject = EXPECTED_PROJECT,
  expectedRuntime = EXPECTED_RUNTIME,
  expectedFunctionCount = EXPECTED_FUNCTION_COUNT,
} = {}) {
  const loginOutput = runCommand('npx.cmd', ['firebase', 'login:list']);
  if (!/Logged in as/i.test(loginOutput)) {
    throw new Error('Firebase CLI is not authenticated.');
  }

  const projectOutput = runCommand('npx.cmd', ['firebase', 'use']);
  const activeProject = parseFirebaseUseOutput(projectOutput);
  if (activeProject !== expectedProject) {
    throw new Error(`Expected Firebase project ${expectedProject}, got ${activeProject || 'unknown'}.`);
  }

  const functionsOutput = runCommand('npx.cmd', [
    'firebase',
    'functions:list',
    '--project',
    expectedProject,
    '--json',
  ]);
  const functionsSummary = parseFunctionsList(functionsOutput);
  validateFunctionsHealth(functionsSummary, {
    expectedRuntime,
    expectedFunctionCount,
  });

  const auditOutput = runCommand('npm.cmd', ['audit', '--omit=dev', '--json'], {
    cwd: path.resolve(process.cwd(), 'functions'),
    allowAuditExit: true,
  });
  const audit = parseAuditSummary(auditOutput);
  validateAuditSummary(audit);

  return buildHealthReport({
    firebaseLogin: 'ok',
    project: activeProject,
    functionCount: functionsSummary.functionCount,
    runtimes: functionsSummary.runtimes,
    audit,
  });
}

async function main() {
  const report = await runHealthCheck();
  console.log(report);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[health:firebase:production] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  buildHealthReport,
  parseAuditSummary,
  parseFirebaseUseOutput,
  parseFunctionsList,
  runHealthCheck,
  validateAuditSummary,
  validateFunctionsHealth,
};
