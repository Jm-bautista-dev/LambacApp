const assert = require('assert');
const crypto = require('crypto');
const http = require('http');
const { app, _testHelpers } = require('./server.js');

const {
  verifyPaymongoSignature,
  isQualifyingFirstOrder,
  isActivePendingFirstOrder,
  getPaymongoSecretKey,
  getPaymongoWebhookSecret,
  getPaymongoAuthHeader,
  setTestOverrides,
} = _testHelpers;

// =============================================================================
// In-Memory Firestore Mock for Full HTTP Endpoint Integration Testing
// =============================================================================
function createInMemoryFirestore(initialCollections = {}) {
  const store = new Map();

  for (const [colName, docs] of Object.entries(initialCollections)) {
    const colMap = new Map();
    for (const [docId, docData] of Object.entries(docs)) {
      colMap.set(docId, JSON.parse(JSON.stringify(docData)));
    }
    store.set(colName, colMap);
  }

  function getColMap(name) {
    if (!store.has(name)) {
      store.set(name, new Map());
    }
    return store.get(name);
  }

  function makeDocRef(colName, docId) {
    return {
      id: docId,
      path: `${colName}/${docId}`,
      async get() {
        const colMap = getColMap(colName);
        const exists = colMap.has(docId);
        const data = exists ? JSON.parse(JSON.stringify(colMap.get(docId))) : undefined;
        return {
          id: docId,
          exists,
          ref: makeDocRef(colName, docId),
          data: () => data,
        };
      },
      async set(newData, options = {}) {
        const colMap = getColMap(colName);
        if (options && options.merge && colMap.has(docId)) {
          colMap.set(docId, { ...colMap.get(docId), ...newData });
        } else {
          colMap.set(docId, { ...newData });
        }
      },
      async update(updates) {
        const colMap = getColMap(colName);
        if (!colMap.has(docId)) {
          throw new Error(`Document ${colName}/${docId} does not exist`);
        }
        colMap.set(docId, { ...colMap.get(docId), ...updates });
      },
    };
  }

  function makeQuery(colName, filters = [], limitCount = null) {
    return {
      where(field, op, value) {
        return makeQuery(colName, [...filters, { field, op, value }], limitCount);
      },
      limit(n) {
        return makeQuery(colName, filters, n);
      },
      async get() {
        const colMap = getColMap(colName);
        const matchedDocs = [];
        for (const [docId, rawData] of colMap.entries()) {
          const matchesAll = filters.every(({ field, op, value }) => {
            if (op === '==') return rawData[field] === value;
            return false;
          });
          if (matchesAll) {
            const copy = JSON.parse(JSON.stringify(rawData));
            matchedDocs.push({
              id: docId,
              exists: true,
              ref: makeDocRef(colName, docId),
              data: () => copy,
            });
          }
        }
        const sliced = limitCount ? matchedDocs.slice(0, limitCount) : matchedDocs;
        return {
          empty: sliced.length === 0,
          size: sliced.length,
          docs: sliced,
          forEach(cb) {
            sliced.forEach(cb);
          },
        };
      },
    };
  }

  return {
    collection(colName) {
      return {
        doc(docId) {
          return makeDocRef(colName, docId);
        },
        where(field, op, value) {
          return makeQuery(colName, [{ field, op, value }]);
        },
      };
    },
    async runTransaction(updateFn) {
      let writeStarted = false;
      const stagedOps = [];
      const tx = {
        async get(docRef) {
          if (writeStarted) {
            throw new Error(
              'Firestore transactions require all reads to be executed before all writes.'
            );
          }
          return docRef.get();
        },
        set(docRef, data, options) {
          writeStarted = true;
          stagedOps.push(() => docRef.set(data, options));
        },
        update(docRef, data) {
          writeStarted = true;
          stagedOps.push(() => docRef.update(data));
        },
      };
      const result = await updateFn(tx);
      for (const op of stagedOps) {
        await op();
      }
      return result;
    },
    _dump(colName, docId) {
      return getColMap(colName).get(docId);
    },
  };
}

