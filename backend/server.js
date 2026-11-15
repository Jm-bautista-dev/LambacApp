const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const admin = require('firebase-admin');

// =============================================================================
// 0. Dependency-Free .env File Loader (Loads backend/.env if present)
// =============================================================================
function loadEnvFileIfPresent(envFilePath) {
  try {
    if (!fs.existsSync(envFilePath)) return;
    const raw = fs.readFileSync(envFilePath, 'utf8');
    const lines = raw.split(/\r?\n/);
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx <= 0) continue;
      const key = trimmed.slice(0, eqIdx).trim();
      let val = trimmed.slice(eqIdx + 1).trim();
      if (
        (val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))
      ) {
        val = val.slice(1, -1);
      }
      if (key && process.env[key] === undefined) {
        process.env[key] = val;
      }
    }
  } catch (_) {
    // Ignore file read errors in restricted serverless environments
  }
}

loadEnvFileIfPresent(path.join(__dirname, '.env'));
loadEnvFileIfPresent(path.join(__dirname, '..', '.env'));

// =============================================================================
// 1. Firebase Admin SDK Initialization (Connects to Firebase Spark Auth & Firestore)
// =============================================================================
let firebaseCredentialsConfigured = false;

function hasFirebaseCredentials() {
  if (_testOverrides.firestoreDb) return true;
  const serviceAccountJson = (process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '').trim();
  const clientEmail = (process.env.FIREBASE_CLIENT_EMAIL || '').trim();
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').trim();
  const googleCredsPath = (process.env.GOOGLE_APPLICATION_CREDENTIALS || '').trim();
  return Boolean(
    serviceAccountJson.startsWith('{') ||
      (clientEmail && privateKey) ||
      (googleCredsPath && fs.existsSync(googleCredsPath))
  );
}

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const projectId = process.env.FIREBASE_PROJECT_ID || 'lambac-coffee-roastery';
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : undefined;

  if (serviceAccountJson && serviceAccountJson.trim().startsWith('{')) {
    const credentials = JSON.parse(serviceAccountJson);
    firebaseCredentialsConfigured = true;
    return admin.initializeApp({
      credential: admin.credential.cert(credentials),
      projectId: credentials.project_id || projectId,
    });
  }

  if (clientEmail && privateKey) {
    firebaseCredentialsConfigured = true;
    return admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
      projectId,
    });
  }

  if (
    process.env.GOOGLE_APPLICATION_CREDENTIALS &&
    fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)
  ) {
    firebaseCredentialsConfigured = true;
  }

  return admin.initializeApp({ projectId });
}

// Test overrides for full HTTP endpoint integration testing without live network calls
const _testOverrides = {
  firestoreDb: null,
  authAdmin: null,
  fetchImpl: null,
};

function setTestOverrides(overrides = {}) {
  _testOverrides.firestoreDb = overrides.firestoreDb || null;
  _testOverrides.authAdmin = overrides.authAdmin || null;
  _testOverrides.fetchImpl = overrides.fetchImpl || null;
}

initializeFirebaseAdmin();

function getFirestoreDb() {
  if (_testOverrides.firestoreDb) {
    return _testOverrides.firestoreDb;
  }
  return admin.firestore();
}

function getAuthAdmin() {
  if (_testOverrides.authAdmin) {
    return _testOverrides.authAdmin;
  }
  return admin.auth();
}

function getFetchImpl() {
  if (_testOverrides.fetchImpl) {
    return _testOverrides.fetchImpl;
  }
  return fetch;
}

// =============================================================================
// 2. Environment Variable Readers (Zero Hardcoded Secrets)
// =============================================================================
const PAYMONGO_API_BASE = 'https://api.paymongo.com/v1';

function getPaymongoSecretKey() {
  return (process.env.PAYMONGO_SECRET_KEY || '').trim();
}

function getPaymongoWebhookSecret() {
  return (process.env.PAYMONGO_WEBHOOK_SECRET || '').trim();
}

function getAppWebOrigin() {
  return (process.env.APP_WEB_ORIGIN || 'https://lambac-coffee-roastery.web.app').replace(/\/+$/, '');
}

const DEFAULT_ALLOWED_ORIGINS = [
  'http://localhost:64076',
  'http://127.0.0.1:64076',
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  'http://localhost:5000',
  'http://127.0.0.1:5000',
  'http://localhost:8080',
  'http://127.0.0.1:8080',
  'https://lambac-coffee-roastery.web.app',
  'https://lambac-coffee-roastery.firebaseapp.com',
];

const SAFE_LOCALHOST_ORIGIN_REGEX = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;

function normalizeOrigin(origin) {
  return String(origin || '').trim().replace(/\/+$/, '');
}

/**
 * Returns the explicit allowlist of configured CORS origins from CORS_ALLOWED_ORIGINS,
 * APP_WEB_ORIGIN, and default Lambac origins.
 */
function getAllowedCorsOrigins() {
  const configuredRaw = String(process.env.CORS_ALLOWED_ORIGINS || '').trim();
  const configuredList = configuredRaw
    ? configuredRaw
        .split(',')
        .map((o) => normalizeOrigin(o))
        .filter(Boolean)
    : [];

  const allowSet = new Set([
    ...DEFAULT_ALLOWED_ORIGINS.map(normalizeOrigin),
    normalizeOrigin(getAppWebOrigin()),
    ...configuredList,
  ]);
  allowSet.delete('');
  allowSet.delete('*'); // Never allow wildcard '*' with credentials
  return Array.from(allowSet);
}

/**
 * Strictly validates whether a request Origin header is permitted.
 * - Rejects wildcard or arbitrary external origins.
 * - Allows origins explicitly listed in CORS_ALLOWED_ORIGINS / defaults.
 * - Allows safe localhost/127.0.0.1 development origins unless CORS_ALLOW_LOCALHOST=false.
 */
function isOriginAllowed(origin) {
  const normalized = normalizeOrigin(origin);
  if (!normalized || normalized === 'null' || normalized === '*') {
    return false;
  }

  const allowedList = getAllowedCorsOrigins();
  if (allowedList.includes(normalized)) {
    return true;
  }

  const allowLocalhostDev =
    String(process.env.CORS_ALLOW_LOCALHOST || 'true').trim().toLowerCase() !== 'false';
  if (allowLocalhostDev && SAFE_LOCALHOST_ORIGIN_REGEX.test(normalized)) {
    return true;
  }

  return false;
}

const ALLOWED_CORS_METHODS = 'GET, POST, PUT, PATCH, DELETE, OPTIONS';
const ALLOWED_CORS_HEADERS =
  'Authorization, Content-Type, Accept, Origin, X-Requested-With, Paymongo-Signature';

/**
 * Applies explicit CORS headers to the response when the request Origin is in the allowlist.
 * Never emits '*' when credentials are enabled, and never reflects untrusted origins.
 */
