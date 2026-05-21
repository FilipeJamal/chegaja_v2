const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

function extractFunction(source, name) {
  const marker = `async function ${name}`;
  const start = source.indexOf(marker);
  assert.notStrictEqual(start, -1, `Function ${name} not found`);

  const openBrace = source.indexOf('{', start);
  let depth = 0;
  for (let index = openBrace; index < source.length; index += 1) {
    const char = source[index];
    if (char === '{') depth += 1;
    if (char === '}') depth -= 1;
    if (depth === 0) return source.slice(start, index + 1);
  }

  throw new Error(`Could not extract ${name}`);
}

function visibleLocator(value) {
  return {
    first() {
      return this;
    },
    async isVisible() {
      return value;
    },
  };
}

function fakePage({ inputVisible, textAreaVisible, orderSubmitVisible, profileSubmitVisible }) {
  return {
    locator(selector) {
      if (selector.startsWith('input')) return visibleLocator(inputVisible);
      if (selector.startsWith('textarea')) return visibleLocator(textAreaVisible);
      return visibleLocator(false);
    },
    getByText(pattern) {
      const source = pattern instanceof RegExp ? pattern.source : String(pattern);
      const matchesOrderSubmit = /Pedir|Request/.test(source) && orderSubmitVisible;
      const matchesProfileSubmit = /Guardar|Save/.test(source) && profileSubmitVisible;
      return visibleLocator(matchesOrderSubmit || matchesProfileSubmit);
    },
  };
}

const scriptPath = path.join(process.cwd(), 'scripts', 'e2e', 'full_ui_dual_role_e2e.js');
const scriptSource = fs.readFileSync(scriptPath, 'utf8');
const isOnOrderForm = vm.runInNewContext(`(${extractFunction(scriptSource, 'isOnOrderForm')})`);

(async () => {
  assert.strictEqual(
    await isOnOrderForm(
      fakePage({
        inputVisible: true,
        textAreaVisible: true,
        orderSubmitVisible: false,
        profileSubmitVisible: true,
      }),
    ),
    false,
    'profile edit forms must not be treated as order forms',
  );

  assert.strictEqual(
    await isOnOrderForm(
      fakePage({
        inputVisible: true,
        textAreaVisible: true,
        orderSubmitVisible: true,
        profileSubmitVisible: false,
      }),
    ),
    true,
    'order forms with the order submit CTA should be detected',
  );

  console.log('full_ui_dual_role_e2e order form detection ok');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
