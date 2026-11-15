const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const crypto = require('crypto');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

// PayMongo Test / Live Configuration
// Read strictly from environment variables (never hardcode secret keys in source code)
const PAYMONGO_SECRET_KEY = process.env.PAYMONGO_SECRET_KEY || '';
const PAYMONGO_PUBLIC_KEY = process.env.PAYMONGO_PUBLIC_KEY || '';
const PAYMONGO_WEBHOOK_SECRET = process.env.PAYMONGO_WEBHOOK_SECRET || '';

const PAYMONGO_API_BASE = 'https://api.paymongo.com/v1';

/**
 * Helper to generate Basic Auth header for PayMongo
 */
function getPaymongoAuthHeader() {
  const token = Buffer.from(`${PAYMONGO_SECRET_KEY}:`).toString('base64');
  return `Basic ${token}`;
}

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
  if (status !== 'pending' && status !== 'confirmed') {
    return false;
  }

  const paymentMethod = String(order.payment_method || order.paymentMethod || '').trim().toLowerCase();
  if (paymentMethod !== 'gcash') {
    return false;
  }

  const paymentStatus = String(order.payment_status || order.paymentStatus || '').trim().toUpperCase();
  // Only PENDING is considered an active attempt; FAILED, EXPIRED, CANCELLED release the lock
  return paymentStatus === 'PENDING';
}

/**
 * Authoritative Backend Lookup: Determines whether an authenticated customer (by UID)
 * has completed their first qualifying order or must use GCash via PayMongo.
 */
async function determineCustomerFirstOrderStatus(uid, firestoreDb = db) {
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

  // Also check camelCase customerId if needed
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

  // Check reservation document if activeFirstOrderId was not found in query
  if (!qualifyingOrderId && !activeFirstOrderId && reservationSnap.exists) {
    const resData = reservationSnap.data() || {};
    if (resData.status === 'COMPLETED' && resData.completed_order_id) {
      qualifyingOrderId = resData.completed_order_id;
    } else if (resData.status === 'ACTIVE' && resData.order_id) {
      const reservedOrder = ordersMap.get(resData.order_id);
      if (reservedOrder && isActivePendingFirstOrder(reservedOrder)) {
        activeFirstOrderId = resData.order_id;
      }
    }
  }

  // Check server-authoritative user flag if orders collection had a verified completion recorded
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
 * Verify Webhook Signature according to PayMongo official documentation
 * Header: Paymongo-Signature
 * Value: t=1600000000,te=signature_for_test,li=signature_for_live
 */
function verifyPaymongoSignature(signatureHeader, rawBody, webhookSecret) {
  if (!webhookSecret || !String(webhookSecret).trim()) {
    console.error('[WEBHOOK] PAYMONGO_WEBHOOK_SECRET is not configured. Rejecting webhook request.');
    return false;
  }

  if (!signatureHeader) {
    console.error('[WEBHOOK] Missing Paymongo-Signature header.');
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
    console.error('[WEBHOOK] Missing timestamp in signature header.');
    return false;
  }

  // Prevent replay attacks (allow up to 10 minutes tolerance)
  const currentTime = Math.floor(Date.now() / 1000);
  if (Math.abs(currentTime - parseInt(timestamp, 10)) > 600) {
    console.error('[WEBHOOK] Webhook signature timestamp expired.');
    return false;
  }

  // Payload is: <timestamp>.<rawBody>
  const payloadToSign = `${timestamp}.${rawBody}`;
  const computedHmac = crypto
    .createHmac('sha256', webhookSecret)
    .update(payloadToSign)
    .digest('hex');

  // Match test signature or live signature depending on which is provided
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

// =============================================================================
// Express App for PayMongo API & Webhooks
// =============================================================================
const app = express();

// Capture raw body for webhook signature verification
app.use(
  express.json({
    verify: (req, res, buf) => {
      req.rawBody = buf.toString('utf8');
    },
  })
);
app.use(cors({ origin: true }));

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'lambac-paymongo-service',
    timestamp: new Date().toISOString(),
    livemode: false,
  });
});

/**
 * Authentication Middleware: Verify Firebase Auth ID Token
 */
async function authenticateUser(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Missing or malformed Authorization header with Bearer token.',
    });
  }

  const idToken = authHeader.split('Bearer ')[1].trim();
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
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

/**
 * GET & POST /first-order-eligibility
 * Returns authoritative first-order GCash eligibility for the authenticated customer.
 */