function applyCorsHeaders(req, res) {
  if (!req || !res) return false;
  const rawOrigin = req.headers ? req.headers.origin : undefined;
  if (!rawOrigin) {
    return true;
  }

  const normalizedOrigin = normalizeOrigin(rawOrigin);
  if (!isOriginAllowed(normalizedOrigin)) {
    res.Vary = 'Origin';
    res.setHeader('Vary', 'Origin');
    return false;
  }

  res.setHeader('Access-Control-Allow-Origin', normalizedOrigin);
  res.setHeader('Vary', 'Origin');
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Methods', ALLOWED_CORS_METHODS);
  res.setHeader('Access-Control-Allow-Headers', ALLOWED_CORS_HEADERS);
  res.setHeader('Access-Control-Max-Age', '86400');
  return true;
}

/**
 * Generates Basic Auth header for PayMongo API using environment PAYMONGO_SECRET_KEY.
 * Throws if PAYMONGO_SECRET_KEY is not configured in environment variables.
 */
function getPaymongoAuthHeader() {
  const secretKey = getPaymongoSecretKey();
  if (!secretKey) {
    throw new Error('PAYMONGO_SECRET_KEY is not configured in backend environment variables.');
  }
  const token = Buffer.from(`${secretKey}:`).toString('base64');
  return `Basic ${token}`;
}

// =============================================================================
// 3. Pure Business Logic & Security Verification Helpers
// =============================================================================

/**
 * Pure helper: Determines whether an order document qualifies as a completed first order.
 *
 * Rules:
 * - Must NOT be cancelled or voided.
 * - Payment status MUST be verified 'PAID' (never PENDING, FAILED, EXPIRED, CANCELLED, or UNPAID).
 * - Must be a verified PayMongo GCash order OR a historical completed & paid order.
 */
function isQualifyingFirstOrder(order) {
  if (!order || typeof order !== 'object') return false;

  const status = String(order.status || '').trim().toLowerCase();
  if (status === 'cancelled' || status === 'canceled' || status === 'voided') {
    return false;
  }

  const paymentStatus = String(order.payment_status || order.paymentStatus || '').trim().toUpperCase();
  if (paymentStatus !== 'PAID') {
    return false;
  }

  const paymentMethod = String(order.payment_method || order.paymentMethod || '').trim().toLowerCase();
  const paymentProvider = String(order.payment_provider || order.paymentProvider || '').trim().toLowerCase();
  const hasVerifiedRef = Boolean(
    order.payment_reference ||
      order.paymentReference ||
      order.paid_at ||
      order.paidAt ||
      paymentProvider === 'paymongo'
  );

  // 1. Verified PayMongo GCash payment
  if (paymentMethod === 'gcash' && hasVerifiedRef) {
    return true;
  }

  // 2. Historical completed & paid order
  if (status === 'completed' && paymentStatus === 'PAID') {
    return true;
  }

  return false;
}

/**
 * Pure helper: Determines whether an order is currently an active, non-expired, non-failed
 * pending first-order GCash attempt.
 */
function isActivePendingFirstOrder(order) {
  if (!order || typeof order !== 'object') return false;

  const status = String(order.status || '').trim().toLowerCase();
  if (
    status === 'cancelled' ||
    status === 'canceled' ||
    status === 'voided' ||
    status === 'completed'
  ) {
    return false;
  }

  const paymentMethod = String(order.payment_method || order.paymentMethod || '').trim().toLowerCase();
  if (paymentMethod !== 'gcash') {
    return false;
  }

  const paymentStatus = String(order.payment_status || order.paymentStatus || '').trim().toUpperCase();
  return paymentStatus === 'PENDING';
}

/**
 * Authoritative Backend Lookup: Determines whether an authenticated customer (by UID)
 * has completed their first qualifying order or must use GCash via PayMongo.
 */
async function determineCustomerFirstOrderStatus(uid, firestoreDb = getFirestoreDb()) {
  if (!uid) {
    throw new Error('Customer UID is required to determine first-order eligibility.');
  }

  const [ordersBySnakeSnap, userSnap, reservationSnap] = await Promise.all([
    firestoreDb.collection('orders').where('customer_id', '==', uid).get(),
    firestoreDb.collection('users').doc(uid).get(),
    firestoreDb.collection('first_order_reservations').doc(uid).get(),
  ]);

  const ordersMap = new Map();
  ordersBySnakeSnap.forEach((doc) => {
    ordersMap.set(doc.id, { id: doc.id, ...doc.data() });
  });

  if (ordersMap.size === 0) {
    const ordersByCamelSnap = await firestoreDb
      .collection('orders')
      .where('customerId', '==', uid)
      .get();
    ordersByCamelSnap.forEach((doc) => {
      ordersMap.set(doc.id, { id: doc.id, ...doc.data() });
    });
  }

  let qualifyingOrderId = null;
  let activeFirstOrderId = null;

  for (const [docId, orderData] of ordersMap.entries()) {
    if (isQualifyingFirstOrder(orderData)) {
      qualifyingOrderId = docId;
      break;
    }
    if (!activeFirstOrderId && isActivePendingFirstOrder(orderData)) {
      activeFirstOrderId = docId;
    }
  }

  if (!qualifyingOrderId && !activeFirstOrderId && reservationSnap.exists) {
    const resData = reservationSnap.data() || {};
    if (resData.status === 'COMPLETED' && resData.completed_order_id) {
      qualifyingOrderId = resData.completed_order_id;
    } else if ((resData.status === 'ACTIVE' || resData.status === 'ACTIVE_PENDING') && resData.order_id) {
      const reservedOrder = ordersMap.get(resData.order_id);
      if (reservedOrder && isActivePendingFirstOrder(reservedOrder)) {
        activeFirstOrderId = resData.order_id;
      }
    }
  }

  if (!qualifyingOrderId && userSnap.exists) {
    const userData = userSnap.data() || {};
    if (
      userData.first_order_gcash_completed === true &&
      userData.first_order_completed_order_id
    ) {
      qualifyingOrderId = userData.first_order_completed_order_id;
    }
  }

  const hasCompletedFirstOrder = Boolean(qualifyingOrderId);
  const requiresFirstOrderGcash = !hasCompletedFirstOrder;

  return {
    customer_id: uid,
    customerId: uid,
    has_completed_first_order: hasCompletedFirstOrder,
    hasCompletedFirstOrder,
    requires_first_order_gcash: requiresFirstOrderGcash,
    requiresFirstOrderGcash,
    allowed_payment_methods: requiresFirstOrderGcash
      ? ['GCash']
      : ['GCash', 'Pay at Counter'],
    allowedPaymentMethods: requiresFirstOrderGcash
      ? ['GCash']
      : ['GCash', 'Pay at Counter'],
    active_first_order_id: activeFirstOrderId,
    activeFirstOrderId,
    qualifying_order_id: qualifyingOrderId,
    qualifyingOrderId,
    message: requiresFirstOrderGcash
      ? 'Your first order must be paid through GCash.'
      : 'First-order GCash requirement completed. All payment methods available.',
  };
}

