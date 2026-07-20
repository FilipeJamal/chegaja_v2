const assert = require('assert');
const fs = require('fs');
const path = require('path');

describe('P1.6 App Check configuration', () => {
  const source = fs.readFileSync(path.resolve(__dirname, '../index.js'), 'utf8');

  it('wraps every callable with App Check enforcement outside emulators', () => {
    assert(source.includes('onCall: firebaseOnCall'));
    assert(source.includes('enforceAppCheck: !useEmulators'));
    assert(source.includes('await enforceCallableRateLimit(request)'));
    assert(!source.includes('const { onCall, onRequest'));
  });

  it('protects all external Google API proxies with App Check, Auth and rate limits', () => {
    for (const endpoint of ['places_autocomplete', 'places_details', 'directions_route']) {
      assert(source.includes(`endpoint: '${endpoint}'`), `${endpoint} is not protected`);
    }
    assert(source.includes("req.get('X-Firebase-AppCheck')"));
    assert(source.includes('firebaseAppCheck.verifyToken(appCheckToken)'));
    assert(source.includes('firebaseAuth.verifyIdToken(idToken, true)'));
  });
});