app.get('/first-order-eligibility', authenticateUser, async (req, res) => {
  try {
    const eligibility = await determineCustomerFirstOrderStatus(req.user.uid, db);
    return res.status(200).json(eligibility);
  } catch (err) {
    console.error('[FIRST_ORDER] Error checking eligibility:', err);
    return res.status(500).json({
      error: 'InternalServerError',
      message: err.message,
    });
  }
});

app.post('/first-order-eligibility', authenticateUser, async (req, res) => {
  try {
    const eligibility = await determineCustomerFirstOrderStatus(req.user.uid, db);
    return res.status(200).json(eligibility);
  } catch (err) {
    console.error('[FIRST_ORDER] Error checking eligibility:', err);
    return res.status(500).json({
      error: 'InternalServerError',
      message: err.message,
    });
  }
});

/**
 * POST /validate-first-order
 * Authoritatively validates and reserves a customer's first-order attempt.
 * Rejects Pay at Counter for first orders and prevents simultaneous pending first-order attempts.
 */
app.post('/validate-first-order', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { paymentMethod, orderId, idempotencyKey } = req.body;
    const normalizedMethod = String(paymentMethod || '').trim().toLowerCase();

    const eligibility = await determineCustomerFirstOrderStatus(userId, db);

    if (eligibility.requiresFirstOrderGcash) {
      // 1. Reject Pay at Counter / non-GCash payment method
      if (normalizedMethod !== 'gcash') {
        return res.status(403).json({
          error: 'FirstOrderGcashRequired',
          message: 'Your first order must be paid through GCash. Pay at Counter is unavailable for your first order.',
          requiresFirstOrderGcash: true,
        });
      }

      // 2. Enforce atomic single-reservation lock in Firestore transaction
      const reservationRef = db.collection('first_order_reservations').doc(userId);
      const lockResult = await db.runTransaction(async (transaction) => {
        // PHASE A — READ ALL REQUIRED DOCUMENTS FIRST
        const resSnap = await transaction.get(reservationRef);
        let existingOrderSnap = null;
        const resData = resSnap.exists ? resSnap.data() : null;

        if (resData && resData.status === 'ACTIVE' && resData.order_id && resData.order_id !== orderId) {
          const existingOrderRef = db.collection('orders').doc(resData.order_id);
          existingOrderSnap = await transaction.get(existingOrderRef);
        }

        // PHASE B — VALIDATE
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

        // PHASE C — WRITE RESERVATION ATOMICALLY
        const now = new Date().toISOString();
        transaction.set(
          reservationRef,
          {
            uid: userId,
            order_id: orderId || resData?.order_id || 'pending_creation',
            idempotency_key: idempotencyKey || null,
            status: 'ACTIVE',
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
    console.error('[FIRST_ORDER] Validation error:', err);
    return res.status(500).json({
      error: 'InternalServerError',
      message: err.message,
    });
  }
});

/**
 * POST /create-checkout-session
 * Creates an authoritative PayMongo Hosted Checkout Session for GCash
 */
app.post('/create-checkout-session', authenticateUser, async (req, res) => {
  try {
    const { orderId } = req.body;
    if (!orderId) {
      return res.status(400).json({
        error: 'ValidationFailure',
        message: 'orderId is required.',
      });
    }

    const userId = req.user.uid;

    // 1. Authoritative Order Lookup from Firestore
    let orderDocRef = db.collection('orders').doc(orderId);
    let orderSnap = await orderDocRef.get();

    // Fallback: look up by order_number if not found by doc id
    if (!orderSnap.exists) {
      const qSnap = await db
        .collection('orders')
        .where('order_number', '==', orderId)
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
        message: `Order '${orderId}' not found.`,
      });
    }

    const order = orderSnap.data();
    const orderDocId = orderSnap.id;

    // 2. Access Control / Order Ownership Check
    const orderCustomerId = order.customer_id || order.customerId || order.userId;
    if (orderCustomerId !== userId) {
      const userDoc = await db.collection('users').doc(userId).get();
      const role = userDoc.exists ? (userDoc.data().role || 'customer') : 'customer';
      if (role !== 'admin' && role !== 'staff' && role !== 'barista') {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'You can only create checkout sessions for your own orders.',
        });
      }
    }

    // 3. State Validation: Prevent paying for already-paid or cancelled orders
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
      const orderPaymentMethod = String(order.payment_method || order.paymentMethod || 'GCash').trim().toLowerCase();
      if (orderPaymentMethod !== 'gcash') {
        return res.status(403).json({
          error: 'FirstOrderGcashRequired',
          message: 'Your first order must be paid through GCash. Pay at Counter is not allowed for your first order.',
        });
      }

      // Atomic reservation check in Firestore
      const reservationRef = db.collection('first_order_reservations').doc(orderCustomerId);
      const reservationCheck = await db.runTransaction(async (transaction) => {
        // PHASE A — READS
        const resSnap = await transaction.get(reservationRef);
        const resData = resSnap.exists ? resSnap.data() : null;
        let conflictingOrderSnap = null;

        if (resData && resData.status === 'ACTIVE' && resData.order_id && resData.order_id !== orderDocId) {
          conflictingOrderSnap = await transaction.get(db.collection('orders').doc(resData.order_id));
        }

        // PHASE B — VALIDATE
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

        // PHASE C — WRITE RESERVATION
        const now = new Date().toISOString();
        transaction.set(
          reservationRef,
          {
            uid: orderCustomerId,
            order_id: orderDocId,
            order_number: order.order_number || orderDocId,
            status: 'ACTIVE',
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

    // 5. Validate Amount and Currency
    const totalAmount = parseFloat(order.total_amount || order.totalAmount || order.total || 0);
    if (isNaN(totalAmount) || totalAmount <= 0) {
      return res.status(400).json({
        error: 'InvalidAmount',
        message: `Order total amount (₱${totalAmount}) is invalid.`,
      });
    }

    // PayMongo requires amount in integer centavos (e.g. PHP 150.00 -> 15000)
    const amountInCentavos = Math.round(totalAmount * 100);

    // 6. Line Items Generation
    const rawItems = order.items || [];
    let lineItems = [];

    if (Array.isArray(rawItems) && rawItems.length > 0) {
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

    // 7. Customer Billing Info
    const customerName = order.customer_name || order.customerName || req.user.name || 'Customer';
    const customerPhone = order.customer_phone || order.customerPhone || '09171234567';
    const customerEmail = order.customer_email || order.customerEmail || req.user.email || 'customer@lambac.ph';

    // 8. Success and Cancel Redirect URLs
    const successUrl = `https://lambac-coffee-roastery.web.app/order-confirmation?orderId=${orderDocId}&payment=success`;
    const cancelUrl = `https://lambac-coffee-roastery.web.app/order-detail/${orderDocId}?payment=cancelled`;

    // 9. Create PayMongo Checkout Session Payload
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

    console.log(`[PAYMONGO] Creating checkout session for Order: ${orderDocId} Amount: PHP ${totalAmount}`);

    const response = await fetch(`${PAYMONGO_API_BASE}/checkout_sessions`, {
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
      console.error('[PAYMONGO] Error creating session:', responseData);
      return res.status(response.status).json({
        error: 'PaymongoError',
        details: responseData.errors || responseData,
      });
    }

    const checkoutSession = responseData.data;
    const checkoutUrl = checkoutSession.attributes.checkout_url;
    const checkoutSessionId = checkoutSession.id;

    // 10. Update Firestore Order with Checkout Metadata
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

    console.log(`[PAYMONGO] Checkout session created: ${checkoutSessionId} URL: ${checkoutUrl}`);

    return res.status(200).json({
      success: true,
      orderId: orderDocId,
      orderNumber: order.order_number || orderDocId,
      checkoutSessionId,
      checkoutUrl,
      amount: totalAmount,
      currency: 'PHP',
      paymentMethod: 'GCash',
      isFirstOrder: eligibility.requiresFirstOrderGcash,
    });
  } catch (err) {
    console.error('[PAYMONGO] Unhandled exception in create-checkout-session:', err);
    return res.status(500).json({
      error: 'InternalServerError',
      message: err.message,
    });
  }
});

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
}) {
  const now = new Date().toISOString();

  await db.runTransaction(async (transaction) => {
    // =========================================================================
    // PHASE A — READ ALL REQUIRED DOCUMENTS FIRST
    // =========================================================================
    const freshOrderSnap = await transaction.get(orderRef);
    if (!freshOrderSnap.exists) return;

    const currentData = freshOrderSnap.data();
    const customerId = currentData.customer_id || currentData.customerId || currentData.userId;

    const userRef = customerId ? db.collection('users').doc(customerId) : null;
    const reservationRef = customerId ? db.collection('first_order_reservations').doc(customerId) : null;

    const userSnap = userRef ? await transaction.get(userRef) : null;
    const reservationSnap = reservationRef ? await transaction.get(reservationRef) : null;

    // =========================================================================
    // PHASE B — VALIDATE
    // =========================================================================
    const alreadyPaid = String(currentData.payment_status || '').toUpperCase() === 'PAID';

    // =========================================================================
    // PHASE C — WRITE ALL DOCUMENTS ATOMICALLY
    // =========================================================================
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

    // Mark customer's first-order GCash requirement as authoritatively completed
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

    // Update reservation lock to COMPLETED
    if (reservationRef) {
      const existingRes = reservationSnap && reservationSnap.exists ? reservationSnap.data() : {};
      if (existingRes.status !== 'COMPLETED') {
        transaction.set(
          reservationRef,
          {
            uid: customerId,
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

    // Record Webhook Event for idempotency if provided
    if (eventDocRef && eventPayload) {
      transaction.set(eventDocRef, eventPayload);
    }
  });
}

/**
 * POST /verify-payment-session
 * Checks PayMongo session status directly and updates Firestore if paid
 */
app.post('/verify-payment-session', authenticateUser, async (req, res) => {
  try {
    const { orderId, checkoutSessionId } = req.body;
    if (!orderId) {
      return res.status(400).json({ error: 'orderId is required' });
    }

    const orderDocRef = db.collection('orders').doc(orderId);
    const orderSnap = await orderDocRef.get();
    if (!orderSnap.exists) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderSnap.data();
    const sessionId = checkoutSessionId || order.checkout_session_id;

    if (!sessionId) {
      return res.status(400).json({ error: 'No checkout_session_id found for this order.' });
    }

    // Call PayMongo API to inspect the session
    const response = await fetch(`${PAYMONGO_API_BASE}/checkout_sessions/${sessionId}`, {
      method: 'GET',
      headers: {
        Authorization: getPaymongoAuthHeader(),
        Accept: 'application/json',
      },
    });

    if (!response.ok) {
      const errData = await response.json();
      return res.status(response.status).json({ error: 'PaymongoLookupFailed', details: errData });
    }

    const sessionData = await response.json();
    const attributes = sessionData.data.attributes;
    const sessionStatus = attributes.status;
    const payments = attributes.payments || [];

    let isPaid = sessionStatus === 'paid';
    let paymentRef = null;
    let amountPhp = order.total_amount;

    if (payments.length > 0) {
      const lastPayment = payments[payments.length - 1];
      if (lastPayment.attributes && lastPayment.attributes.status === 'paid') {
        isPaid = true;
        paymentRef = lastPayment.id;
        if (lastPayment.attributes.amount) {
          amountPhp = lastPayment.attributes.amount / 100;
        }
      }
    }

    if (isPaid) {
      await markOrderVerifiedPaidAtomically({
        orderRef: orderDocRef,
        orderId,
        paymentId: paymentRef || sessionId,
        checkoutSessionId: sessionId,
        amountPhp,
      });

      return res.json({
        success: true,
        orderId,
        paymentStatus: 'PAID',
        paymentReference: paymentRef || sessionId,
        sessionStatus,
        firstOrderCompleted: true,
      });
    }

    // If session expired on PayMongo side, update order and release first-order lock for retry
    if (sessionStatus === 'expired') {
      const now = new Date().toISOString();
      const customerId = order.customer_id || order.customerId || order.userId;
      await orderDocRef.update({
        payment_status: 'EXPIRED',
        updated_at: now,
      });
      if (customerId) {
        await db.collection('first_order_reservations').doc(customerId).set(
          {
            uid: customerId,
            order_id: orderId,
            status: 'RELEASED_FOR_RETRY',
            updated_at: now,
          },
          { merge: true }
        );
      }
      return res.json({
        success: true,
        orderId,
        paymentStatus: 'EXPIRED',
        sessionStatus,
      });
    }

    return res.json({
      success: true,
      orderId,
      paymentStatus: order.payment_status || 'PENDING',
      sessionStatus,
    });
  } catch (err) {
    console.error('[VERIFY] Error verifying payment session:', err);
    return res.status(500).json({ error: 'InternalServerError', message: err.message });
  }
});

/**
 * POST /paymongo-webhook
 * Official PayMongo Webhook Endpoint for payment events
 */
app.post('/paymongo-webhook', async (req, res) => {
  const signatureHeader = req.headers['paymongo-signature'] || req.headers['Paymongo-Signature'];
  const rawBody = req.rawBody || JSON.stringify(req.body);

  // 1. Verify Webhook Signature
  const isValidSignature = verifyPaymongoSignature(signatureHeader, rawBody, PAYMONGO_WEBHOOK_SECRET);
  if (!isValidSignature) {
    console.error('[WEBHOOK] Signature verification failed. Rejecting request.');
    return res.status(400).json({ error: 'InvalidSignature', message: 'Webhook signature verification failed.' });
  }

  try {
    const event = req.body.data;
    if (!event || !event.attributes) {
      console.warn('[WEBHOOK] Malformed event payload received.');
      return res.status(400).json({ error: 'MalformedPayload' });
    }

    const eventId = event.id;
    const eventType = event.attributes.type;
    console.log(`[WEBHOOK] Received event: ${eventId} Type: ${eventType}`);

    // 2. Idempotency Check: Prevent duplicate processing of the same webhook event
    const eventDocRef = db.collection('payment_webhook_events').doc(eventId);
    const existingEvent = await eventDocRef.get();
    if (existingEvent.exists) {
      console.log(`[WEBHOOK] Event ${eventId} was already processed. Returning 200 idempotent.`);
      return res.status(200).json({ received: true, duplicate: true });
    }

    // 3. Process Events
    if (eventType === 'checkout_session.payment.paid') {
      const checkoutSessionData = event.attributes.data;
      const sessionAttributes = checkoutSessionData.attributes || {};
      const metadata = sessionAttributes.metadata || {};
      const orderId = metadata.order_id || metadata.orderId;

      if (!orderId) {
        console.warn(`[WEBHOOK] checkout_session.payment.paid event ${eventId} has no order_id in metadata.`);
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
        console.warn(`[WEBHOOK] Order ${orderId} does not exist in Firestore.`);
        return res.status(200).json({ received: true, warning: 'Order not found' });
      }

      const order = orderSnap.data();
      const payments = sessionAttributes.payments || [];
      const primaryPayment = payments.length > 0 ? payments[0] : null;
      const paymentId = primaryPayment ? primaryPayment.id : checkoutSessionData.id;
      const amountCentavos = primaryPayment ? primaryPayment.attributes?.amount : null;
      const amountPhp = amountCentavos ? amountCentavos / 100 : order.total_amount;

      // 4. Validate Amount
      const expectedAmount = parseFloat(order.total_amount || 0);
      if (amountPhp && Math.abs(amountPhp - expectedAmount) > 0.05) {
        console.error(`[WEBHOOK] Payment amount mismatch for Order ${orderId}. Expected: ${expectedAmount}, Received: ${amountPhp}`);
      }

      // 5. Atomic Update in Firestore (Order + User First-Order Completion + Reservation + Webhook Event)
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
      });

      console.log(`[WEBHOOK] Successfully marked Order ${orderId} as PAID via GCash and completed first-order requirement (PayMongo Ref: ${paymentId})`);
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
        const resolvedCustomerId = customerId || (orderSnap.exists ? orderSnap.data().customer_id : null);

        await orderRef.update({
          payment_status: 'FAILED',
          payment_failure_reason: paymentData.attributes?.failed_message || 'Payment failed via GCash',
          updated_at: now,
        });

        // Release first-order reservation so customer can retry GCash payment
        if (resolvedCustomerId) {
          await db.collection('first_order_reservations').doc(resolvedCustomerId).set(
            {
              uid: resolvedCustomerId,
              order_id: orderId,
              status: 'RELEASED_FOR_RETRY',
              failure_reason: paymentData.attributes?.failed_message || 'Payment failed via GCash',
              updated_at: now,
            },
            { merge: true }
          );
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
        if (orderSnap.exists && orderSnap.data().payment_status === 'PENDING') {
          const resolvedCustomerId = customerId || orderSnap.data().customer_id;
          await orderRef.update({
            payment_status: 'EXPIRED',
            updated_at: now,
          });

          // Release first-order reservation so customer can retry GCash payment
          if (resolvedCustomerId) {
            await db.collection('first_order_reservations').doc(resolvedCustomerId).set(
              {
                uid: resolvedCustomerId,
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
    console.error('[WEBHOOK] Uncaught error processing webhook event:', err);
    return res.status(500).json({ error: 'WebhookProcessingError', message: err.message });
  }
});

// Export Express App as Cloud Function
exports.api = functions.https.onRequest(app);

// Direct function export for webhook
exports.paymongoWebhook = functions.https.onRequest((req, res) => {
  return app(req, res);
});

// Export helpers for unit testing
exports._testHelpers = {
  verifyPaymongoSignature,
  isQualifyingFirstOrder,
  isActivePendingFirstOrder,
  determineCustomerFirstOrderStatus,
};