/**
 * Verify Webhook Signature according to PayMongo official documentation.
 * Header: Paymongo-Signature
 * Value: t=1600000000,te=signature_for_test,li=signature_for_live
 *
 * SECURITY: Fails closed (returns false) if webhookSecret or signatureHeader is missing.
 */
function verifyPaymongoSignature(signatureHeader, rawBody, webhookSecret) {
  if (!webhookSecret || typeof webhookSecret !== 'string' || !webhookSecret.trim()) {
    console.error('[WEBHOOK] Rejecting request: PAYMONGO_WEBHOOK_SECRET is not configured.');
    return false;
  }

  if (!signatureHeader || typeof signatureHeader !== 'string') {
    console.error('[WEBHOOK] Rejecting request: Missing Paymongo-Signature header.');
    return false;
  }

  const parts = signatureHeader.split(',');
  const signatureMap = {};
  for (const part of parts) {
    const [key, val] = part.split('=');
    if (key && val) {
      signatureMap[key.trim()] = val.trim();
    }
  }

  const timestamp = signatureMap['t'];
  const testSignature = signatureMap['te'];
  const liveSignature = signatureMap['li'];

  if (!timestamp) {
    console.error('[WEBHOOK] Missing timestamp in Paymongo-Signature header.');
    return false;
  }

  // Prevent replay attacks (10-minute tolerance window)
  const currentTime = Math.floor(Date.now() / 1000);
  const parsedTimestamp = parseInt(timestamp, 10);
  if (isNaN(parsedTimestamp) || Math.abs(currentTime - parsedTimestamp) > 600) {
    console.error('[WEBHOOK] Webhook signature timestamp expired or invalid.');
    return false;
  }

  // Signed payload format: <timestamp>.<rawBody>
  const payloadToSign = `${timestamp}.${rawBody}`;
  const computedHmac = crypto
    .createHmac('sha256', webhookSecret.trim())
    .update(payloadToSign)
    .digest('hex');

  const expectedSig = testSignature || liveSignature;
  if (!expectedSig) {
    console.error('[WEBHOOK] No te or li signature found in header.');
    return false;
  }

  const computedBuf = Buffer.from(computedHmac, 'utf8');
  const expectedBuf = Buffer.from(expectedSig, 'utf8');
  if (computedBuf.length !== expectedBuf.length) {
    return false;
  }

  return crypto.timingSafeEqual(computedBuf, expectedBuf);
}

/**
 * Helper: Atomically records verified PayMongo GCash payment on the order,
 * marks the customer's first-order requirement as completed on /users/{uid},
 * and finalizes /first_order_reservations/{uid}.
 * Strictly follows Firestore transaction ordering (ALL READS BEFORE ALL WRITES).
 */
async function markOrderVerifiedPaidAtomically({
  orderRef,
  orderId,
  paymentId,
  checkoutSessionId,
  amountPhp,
  eventDocRef = null,
  eventPayload = null,
  firestoreDb = getFirestoreDb(),
}) {
  const now = new Date().toISOString();

  await firestoreDb.runTransaction(async (transaction) => {
    // PHASE A — READ ALL REQUIRED DOCUMENTS FIRST
    const freshOrderSnap = await transaction.get(orderRef);
    if (!freshOrderSnap.exists) return;

    const currentData = freshOrderSnap.data();
    const customerId = currentData.customer_id || currentData.customerId || currentData.userId;

    const userRef = customerId ? firestoreDb.collection('users').doc(customerId) : null;
    const reservationRef = customerId
      ? firestoreDb.collection('first_order_reservations').doc(customerId)
      : null;

    const userSnap = userRef ? await transaction.get(userRef) : null;
    const reservationSnap = reservationRef ? await transaction.get(reservationRef) : null;

    // PHASE B — VALIDATE
    const alreadyPaid = String(currentData.payment_status || '').toUpperCase() === 'PAID';

    // PHASE C — WRITE ALL DOCUMENTS ATOMICALLY
    if (!alreadyPaid) {
      transaction.update(orderRef, {
        payment_status: 'PAID',
        payment_method: 'GCash',
        payment_provider: 'PayMongo',
        payment_reference: paymentId,
        ...(checkoutSessionId ? { checkout_session_id: checkoutSessionId } : {}),
        ...(amountPhp ? { amount_paid: amountPhp } : {}),
        paid_at: now,
        payment_recorded_at: now,
        updated_at: now,
      });
    }

    if (userRef) {
      const existingUserData = userSnap && userSnap.exists ? userSnap.data() : {};
      if (!existingUserData.first_order_gcash_completed) {
        transaction.set(
          userRef,
          {
            first_order_gcash_completed: true,
            firstOrderGcashCompleted: true,
            first_order_completed_order_id: orderId,
            firstOrderCompletedOrderId: orderId,
            first_order_completed_at: now,
            firstOrderCompletedAt: now,
            updated_at: now,
          },
          { merge: true }
        );
      }
    }

    if (reservationRef) {
      const existingRes = reservationSnap && reservationSnap.exists ? reservationSnap.data() : {};
      if (existingRes.status !== 'COMPLETED') {
        transaction.set(
          reservationRef,
          {
            uid: customerId,
            customer_id: customerId,
            order_id: orderId,
            completed_order_id: orderId,
            status: 'COMPLETED',
            completed_at: now,
            updated_at: now,
          },
          { merge: true }
        );
      }
    }

    if (eventDocRef && eventPayload) {
      transaction.set(eventDocRef, eventPayload);
    }
  });
}

// =============================================================================
// 4. Express Application & Routes
// =============================================================================
const app = express();

