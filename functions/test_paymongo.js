const crypto = require('crypto');
const { _testHelpers } = require('./index.js');

const {
  verifyPaymongoSignature,
  isQualifyingFirstOrder,
  isActivePendingFirstOrder,
} = _testHelpers;

// Unit test 1: Valid signature test
const testSecret = 'whsk_test_mocksecret123456';
const testPayload = JSON.stringify({ data: { id: 'evt_123', type: 'event' } });
const timestamp = Math.floor(Date.now() / 1000);
const validHmac = crypto
  .createHmac('sha256', testSecret)
  .update(`${timestamp}.${testPayload}`)
  .digest('hex');

const validHeader = `t=${timestamp},te=${validHmac}`;
const test1Pass = verifyPaymongoSignature(validHeader, testPayload, testSecret);
console.log('Test 1 (Valid Signature):', test1Pass ? 'PASSED' : 'FAILED');

// Unit test 2: Tampered payload test
const tamperedPayload = JSON.stringify({ data: { id: 'evt_123', type: 'event', tampered: true } });
let test2Pass = false;
try {
  test2Pass = !verifyPaymongoSignature(validHeader, tamperedPayload, testSecret);
} catch (e) {
  test2Pass = true;
}
console.log('Test 2 (Tampered Payload Rejection):', test2Pass ? 'PASSED' : 'FAILED');

// Unit test 3: Tampered signature test
const invalidHeader = `t=${timestamp},te=0000000000000000000000000000000000000000000000000000000000000000`;
const test3Pass = !verifyPaymongoSignature(invalidHeader, testPayload, testSecret);
console.log('Test 3 (Invalid Signature Rejection):', test3Pass ? 'PASSED' : 'FAILED');

// Unit test 4: Pending GCash order does NOT count as completed first order
const test4Pass =
  !isQualifyingFirstOrder({
    status: 'pending',
    payment_method: 'GCash',
    payment_status: 'PENDING',
    payment_provider: 'PayMongo',
  }) &&
  isActivePendingFirstOrder({
    status: 'pending',
    payment_method: 'GCash',
    payment_status: 'PENDING',
  });
console.log('Test 4 (Pending GCash Order Does Not Qualify):', test4Pass ? 'PASSED' : 'FAILED');

// Unit test 5: Failed, Expired, Cancelled, Unpaid orders do NOT count as completed first order
const test5Pass =
  !isQualifyingFirstOrder({
    status: 'pending',
    payment_method: 'GCash',
    payment_status: 'FAILED',
    payment_provider: 'PayMongo',
  }) &&
  !isQualifyingFirstOrder({
    status: 'pending',
    payment_method: 'GCash',
    payment_status: 'EXPIRED',
    payment_provider: 'PayMongo',
  }) &&
  !isQualifyingFirstOrder({
    status: 'cancelled',
    payment_method: 'GCash',
    payment_status: 'PAID',
    payment_provider: 'PayMongo',
  }) &&
  !isQualifyingFirstOrder({
    status: 'pending',
    payment_method: 'Pay at Counter',
    payment_status: 'UNPAID',
  }) &&
  !isActivePendingFirstOrder({
    status: 'pending',
    payment_method: 'GCash',
    payment_status: 'FAILED',
  }) &&
  !isActivePendingFirstOrder({
    status: 'pending',
    payment_method: 'GCash',
    payment_status: 'EXPIRED',
  });
console.log('Test 5 (Failed/Expired/Cancelled/Unpaid Orders Do Not Qualify & Release Lock):', test5Pass ? 'PASSED' : 'FAILED');

// Unit test 6: Verified PAID PayMongo GCash order DOES qualify as completed first order
const test6Pass = isQualifyingFirstOrder({
  status: 'pending',
  payment_method: 'GCash',
  payment_status: 'PAID',
  payment_provider: 'PayMongo',
  payment_reference: 'pay_verified_123',
  paid_at: new Date().toISOString(),
});
console.log('Test 6 (Verified PAID PayMongo GCash Order Qualifies):', test6Pass ? 'PASSED' : 'FAILED');

if (test1Pass && test2Pass && test3Pass && test4Pass && test5Pass && test6Pass) {
  console.log('ALL BACKEND WEBHOOK & FIRST-ORDER ENFORCEMENT TESTS PASSED!');
  process.exit(0);
} else {
  console.error('SOME TESTS FAILED');
  process.exit(1);
}