// Helper to make HTTP requests against the local test server
function requestHttp(baseUrl, method, pathUrl, { headers = {}, body = null } = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(pathUrl, baseUrl);
    const payloadStr =
      body === null
        ? null
        : typeof body === 'string'
        ? body
        : JSON.stringify(body);

    const reqHeaders = { ...headers };
    if (payloadStr !== null && !reqHeaders['Content-Type']) {
      reqHeaders['Content-Type'] = 'application/json';
    }
    if (payloadStr !== null) {
      reqHeaders['Content-Length'] = Buffer.byteLength(payloadStr);
    }

    const req = http.request(
      {
        hostname: urlObj.hostname,
        port: urlObj.port,
        path: urlObj.pathname + urlObj.search,
        method,
        headers: reqHeaders,
      },
      (res) => {
        let raw = '';
        res.on('data', (chunk) => {
          raw += chunk;
        });
        res.on('end', () => {
          let json = null;
          try {
            json = raw ? JSON.parse(raw) : null;
          } catch (_) {}
          resolve({
            status: res.statusCode,
            headers: res.headers,
            raw,
            json,
          });
        });
      }
    );
    req.on('error', reject);
    if (payloadStr !== null) {
      req.write(payloadStr);
    }
    req.end();
  });
}

async function runTests() {
  console.log('Running Standalone PayMongo Backend Unit & Integration Suite...');

  // ---------------------------------------------------------------------------
  // 1. Unit Tests: Secret Isolation & Pure Helpers
  // ---------------------------------------------------------------------------
  delete process.env.PAYMONGO_SECRET_KEY;
  delete process.env.PAYMONGO_WEBHOOK_SECRET;
  assert.strictEqual(getPaymongoSecretKey(), '');
  assert.strictEqual(getPaymongoWebhookSecret(), '');
  assert.throws(() => getPaymongoAuthHeader(), /PAYMONGO_SECRET_KEY is not configured/);

  const testSecret = 'whsk_test_standalone_secret_999';
  const payload = JSON.stringify({ data: { id: 'evt_001', type: 'event' } });
  const nowSec = Math.floor(Date.now() / 1000);
  const validSig = crypto
    .createHmac('sha256', testSecret)
    .update(`${nowSec}.${payload}`)
    .digest('hex');

  assert.strictEqual(verifyPaymongoSignature(`t=${nowSec},te=${validSig}`, payload, ''), false);
  assert.strictEqual(verifyPaymongoSignature('', payload, testSecret), false);
  assert.strictEqual(
    verifyPaymongoSignature(`t=${nowSec},te=${validSig}`, payload, testSecret),
    true
  );
  console.log('✅ 1. Unit tests passed: Secret isolation & HMAC helper verified');

  // ---------------------------------------------------------------------------
  // 2. Start Live HTTP Express Server for End-to-End Integration Tests
  // ---------------------------------------------------------------------------
  process.env.PAYMONGO_SECRET_KEY = 'sk_test_mock_secret_key_for_unit_tests';
  process.env.PAYMONGO_WEBHOOK_SECRET = testSecret;

  const mockDb = createInMemoryFirestore({
    users: {
      cust_1: {
        id: 'cust_1',
        role: 'customer',
        first_order_gcash_completed: false,
      },
      cust_2: {
        id: 'cust_2',
        role: 'customer',
        first_order_gcash_completed: false,
      },
    },
    orders: {
      ord_lmb_1001: {
        id: 'ord_lmb_1001',
        order_number: 'LMB-1001',
        customer_id: 'cust_1',
        customer_name: 'Maria Santos',
        customer_phone: '09171234567',
        customer_email: 'maria@lambac.ph',
        status: 'pending',
        payment_method: 'GCash',
        payment_status: 'PENDING',
        total_amount: 360,
        items: [
          {
            product_id: 'prod_1',
            product_name: 'Benguet Single Origin',
            unit_price: 180,
            quantity: 2,
          },
        ],
      },
      ord_lmb_cancelled: {
        id: 'ord_lmb_cancelled',
        order_number: 'LMB-CANCELLED',
        customer_id: 'cust_1',
        status: 'cancelled',
        payment_method: 'GCash',
        payment_status: 'CANCELLED',
        total_amount: 180,
        items: [],
      },
      ord_lmb_expired: {
        id: 'ord_lmb_expired',
        order_number: 'LMB-EXPIRED',
        customer_id: 'cust_2',
        status: 'pending',
        payment_method: 'GCash',
        payment_status: 'PENDING',
        checkout_session_id: 'cs_expired_session_001',
        payment_reference: 'cs_expired_session_001',
        total_amount: 250,
        items: [{ product_name: 'Espresso Blend', unit_price: 250, quantity: 1 }],
      },
      ord_lmb_failed: {
        id: 'ord_lmb_failed',
        order_number: 'LMB-FAILED',
        customer_id: 'cust_2',
        status: 'pending',
        payment_method: 'GCash',
        payment_status: 'PENDING',
        checkout_session_id: 'cs_failed_session_001',
        payment_reference: 'cs_failed_session_001',
        total_amount: 250,
        items: [{ product_name: 'Espresso Blend', unit_price: 250, quantity: 1 }],
      },
    },
  });

  let paymongoCreateCount = 0;
  let forcePaymongoError = false;
  let sessionStateById = {
    cs_expired_session_001: {
      status: 'expired',
      checkout_url: 'https://checkout.paymongo.com/cs_expired_session_001',
      payments: [],
    },
    cs_failed_session_001: {
      status: 'active',
      checkout_url: 'https://checkout.paymongo.com/cs_failed_session_001',
      payments: [
        {
          id: 'pay_failed_001',
          attributes: {
            status: 'failed',
            failed_message: 'Insufficient GCash wallet balance',
          },
        },
      ],
    },
  };

  const mockAuthAdmin = {
    async verifyIdToken(token) {
      if (token === 'valid_token_cust_1') {
        return { uid: 'cust_1', email: 'maria@lambac.ph', name: 'Maria Santos' };
      }
      if (token === 'valid_token_cust_2') {
        return { uid: 'cust_2', email: 'juan@lambac.ph', name: 'Juan Dela Cruz' };
      }
      throw new Error('Firebase ID token has expired or is invalid.');
    },
  };

  const mockFetch = async (url, options = {}) => {
    const method = (options.method || 'GET').toUpperCase();
    if (method === 'POST' && url.endsWith('/checkout_sessions')) {
      if (forcePaymongoError) {
        return {
          ok: false,
          status: 400,
          async json() {
            return {
              errors: [{ detail: 'PayMongo gateway rejected checkout parameters.' }],
            };
          },
        };
      }
      paymongoCreateCount += 1;
      const bodyObj = JSON.parse(options.body);
      const newSessionId = `cs_live_test_${paymongoCreateCount}`;
      const newCheckoutUrl = `https://checkout.paymongo.com/${newSessionId}`;
      sessionStateById[newSessionId] = {
        status: 'active',
        checkout_url: newCheckoutUrl,
        payments: [],
        requestBody: bodyObj,
      };
      return {
        ok: true,
        status: 200,
        async json() {
          return {
            data: {
              id: newSessionId,
              attributes: {
                checkout_url: newCheckoutUrl,
                status: 'active',
                payments: [],
              },
            },
          };
        },
      };
    }

    if (method === 'GET' && url.includes('/checkout_sessions/')) {
      const sessionId = url.split('/checkout_sessions/')[1];
      const sessionState = sessionStateById[sessionId];
      if (!sessionState) {
        return {
          ok: false,
          status: 404,
          async json() {
            return { errors: [{ detail: 'Session not found' }] };
          },
        };
      }
      return {
        ok: true,
        status: 200,
        async json() {
          return {
            data: {
              id: sessionId,
              attributes: sessionState,
            },
          };
        },
      };
    }

    throw new Error(`Unexpected fetch URL: ${url}`);
  };

  setTestOverrides({
    firestoreDb: mockDb,
    authAdmin: mockAuthAdmin,
    fetchImpl: mockFetch,
  });

  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    // 2A. Health check & CORS OPTIONS Preflight
    const healthRes = await requestHttp(baseUrl, 'GET', '/api/health');
    assert.strictEqual(healthRes.status, 200);
    assert.strictEqual(healthRes.json.status, 'ok');
    assert.strictEqual(healthRes.json.paymongoSecretConfigured, true);
    assert.strictEqual(healthRes.json.webhookSecretConfigured, true);

    const preflightRes = await requestHttp(baseUrl, 'OPTIONS', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'authorization,content-type',
      },
    });
    assert.strictEqual(preflightRes.status, 204);
    assert.strictEqual(
      preflightRes.headers['access-control-allow-origin'],
      'http://localhost:64076'
    );
    assert.ok(preflightRes.headers['access-control-allow-methods'].includes('POST'));
    assert.ok(preflightRes.headers['access-control-allow-methods'].includes('OPTIONS'));
    assert.ok(preflightRes.headers['access-control-allow-headers'].toLowerCase().includes('authorization'));
    assert.ok(preflightRes.headers['access-control-allow-headers'].toLowerCase().includes('content-type'));

    // Deployed Web Origin preflight
    const prodPreflightRes = await requestHttp(baseUrl, 'OPTIONS', '/api/create-checkout-session', {
      headers: {
        Origin: 'https://lambac-coffee-roastery.web.app',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'authorization,content-type',
      },
    });
    assert.strictEqual(prodPreflightRes.status, 204);
    assert.strictEqual(
      prodPreflightRes.headers['access-control-allow-origin'],
      'https://lambac-coffee-roastery.web.app'
    );

    // Untrusted arbitrary origin must be rejected (no Access-Control-Allow-Origin header)
    const untrustedPreflightRes = await requestHttp(baseUrl, 'OPTIONS', '/api/create-checkout-session', {
      headers: {
        Origin: 'https://evil-attacker.example.com',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'authorization,content-type',
      },
    });
    assert.strictEqual(untrustedPreflightRes.status, 403);
    assert.strictEqual(untrustedPreflightRes.headers['access-control-allow-origin'], undefined);
    console.log('✅ 2. Health endpoint & strict allowlist CORS OPTIONS preflight verified');

    // 2B. Invalid Authentication Requests (Missing / Invalid Token) — must still include CORS header
    const noAuthRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: { Origin: 'http://localhost:64076' },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(noAuthRes.status, 401);
    assert.strictEqual(noAuthRes.headers['access-control-allow-origin'], 'http://localhost:64076');

    const badAuthRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        Authorization: 'Bearer invalid_token_xyz',
      },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(badAuthRes.status, 401);
    assert.strictEqual(badAuthRes.headers['access-control-allow-origin'], 'http://localhost:64076');
    console.log('✅ 3. Invalid authentication requests rejected with 401 and preserve CORS headers');

    // 2C. Invalid Order Requests (Missing orderId, Malformed JSON, Non-existent order, Wrong owner, Cancelled order)
    const missingOrderRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        Authorization: 'Bearer valid_token_cust_1',
      },
      body: {},
    });
    assert.strictEqual(missingOrderRes.status, 400);
    assert.strictEqual(missingOrderRes.headers['access-control-allow-origin'], 'http://localhost:64076');

    const malformedJsonRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        Authorization: 'Bearer valid_token_cust_1',
        'Content-Type': 'application/json',
      },
      body: '{bad_json:',
    });
    assert.strictEqual(malformedJsonRes.status, 400);
    assert.strictEqual(malformedJsonRes.json.error, 'InvalidJsonPayload');
    assert.strictEqual(malformedJsonRes.headers['access-control-allow-origin'], 'http://localhost:64076');

    const notFoundOrderRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        Authorization: 'Bearer valid_token_cust_1',
      },
      body: { orderId: 'ord_does_not_exist' },
    });
    assert.strictEqual(notFoundOrderRes.status, 404);
    assert.strictEqual(notFoundOrderRes.headers['access-control-allow-origin'], 'http://localhost:64076');

    const wrongOwnerRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        Authorization: 'Bearer valid_token_cust_2',
      },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(wrongOwnerRes.status, 403);
    assert.strictEqual(wrongOwnerRes.headers['access-control-allow-origin'], 'http://localhost:64076');

    const cancelledOrderRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        Authorization: 'Bearer valid_token_cust_1',
      },
      body: { orderId: 'ord_lmb_cancelled' },
    });
    assert.strictEqual(cancelledOrderRes.status, 400);
    assert.strictEqual(cancelledOrderRes.json.error, 'InvalidOrderStatus');
    assert.strictEqual(cancelledOrderRes.headers['access-control-allow-origin'], 'http://localhost:64076');

    // Backend unavailable / unconfigured secret 503 check with CORS header
    const savedSecret = process.env.PAYMONGO_SECRET_KEY;
    process.env.PAYMONGO_SECRET_KEY = '';
    const unconfiguredRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Origin: 'http://localhost:64076',
        Authorization: 'Bearer valid_token_cust_1',
      },
      body: { orderId: 'ord_lmb_1001' },
    });
    process.env.PAYMONGO_SECRET_KEY = savedSecret;
    assert.strictEqual(unconfiguredRes.status, 503);
    assert.strictEqual(unconfiguredRes.json.error, 'PaymongoNotConfigured');
    assert.strictEqual(unconfiguredRes.headers['access-control-allow-origin'], 'http://localhost:64076');
    console.log('✅ 4. Invalid order requests (400/403/404) & 503 unavailable error verified with CORS headers');

    // 2D. Failed Checkout Session Creation (PayMongo API error)
    forcePaymongoError = true;
    const failedCreateRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: { Authorization: 'Bearer valid_token_cust_1' },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(failedCreateRes.status, 400);
    assert.strictEqual(failedCreateRes.json.error, 'PaymongoError');
    forcePaymongoError = false;
    console.log('✅ 5. Failed PayMongo checkout session creation handled cleanly');

    // 2E. Successful Checkout Session Creation
    const createRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: {
        Authorization: 'Bearer valid_token_cust_1',
        Origin: 'http://localhost:64076',
      },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(createRes.status, 200);
    assert.strictEqual(createRes.json.success, true);
    assert.strictEqual(createRes.json.orderId, 'ord_lmb_1001');
    assert.strictEqual(createRes.json.checkoutSessionId, 'cs_live_test_1');
    assert.strictEqual(
      createRes.json.checkoutUrl,
      'https://checkout.paymongo.com/cs_live_test_1'
    );
    assert.strictEqual(createRes.json.amount, 360);
    assert.strictEqual(paymongoCreateCount, 1);

    // Verify Firestore order was updated with PENDING status and checkout URL
    const updatedOrderAfterCreate = mockDb._dump('orders', 'ord_lmb_1001');
    assert.strictEqual(updatedOrderAfterCreate.payment_status, 'PENDING');
    assert.strictEqual(updatedOrderAfterCreate.checkout_session_id, 'cs_live_test_1');
    assert.strictEqual(
      updatedOrderAfterCreate.checkout_url,
      'https://checkout.paymongo.com/cs_live_test_1'
    );
    console.log('✅ 6. Successful checkout session creation & server-side amount calculation verified');

    // 2F. Duplicate Checkout Request Idempotency (Reuses active session instead of creating a duplicate)
    const duplicateCreateRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: { Authorization: 'Bearer valid_token_cust_1' },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(duplicateCreateRes.status, 200);
    assert.strictEqual(duplicateCreateRes.json.checkoutSessionId, 'cs_live_test_1');
    assert.strictEqual(duplicateCreateRes.json.reusedExistingSession, true);
    assert.strictEqual(paymongoCreateCount, 1); // Did NOT call PayMongo POST again!
    console.log('✅ 7. Duplicate checkout request idempotently reused active session');

    // 2G. Verify Payment Session — Pending (Customer returned without paying yet)
    const verifyPendingRes = await requestHttp(baseUrl, 'POST', '/api/verify-payment-session', {
      headers: { Authorization: 'Bearer valid_token_cust_1' },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(verifyPendingRes.status, 200);
    assert.strictEqual(verifyPendingRes.json.paymentStatus, 'PENDING');
    assert.strictEqual(mockDb._dump('orders', 'ord_lmb_1001').payment_status, 'PENDING');
    console.log('✅ 8. Returning from checkout while still PENDING never marks order as PAID');

    // 2H. Payment Expiration & Payment Failure via /api/verify-payment-session
    const verifyExpiredRes = await requestHttp(baseUrl, 'POST', '/api/verify-payment-session', {
      headers: { Authorization: 'Bearer valid_token_cust_2' },
      body: { orderId: 'ord_lmb_expired' },
    });
    assert.strictEqual(verifyExpiredRes.status, 200);
    assert.strictEqual(verifyExpiredRes.json.paymentStatus, 'EXPIRED');
    assert.strictEqual(mockDb._dump('orders', 'ord_lmb_expired').payment_status, 'EXPIRED');
    assert.strictEqual(
      mockDb._dump('first_order_reservations', 'cust_2').status,
      'RELEASED_FOR_RETRY'
    );

    const verifyFailedRes = await requestHttp(baseUrl, 'POST', '/api/verify-payment-session', {
      headers: { Authorization: 'Bearer valid_token_cust_2' },
      body: { orderId: 'ord_lmb_failed' },
    });
    assert.strictEqual(verifyFailedRes.status, 200);
    assert.strictEqual(verifyFailedRes.json.paymentStatus, 'FAILED');
    assert.strictEqual(mockDb._dump('orders', 'ord_lmb_failed').payment_status, 'FAILED');
    console.log('✅ 9. Payment expiration & failure states verified and release first-order lock');

    // 2I. Webhook Verification: Invalid Signature, Valid Paid Webhook, and Duplicate Webhook Delivery
    const webhookEventPayload = JSON.stringify({
      data: {
        id: 'evt_paid_1001',
        attributes: {
          type: 'checkout_session.payment.paid',
          data: {
            id: 'cs_live_test_1',
            attributes: {
              metadata: {
                order_id: 'ord_lmb_1001',
                customer_id: 'cust_1',
              },
              payments: [
                {
                  id: 'pay_verified_999',
                  attributes: {
                    amount: 36000,
                    status: 'paid',
                  },
                },
              ],
            },
          },
        },
      },
    });

    // Invalid signature -> 400
    const badWebhookRes = await requestHttp(baseUrl, 'POST', '/api/paymongo-webhook', {
      headers: {
        'Paymongo-Signature': `t=${nowSec},te=0000000000000000000000000000000000000000000000000000000000000000`,
      },
      body: webhookEventPayload,
    });
    assert.strictEqual(badWebhookRes.status, 400);
    assert.strictEqual(mockDb._dump('orders', 'ord_lmb_1001').payment_status, 'PENDING');

    // Valid signature -> 200 & marks order PAID + completes first-order requirement
    const validWebhookSig = crypto
      .createHmac('sha256', testSecret)
      .update(`${nowSec}.${webhookEventPayload}`)
      .digest('hex');

    const goodWebhookRes = await requestHttp(baseUrl, 'POST', '/api/paymongo-webhook', {
      headers: {
        'Paymongo-Signature': `t=${nowSec},te=${validWebhookSig}`,
      },
      body: webhookEventPayload,
    });
    assert.strictEqual(goodWebhookRes.status, 200);
    assert.strictEqual(goodWebhookRes.json.received, true);
    assert.strictEqual(mockDb._dump('orders', 'ord_lmb_1001').payment_status, 'PAID');
    assert.strictEqual(mockDb._dump('orders', 'ord_lmb_1001').payment_reference, 'pay_verified_999');
    assert.strictEqual(mockDb._dump('users', 'cust_1').first_order_gcash_completed, true);
    assert.strictEqual(mockDb._dump('first_order_reservations', 'cust_1').status, 'COMPLETED');

    // Duplicate webhook delivery -> 200 with duplicate: true
    const dupWebhookRes = await requestHttp(baseUrl, 'POST', '/api/paymongo-webhook', {
      headers: {
        'Paymongo-Signature': `t=${nowSec},te=${validWebhookSig}`,
      },
      body: webhookEventPayload,
    });
    assert.strictEqual(dupWebhookRes.status, 200);
    assert.strictEqual(dupWebhookRes.json.duplicate, true);

    // Attempt to create checkout session on an already PAID order -> 400 OrderAlreadyPaid
    const paidOrderCreateRes = await requestHttp(baseUrl, 'POST', '/api/create-checkout-session', {
      headers: { Authorization: 'Bearer valid_token_cust_1' },
      body: { orderId: 'ord_lmb_1001' },
    });
    assert.strictEqual(paidOrderCreateRes.status, 400);
    assert.strictEqual(paidOrderCreateRes.json.error, 'OrderAlreadyPaid');
    console.log('✅ 10. Webhook verification, invalid signature rejection, and duplicate webhook idempotency verified');

    console.log('\n🎉 ALL 10 BACKEND UNIT & HTTP INTEGRATION TEST SUITES PASSED!');
  } finally {
    server.close();
    setTestOverrides({});
  }
}

runTests().catch((err) => {
  console.error('❌ Test suite failed:', err);
  process.exit(1);
});