// 4a. Centralized CORS & OPTIONS Preflight Middleware (Registered FIRST before all routes/parsers/auth)
const corsOptions = {
  origin(origin, callback) {
    // Non-browser requests (e.g. PayMongo webhooks, mobile apps, health checks without Origin)
    if (!origin) {
      return callback(null, true);
    }
    const normalized = normalizeOrigin(origin);
    if (isOriginAllowed(normalized)) {
      return callback(null, normalized);
    }
    return callback(null, false);
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: [
    'Authorization',
    'Content-Type',
    'Accept',
    'Origin',
    'X-Requested-With',
    'Paymongo-Signature',
  ],
  credentials: true,
  maxAge: 86400,
  optionsSuccessStatus: 204,
};

app.use((req, res, next) => {
  const originHeader = req.headers.origin;
  const allowed = applyCorsHeaders(req, res);

  if (req.method === 'OPTIONS') {
    if (originHeader && !allowed) {
      return res.status(403).json({
        error: 'CorsOriginDenied',
        message: 'Origin is not allowed by CORS policy.',
      });
    }
    return res.status(204).end();
  }

  if (originHeader && !allowed) {
    return res.status(403).json({
      error: 'CorsOriginDenied',
      message: 'Origin is not allowed by CORS policy.',
    });
  }

  return next();
});

app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

app.use(
  express.json({
    verify: (req, res, buf) => {
      req.rawBody = buf.toString('utf8');
    },
  })
);

/**
 * Helper to classify missing Firebase Admin credentials errors cleanly
 * while guaranteeing CORS headers on all error responses.
 */
function handleBackendError(res, err, contextLabel, req = null) {
  if (req) {
    applyCorsHeaders(req, res);
  }
  const msg = String(err && err.message ? err.message : err);
  console.error(`[${contextLabel}] Error:`, msg);
  if (msg.includes('Could not load the default credentials')) {
    return res.status(503).json({
      error: 'FirebaseCredentialsNotConfigured',
      message:
        'Firebase Admin credentials (FIREBASE_SERVICE_ACCOUNT_JSON) are not configured on the backend server.',
    });
  }
  return res.status(500).json({
    error: 'InternalServerError',
    message: 'An unexpected server error occurred while processing your payment request.',
  });
}

/**
 * Authentication Middleware: Verifies Firebase Auth ID Token against Firebase Spark project.
 * Explicitly allows legitimate OPTIONS preflight requests through without requiring Authorization.
 */
async function authenticateUser(req, res, next) {
  applyCorsHeaders(req, res);
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Missing or malformed Authorization header with Bearer token.',
    });
  }

  const idToken = authHeader.split('Bearer ')[1].trim();
  if (!idToken) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Missing Firebase authentication token.',
    });
  }

  try {
    const decodedToken = await getAuthAdmin().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (err) {
    console.error('[AUTH] Token verification failed:', err.message);
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired Firebase authentication token.',
    });
  }
}

// In-flight mutex to prevent duplicate concurrent checkout session creation for the same orderId
const activeCheckoutCreations = new Map();

const router = express.Router();

/**
 * GET /health
 * Reports service status and whether environment secrets are configured (never exposing values)
 */
router.get('/health', (req, res) => {
  applyCorsHeaders(req, res);
  res.status(200).json({
    status: 'ok',
    service: 'lambac-paymongo-standalone-backend',
    firebaseProject: process.env.FIREBASE_PROJECT_ID || 'lambac-coffee-roastery',
    firebaseInitialized: Boolean(admin.apps.length > 0),
    firebaseCredentialsConfigured: hasFirebaseCredentials(),
    paymongoSecretConfigured: Boolean(getPaymongoSecretKey()),
    webhookSecretConfigured: Boolean(getPaymongoWebhookSecret()),
    corsAllowedOrigins: getAllowedCorsOrigins(),
    timestamp: new Date().toISOString(),
  });
});

/**
 * GET & POST /first-order-eligibility
 */
router.get('/first-order-eligibility', authenticateUser, async (req, res) => {
  try {
    const eligibility = await determineCustomerFirstOrderStatus(req.user.uid, getFirestoreDb());
    return res.status(200).json(eligibility);
  } catch (err) {
    return handleBackendError(res, err, 'FIRST_ORDER', req);
  }
});

router.post('/first-order-eligibility', authenticateUser, async (req, res) => {
  try {
    const eligibility = await determineCustomerFirstOrderStatus(req.user.uid, getFirestoreDb());
    return res.status(200).json(eligibility);
  } catch (err) {
    return handleBackendError(res, err, 'FIRST_ORDER', req);
  }
});

/**
 * POST /validate-first-order
 */
router.post('/validate-first-order', authenticateUser, async (req, res) => {
  try {
    const db = getFirestoreDb();
    const userId = req.user.uid;
    const { paymentMethod, orderId, idempotencyKey } = req.body || {};
    const normalizedMethod = String(paymentMethod || '').trim().toLowerCase();

    const eligibility = await determineCustomerFirstOrderStatus(userId, db);

    if (eligibility.requiresFirstOrderGcash) {
      if (normalizedMethod !== 'gcash') {
        return res.status(403).json({
          error: 'FirstOrderGcashRequired',
          message:
            'Your first order must be paid through GCash. Pay at Counter is unavailable for your first order.',
          requiresFirstOrderGcash: true,
        });
      }

      const reservationRef = db.collection('first_order_reservations').doc(userId);
      const lockResult = await db.runTransaction(async (transaction) => {
        const resSnap = await transaction.get(reservationRef);
        let existingOrderSnap = null;
        const resData = resSnap.exists ? resSnap.data() : null;

        if (
          resData &&
          (resData.status === 'ACTIVE' || resData.status === 'ACTIVE_PENDING') &&
          resData.order_id &&
          resData.order_id !== orderId
        ) {
          const existingOrderRef = db.collection('orders').doc(resData.order_id);
          existingOrderSnap = await transaction.get(existingOrderRef);
        }

        if (resData && resData.status === 'COMPLETED') {
          return { allowed: true, alreadyCompleted: true };
        }

        if (existingOrderSnap && existingOrderSnap.exists) {
          const existingOrderData = existingOrderSnap.data();
          const sameIdempotency =
            idempotencyKey &&
            existingOrderData.idempotency_key &&
            existingOrderData.idempotency_key === idempotencyKey;

          if (!sameIdempotency && isActivePendingFirstOrder(existingOrderData)) {
            return {
              allowed: false,
              activeOrderId: resData.order_id,
              activeOrderNumber: existingOrderData.order_number || resData.order_id,
            };
          }
        }

        const now = new Date().toISOString();
        transaction.set(
          reservationRef,
          {
            uid: userId,
            customer_id: userId,
            order_id: orderId || resData?.order_id || 'pending_creation',
            idempotency_key: idempotencyKey || null,
            status: 'ACTIVE_PENDING',
            reserved_at: resData?.reserved_at || now,
            updated_at: now,
          },
          { merge: true }
        );

        return { allowed: true, alreadyCompleted: false };
      });

      if (!lockResult.allowed) {
        return res.status(409).json({
          error: 'SimultaneousFirstOrderBlocked',
          message: `You already have an active first-order GCash payment in progress (#${lockResult.activeOrderNumber}). Please complete or cancel that order before creating another.`,
          activeFirstOrderId: lockResult.activeOrderId,
        });
      }
    }

    return res.status(200).json({
      valid: true,
      requiresFirstOrderGcash: eligibility.requiresFirstOrderGcash,
      hasCompletedFirstOrder: eligibility.hasCompletedFirstOrder,
    });
  } catch (err) {
    return handleBackendError(res, err, 'FIRST_ORDER', req);
  }
});

/**
 * Resolve web return origin from request Origin header or APP_WEB_ORIGIN
 */
function resolveReturnOrigin(req) {
  const reqOrigin = String(req.headers.origin || '').trim().replace(/\/+$/, '');
  if (reqOrigin.startsWith('https://') || reqOrigin.startsWith('http://localhost') || reqOrigin.startsWith('http://127.0.0.1')) {
    return reqOrigin;
  }
  return getAppWebOrigin();
}

/**
 * POST /create-checkout-session
 */
router.post('/create-checkout-session', authenticateUser, async (req, res) => {
  try {
    if (!getPaymongoSecretKey()) {
      return res.status(503).json({
        error: 'PaymongoNotConfigured',
        message: 'PayMongo secret key is not configured on the backend server.',
      });
    }

    const db = getFirestoreDb();
    const { orderId, forceNew } = req.body || {};
    if (!orderId || typeof orderId !== 'string' || !orderId.trim()) {
      return res.status(400).json({
        error: 'ValidationFailure',
        message: 'orderId is required.',
      });
    }

    const trimmedOrderId = orderId.trim();
    const userId = req.user.uid;

    // 1. Authoritative Order Lookup from Firestore
    let orderDocRef = db.collection('orders').doc(trimmedOrderId);
    let orderSnap = await orderDocRef.get();

    if (!orderSnap.exists) {
      const qSnap = await db
        .collection('orders')
        .where('order_number', '==', trimmedOrderId)
        .limit(1)
        .get();
      if (!qSnap.empty) {
        orderSnap = qSnap.docs[0];
        orderDocRef = orderSnap.ref;
      }
    }

    if (!orderSnap.exists) {
      return res.status(404).json({
        error: 'NotFound',
        message: `Order '${trimmedOrderId}' not found.`,
      });
    }

    const order = orderSnap.data();
    const orderDocId = orderSnap.id;

    // 2. Access Control / Customer Ownership Verification
    const orderCustomerId = order.customer_id || order.customerId || order.userId;
    if (orderCustomerId !== userId) {
      const userDoc = await db.collection('users').doc(userId).get();
      const role = userDoc.exists ? userDoc.data().role || 'customer' : 'customer';
      if (role !== 'admin' && role !== 'staff' && role !== 'barista') {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'You can only create checkout sessions for your own orders.',
        });
      }
    }

    // 3. State Validation
    const paymentStatus = (order.payment_status || order.paymentStatus || 'UNPAID').toUpperCase();
    if (paymentStatus === 'PAID') {
      return res.status(400).json({
        error: 'OrderAlreadyPaid',
        message: 'This order has already been marked as PAID.',
        orderId: orderDocId,
        paymentStatus: 'PAID',
      });
    }

    const orderStatus = (order.status || 'pending').toLowerCase();
    if (orderStatus === 'cancelled' || orderStatus === 'completed') {
      return res.status(400).json({
        error: 'InvalidOrderStatus',
        message: `Cannot process payment for an order in '${orderStatus}' state.`,
      });
    }

    // 4. First-Order GCash Enforcement & Simultaneous Reservation Check
    const eligibility = await determineCustomerFirstOrderStatus(orderCustomerId, db);
    if (eligibility.requiresFirstOrderGcash) {
      const orderPaymentMethod = String(
        order.payment_method || order.paymentMethod || 'GCash'
      )
        .trim()
        .toLowerCase();
      if (orderPaymentMethod !== 'gcash') {
        return res.status(403).json({
          error: 'FirstOrderGcashRequired',
          message:
            'Your first order must be paid through GCash. Pay at Counter is not allowed for your first order.',
        });
      }

      const reservationRef = db.collection('first_order_reservations').doc(orderCustomerId);
      const reservationCheck = await db.runTransaction(async (transaction) => {
        const resSnap = await transaction.get(reservationRef);
        const resData = resSnap.exists ? resSnap.data() : null;
        let conflictingOrderSnap = null;

        if (
          resData &&
          (resData.status === 'ACTIVE' || resData.status === 'ACTIVE_PENDING') &&
          resData.order_id &&
          resData.order_id !== orderDocId
        ) {
          conflictingOrderSnap = await transaction.get(
            db.collection('orders').doc(resData.order_id)
          );
        }

        if (conflictingOrderSnap && conflictingOrderSnap.exists) {
          const conflictingOrder = conflictingOrderSnap.data();
          if (isActivePendingFirstOrder(conflictingOrder)) {
            return {
              blocked: true,
              activeOrderId: resData.order_id,
              activeOrderNumber: conflictingOrder.order_number || resData.order_id,
            };
          }
        }

        const now = new Date().toISOString();
        transaction.set(
          reservationRef,
          {
            uid: orderCustomerId,
            customer_id: orderCustomerId,
            order_id: orderDocId,
            order_number: order.order_number || orderDocId,
            status: 'ACTIVE_PENDING',
            reserved_at: resData?.reserved_at || now,
            updated_at: now,
          },
          { merge: true }
        );

        return { blocked: false };
      });

      if (reservationCheck.blocked) {
        return res.status(409).json({
          error: 'SimultaneousFirstOrderBlocked',
          message: `Multiple simultaneous first-order checkout sessions are not allowed. Please complete or cancel your active first-order payment (#${reservationCheck.activeOrderNumber}).`,
          activeFirstOrderId: reservationCheck.activeOrderId,
        });
      }
    }

    // 5. Authoritative Server-Side Amount & Currency Calculation
    const rawItems = Array.isArray(order.items) ? order.items : [];
    const computedItemsTotal = rawItems.reduce((acc, item) => {
      const unitPrice = parseFloat(item.unit_price || item.unitPrice || item.price || 0);
      const qty = parseInt(item.quantity || 1, 10);
      if (isNaN(unitPrice) || unitPrice <= 0 || isNaN(qty) || qty <= 0) return acc;
      return acc + unitPrice * qty;
    }, 0);

    const storedTotal = parseFloat(order.total_amount || order.totalAmount || order.total || 0);
    const totalAmount = computedItemsTotal > 0 ? computedItemsTotal : storedTotal;
    if (isNaN(totalAmount) || totalAmount <= 0) {
      return res.status(400).json({
        error: 'InvalidAmount',
        message: `Order total amount (₱${totalAmount}) is invalid.`,
      });
    }

    const amountInCentavos = Math.round(totalAmount * 100);
    const fetchFn = getFetchImpl();

    // 5b. Duplicate Checkout Protection: If an in-flight creation for this order is already running, await it
    if (activeCheckoutCreations.has(orderDocId)) {
      const inFlightResult = await activeCheckoutCreations.get(orderDocId);
      return res.status(200).json({ ...inFlightResult, reusedExistingSession: true });
    }

    // 5c. Existing Active Checkout Session Reuse & Paid Detection
    const existingSessionId = order.checkout_session_id || order.payment_reference;
    if (
      existingSessionId &&
      String(existingSessionId).startsWith('cs_') &&
      forceNew !== true &&
      paymentStatus === 'PENDING'
    ) {
      try {
        const existingRes = await fetchFn(
          `${PAYMONGO_API_BASE}/checkout_sessions/${existingSessionId}`,
          {
            method: 'GET',
            headers: {
              Authorization: getPaymongoAuthHeader(),
              Accept: 'application/json',
            },
          }
        );

        if (existingRes.ok) {
          const existingJson = await existingRes.json();
          const existingAttr = existingJson?.data?.attributes || {};
          const existingStatus = String(existingAttr.status || '').toLowerCase();
          const existingPayments = Array.isArray(existingAttr.payments)
            ? existingAttr.payments
            : [];
          const paidPayment = existingPayments.find(
            (p) => p?.attributes?.status === 'paid'
          );

          if (existingStatus === 'paid' || paidPayment) {
            await markOrderVerifiedPaidAtomically({
              orderRef: orderDocRef,
              orderId: orderDocId,
              paymentId: paidPayment ? paidPayment.id : existingSessionId,
              checkoutSessionId: existingSessionId,
              amountPhp: totalAmount,
              firestoreDb: db,
            });
            return res.status(400).json({
              error: 'OrderAlreadyPaid',
              message: 'This order has already been paid and verified via GCash.',
              orderId: orderDocId,
              paymentStatus: 'PAID',
            });
          }

          const existingCheckoutUrl = existingAttr.checkout_url || order.checkout_url;
          if (
            existingStatus === 'active' &&
            existingCheckoutUrl &&
            String(existingCheckoutUrl).startsWith('https://')
          ) {
            return res.status(200).json({
              success: true,
              orderId: orderDocId,
              orderNumber: order.order_number || orderDocId,
              checkoutSessionId: existingSessionId,
              checkoutUrl: existingCheckoutUrl,
              amount: totalAmount,
              currency: 'PHP',
              paymentMethod: 'GCash',
              isFirstOrder: eligibility.requiresFirstOrderGcash,
              reusedExistingSession: true,
            });
          }
        }
      } catch (_) {
        // Proceed to create a fresh session if lookup of previous session failed
      }
    }

    // 6. Line Items Generation
    let lineItems = [];

    if (rawItems.length > 0) {
      lineItems = rawItems.map((item) => {
        const itemPrice = parseFloat(item.unit_price || item.unitPrice || item.price || 0);
        const itemQuantity = parseInt(item.quantity || 1, 10);
        const itemName = item.product_name || item.productName || item.name || 'Roastery Item';
        const sizeDesc = item.size ? ` [Size: ${item.size}]` : '';
        const grindDesc = item.grind ? ` [Grind: ${item.grind}]` : '';

        return {
          currency: 'PHP',
          amount: Math.round(itemPrice * 100),
          name: `${itemName}${sizeDesc}${grindDesc}`,
          quantity: itemQuantity,
        };
      });

      const lineItemSum = lineItems.reduce((acc, curr) => acc + curr.amount * curr.quantity, 0);
      if (lineItemSum !== amountInCentavos) {
        lineItems = [
          {
            currency: 'PHP',
            amount: amountInCentavos,
            name: `Order #${order.order_number || orderDocId} (Pickup)`,
            quantity: 1,
          },
        ];
      }
    } else {
      lineItems = [
        {
          currency: 'PHP',
          amount: amountInCentavos,
          name: `Order #${order.order_number || orderDocId} (Pickup)`,
          quantity: 1,
        },
      ];
    }

    const customerName =
      order.customer_name || order.customerName || req.user.name || 'Customer';
    const customerPhone = order.customer_phone || order.customerPhone || '09171234567';
    const customerEmail =
      order.customer_email || order.customerEmail || req.user.email || 'customer@lambac.ph';

    const webOrigin = resolveReturnOrigin(req);
    const successUrl = `${webOrigin}/#/order-confirmation?orderId=${orderDocId}&payment=success`;
    const cancelUrl = `${webOrigin}/#/order-detail/${orderDocId}?payment=cancelled`;

    const sessionPayload = {
      data: {
        attributes: {
          billing: {
            name: customerName,
            email: customerEmail,
            phone: customerPhone,
          },
          send_email_receipt: false,
          show_description: true,
          show_line_items: true,
          line_items: lineItems,
          payment_method_types: ['gcash'],
          description: `Lambac Coffee Roastery Order #${order.order_number || orderDocId}`,
          success_url: successUrl,
          cancel_url: cancelUrl,
          metadata: {
            order_id: orderDocId,
            order_number: order.order_number || orderDocId,
            customer_id: orderCustomerId,
            is_first_order: String(eligibility.requiresFirstOrderGcash),
          },
        },
      },
    };

    const creationPromise = (async () => {
      const response = await fetchFn(`${PAYMONGO_API_BASE}/checkout_sessions`, {
        method: 'POST',
        headers: {
          Authorization: getPaymongoAuthHeader(),
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify(sessionPayload),
      });

      const responseData = await response.json();

      if (!response.ok) {
        const firstDetail =
          Array.isArray(responseData?.errors) && responseData.errors[0]?.detail
            ? responseData.errors[0].detail
            : 'Unable to create PayMongo GCash checkout session.';
        const err = new Error(firstDetail);
        err.statusCode = response.status;
        err.errorCode = 'PaymongoError';
        throw err;
      }

      const checkoutSession = responseData?.data;
      const checkoutUrl = checkoutSession?.attributes?.checkout_url;
      const checkoutSessionId = checkoutSession?.id;

      if (
        !checkoutSessionId ||
        !checkoutUrl ||
        typeof checkoutUrl !== 'string' ||
        !checkoutUrl.startsWith('https://')
      ) {
        const err = new Error('PayMongo returned an invalid or missing checkout URL.');
        err.statusCode = 502;
        err.errorCode = 'InvalidCheckoutUrl';
        throw err;
      }

      await orderDocRef.update({
        payment_method: 'GCash',
        payment_provider: 'PayMongo',
        payment_status: 'PENDING',
        checkout_session_id: checkoutSessionId,
        payment_reference: checkoutSessionId,
        checkout_url: checkoutUrl,
        is_first_order_gcash: eligibility.requiresFirstOrderGcash,
        checkout_created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: new Date().toISOString(),
      });

      return {
        success: true,
        orderId: orderDocId,
        orderNumber: order.order_number || orderDocId,
        checkoutSessionId,
        checkoutUrl,
        amount: totalAmount,
        currency: 'PHP',
        paymentMethod: 'GCash',
        isFirstOrder: eligibility.requiresFirstOrderGcash,
      };
    })();

    activeCheckoutCreations.set(orderDocId, creationPromise);
    try {
      const resultPayload = await creationPromise;
      return res.status(200).json(resultPayload);
    } finally {
      activeCheckoutCreations.delete(orderDocId);
    }
  } catch (err) {
    applyCorsHeaders(req, res);
    if (err && err.statusCode) {
      return res.status(err.statusCode).json({
        error: err.errorCode || 'PaymongoError',
        message: err.message,
      });
    }
    return handleBackendError(res, err, 'PAYMONGO_CREATE', req);
  }
});

/**
 * POST /verify-payment-session
 */
router.post('/verify-payment-session', authenticateUser, async (req, res) => {
  try {
    if (!getPaymongoSecretKey()) {
      return res.status(503).json({
        error: 'PaymongoNotConfigured',
        message: 'PayMongo secret key is not configured on the backend server.',
      });
    }

    const db = getFirestoreDb();
    const { orderId, checkoutSessionId } = req.body || {};
    if (!orderId || typeof orderId !== 'string' || !orderId.trim()) {
      return res.status(400).json({
        error: 'ValidationFailure',
        message: 'orderId is required.',
      });
    }

    const orderDocRef = db.collection('orders').doc(orderId.trim());
    const orderSnap = await orderDocRef.get();
    if (!orderSnap.exists) {
      return res.status(404).json({
        error: 'NotFound',
        message: 'Order not found.',
      });
    }

    const order = orderSnap.data();
    const orderCustomerId = order.customer_id || order.customerId || order.userId;
    if (orderCustomerId !== req.user.uid) {
      const userDoc = await db.collection('users').doc(req.user.uid).get();
      const role = userDoc.exists ? userDoc.data().role || 'customer' : 'customer';
      if (role !== 'admin' && role !== 'staff' && role !== 'barista') {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'You can only verify payment status for your own orders.',
        });
      }
    }

    // If already verified PAID in Firestore, return immediately
    if (String(order.payment_status || '').toUpperCase() === 'PAID') {
      return res.json({
        success: true,
        orderId: orderSnap.id,
        paymentStatus: 'PAID',
        paymentReference: order.payment_reference || order.checkout_session_id,
        sessionStatus: 'paid',
        firstOrderCompleted: true,
      });
    }

    const sessionId = checkoutSessionId || order.checkout_session_id || order.payment_reference;
    if (!sessionId) {
      return res.status(400).json({
        error: 'MissingCheckoutSession',
        message: 'No active GCash checkout session found for this order.',
      });
    }

    const fetchFn = getFetchImpl();
    const response = await fetchFn(`${PAYMONGO_API_BASE}/checkout_sessions/${sessionId}`, {
      method: 'GET',
      headers: {
        Authorization: getPaymongoAuthHeader(),
        Accept: 'application/json',
      },
    });

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'PaymongoLookupFailed',
        message: 'Unable to retrieve payment status from PayMongo.',
      });
    }

    const sessionData = await response.json();
    const attributes = sessionData?.data?.attributes || {};
    const sessionStatus = String(attributes.status || '').toLowerCase();
    const payments = Array.isArray(attributes.payments) ? attributes.payments : [];

    let isPaid = sessionStatus === 'paid';
    let isFailed = false;
    let failureMessage = null;
    let paymentRef = null;
    let amountPhp = order.total_amount;

    if (payments.length > 0) {
      const lastPayment = payments[payments.length - 1];
      const lastStatus = String(lastPayment?.attributes?.status || '').toLowerCase();
      if (lastStatus === 'paid') {
        isPaid = true;
        paymentRef = lastPayment.id;
        if (lastPayment.attributes.amount) {
          amountPhp = lastPayment.attributes.amount / 100;
        }
      } else if (lastStatus === 'failed') {
        isFailed = true;
        failureMessage =
          lastPayment.attributes?.failed_message || 'GCash payment failed.';
      }
    }

    if (isPaid) {
      await markOrderVerifiedPaidAtomically({
        orderRef: orderDocRef,
        orderId: orderSnap.id,
        paymentId: paymentRef || sessionId,
        checkoutSessionId: sessionId,
        amountPhp,
        firestoreDb: db,
      });

      return res.json({
        success: true,
        orderId: orderSnap.id,
        paymentStatus: 'PAID',
        paymentReference: paymentRef || sessionId,
        sessionStatus,
        firstOrderCompleted: true,
      });
    }

    if (sessionStatus === 'expired') {
      const now = new Date().toISOString();
      await orderDocRef.update({
        payment_status: 'EXPIRED',
        updated_at: now,
      });
      if (orderCustomerId) {
        await db.collection('first_order_reservations').doc(orderCustomerId).set(
          {
            uid: orderCustomerId,
            customer_id: orderCustomerId,
            order_id: orderSnap.id,
            status: 'RELEASED_FOR_RETRY',
            updated_at: now,
          },
          { merge: true }
        );
      }
      return res.json({
        success: true,
        orderId: orderSnap.id,
        paymentStatus: 'EXPIRED',
        sessionStatus,
      });
    }

    if (isFailed) {
      const now = new Date().toISOString();
      await orderDocRef.update({
        payment_status: 'FAILED',
        payment_failure_reason: failureMessage,
        updated_at: now,
      });
      if (orderCustomerId) {
        await db.collection('first_order_reservations').doc(orderCustomerId).set(
          {
            uid: orderCustomerId,
            customer_id: orderCustomerId,
            order_id: orderSnap.id,
            status: 'RELEASED_FOR_RETRY',
            failure_reason: failureMessage,
            updated_at: now,
          },
          { merge: true }
        );
      }
      return res.json({
        success: true,
        orderId: orderSnap.id,
        paymentStatus: 'FAILED',
        failureReason: failureMessage,
        sessionStatus,
      });
    }

    return res.json({
      success: true,
      orderId: orderSnap.id,
      paymentStatus: order.payment_status || 'PENDING',
      sessionStatus,
    });
  } catch (err) {
    return handleBackendError(res, err, 'VERIFY', req);
  }
});

/**
 * POST /paymongo-webhook
 * Official PayMongo Webhook Endpoint with strict fail-closed HMAC signature verification
 */
router.post('/paymongo-webhook', async (req, res) => {
  const signatureHeader =
    req.headers['paymongo-signature'] || req.headers['Paymongo-Signature'];
  const rawBody = req.rawBody || JSON.stringify(req.body);
  const webhookSecret = getPaymongoWebhookSecret();

  // 1. Strict Fail-Closed Webhook Signature Verification
  const isValidSignature = verifyPaymongoSignature(signatureHeader, rawBody, webhookSecret);
  if (!isValidSignature) {
    return res.status(400).json({
      error: 'InvalidSignature',
      message: 'Webhook signature verification failed.',
    });
  }

  try {
    const db = getFirestoreDb();
    const event = req.body.data;
    if (!event || !event.attributes) {
      return res.status(400).json({ error: 'MalformedPayload' });
    }

    const eventId = event.id;
    const eventType = event.attributes.type;

    // 2. Idempotency Check (/payment_webhook_events/{eventId})
    const eventDocRef = db.collection('payment_webhook_events').doc(eventId);
    const existingEvent = await eventDocRef.get();
    if (existingEvent.exists) {
      return res.status(200).json({ received: true, duplicate: true });
    }

    // 3. Process Event Types
    if (eventType === 'checkout_session.payment.paid') {
      const checkoutSessionData = event.attributes.data;
      const sessionAttributes = checkoutSessionData.attributes || {};
      const metadata = sessionAttributes.metadata || {};
      const orderId = metadata.order_id || metadata.orderId;

      if (!orderId) {
        await eventDocRef.set({
          event_id: eventId,
          type: eventType,
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
          status: 'skipped_no_order_id',
        });
        return res.status(200).json({ received: true });
      }

      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        return res.status(200).json({ received: true, warning: 'Order not found' });
      }

      const order = orderSnap.data();
      const payments = sessionAttributes.payments || [];
      const primaryPayment = payments.length > 0 ? payments[0] : null;
      const paymentId = primaryPayment ? primaryPayment.id : checkoutSessionData.id;
      const amountCentavos = primaryPayment ? primaryPayment.attributes?.amount : null;
      const amountPhp = amountCentavos ? amountCentavos / 100 : order.total_amount;

      await markOrderVerifiedPaidAtomically({
        orderRef,
        orderId,
        paymentId,
        checkoutSessionId: checkoutSessionData.id,
        amountPhp,
        eventDocRef,
        eventPayload: {
          event_id: eventId,
          event_type: eventType,
          order_id: orderId,
          order_number: order.order_number || '',
          payment_id: paymentId,
          amount: amountPhp,
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
          status: 'success',
        },
        firestoreDb: db,
      });
    } else if (eventType === 'payment.paid') {
      const paymentData = event.attributes.data;
      const paymentAttributes = paymentData.attributes || {};
      const metadata = paymentAttributes.metadata || {};
      const orderId = metadata.order_id || metadata.orderId;

      if (orderId) {
        const orderRef = db.collection('orders').doc(orderId);
        const amountPhp = (paymentAttributes.amount || 0) / 100;

        await markOrderVerifiedPaidAtomically({
          orderRef,
          orderId,
          paymentId: paymentData.id,
          checkoutSessionId: null,
          amountPhp,
          eventDocRef,
          eventPayload: {
            event_id: eventId,
            event_type: eventType,
            order_id: orderId,
            payment_id: paymentData.id,
            amount: amountPhp,
            processed_at: admin.firestore.FieldValue.serverTimestamp(),
            status: 'success',
          },
          firestoreDb: db,
        });
      }
    } else if (eventType === 'payment.failed') {
      const paymentData = event.attributes.data;
      const metadata = paymentData.attributes?.metadata || {};
      const orderId = metadata.order_id || metadata.orderId;
      const customerId = metadata.customer_id || metadata.customerId;
      const now = new Date().toISOString();

      if (orderId) {
        const orderRef = db.collection('orders').doc(orderId);
        const orderSnap = await orderRef.get();
        const resolvedCustomerId =
          customerId || (orderSnap.exists ? orderSnap.data().customer_id : null);

        if (orderSnap.exists && String(orderSnap.data().payment_status || '').toUpperCase() !== 'PAID') {
          await orderRef.update({
            payment_status: 'FAILED',
            payment_failure_reason:
              paymentData.attributes?.failed_message || 'Payment failed via GCash',
            updated_at: now,
          });

          if (resolvedCustomerId) {
            await db.collection('first_order_reservations').doc(resolvedCustomerId).set(
              {
                uid: resolvedCustomerId,
                customer_id: resolvedCustomerId,
                order_id: orderId,
                status: 'RELEASED_FOR_RETRY',
                failure_reason:
                  paymentData.attributes?.failed_message || 'Payment failed via GCash',
                updated_at: now,
              },
              { merge: true }
            );
          }
        }
      }

      await eventDocRef.set({
        event_id: eventId,
        event_type: eventType,
        order_id: orderId || null,
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
        status: 'payment_failed',
      });
    } else if (eventType === 'checkout_session.expired') {
      const sessionData = event.attributes.data;
      const metadata = sessionData.attributes?.metadata || {};
      const orderId = metadata.order_id || metadata.orderId;
      const customerId = metadata.customer_id || metadata.customerId;
      const now = new Date().toISOString();

      if (orderId) {
        const orderRef = db.collection('orders').doc(orderId);
        const orderSnap = await orderRef.get();
        if (orderSnap.exists && String(orderSnap.data().payment_status || '').toUpperCase() !== 'PAID') {
          const resolvedCustomerId = customerId || orderSnap.data().customer_id;
          await orderRef.update({
            payment_status: 'EXPIRED',
            updated_at: now,
          });

          if (resolvedCustomerId) {
            await db.collection('first_order_reservations').doc(resolvedCustomerId).set(
              {
                uid: resolvedCustomerId,
                customer_id: resolvedCustomerId,
                order_id: orderId,
                status: 'RELEASED_FOR_RETRY',
                updated_at: now,
              },
              { merge: true }
            );
          }
        }
      }

      await eventDocRef.set({
        event_id: eventId,
        event_type: eventType,
        order_id: orderId || null,
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
        status: 'session_expired',
      });
    }

    return res.status(200).json({ received: true, eventId });
  } catch (err) {
    return handleBackendError(res, err, 'WEBHOOK', req);
  }
});

// Mount router at both /api and / so either base URL convention works seamlessly
app.use('/api', router);
app.use('/', router);

// 4b. Unknown Route 404 Handler with Guaranteed CORS Headers
app.use((req, res) => {
  applyCorsHeaders(req, res);
  return res.status(404).json({
    error: 'NotFound',
    message: `Route ${req.method} ${req.originalUrl} not found on Lambac PayMongo backend.`,
  });
});

// 4c. Centralized Express Error Middleware (Catches malformed JSON SyntaxError & unexpected middleware failures with CORS headers)
app.use((err, req, res, _next) => {
  applyCorsHeaders(req, res);
  if (err && (err.type === 'entity.parse.failed' || err instanceof SyntaxError)) {
    return res.status(400).json({
      error: 'InvalidJsonPayload',
      message: 'Malformed JSON request body.',
    });
  }
  return handleBackendError(res, err, 'EXPRESS_MIDDLEWARE', req);
});

if (require.main === module) {
  const port = parseInt(process.env.PORT || '3000', 10);
  app.listen(port, () => {
    console.log(`[LAMBAC BACKEND] Standalone PayMongo server listening on port ${port}`);
  });
}

module.exports = {
  app,
  _testHelpers: {
    verifyPaymongoSignature,
    isQualifyingFirstOrder,
    isActivePendingFirstOrder,
    determineCustomerFirstOrderStatus,
    getPaymongoSecretKey,
    getPaymongoWebhookSecret,
    getPaymongoAuthHeader,
    getAllowedCorsOrigins,
    isOriginAllowed,
    applyCorsHeaders,
    authenticateUser,
    setTestOverrides,
  },
};

