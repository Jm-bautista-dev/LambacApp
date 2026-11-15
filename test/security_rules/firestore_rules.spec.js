const fs = require('fs');
const path = require('path');
const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'lambac-coffee-roastery-test';
const FIRESTORE_RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

describe('Lambac Coffee Roastery — Firebase Firestore Security Rules Automated Suite', () => {
  let testEnv;

  before(async function () {
    this.timeout(20000);
    const rules = fs.readFileSync(FIRESTORE_RULES_PATH, 'utf8');
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
    }
  });

  // ---------------------------------------------------------------------------
  // 1. UNAUTHENTICATED GUEST BOUNDARIES
  // ---------------------------------------------------------------------------
  describe('1. Unauthenticated Guest Access Boundaries', () => {
    it('NEGATIVE: Unauthenticated request CANNOT read customer user profile', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(unauthDb.collection('users').doc('cust_alice').get());
    });

    it('NEGATIVE: Unauthenticated request CANNOT create order', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(
        unauthDb.collection('orders').doc('ord_guest_1').set({
          customer_name: 'Guest Hacker',
          total_amount: 500,
          status: 'pending',
        })
      );
    });

    it('POSITIVE: Unauthenticated user CAN read public product catalog', async () => {
      // Seed public product as admin
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('products').doc('benguet-typica').set({
          name: 'Benguet Typica',
          base_price: 420.0,
          is_active: true,
        });
      });

      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertSucceeds(unauthDb.collection('products').doc('benguet-typica').get());
    });
  });

  // ---------------------------------------------------------------------------
  // 2. CUSTOMER DATA ISOLATION & SELF-ESCALATION PREVENTION
  // ---------------------------------------------------------------------------
  describe('2. Customer Multi-Tenant Isolation & Role Escalation Prevention', () => {
    it('POSITIVE: Customer Alice CAN read her own user document', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('cust_alice').set({
          fullName: 'Alice Customer',
          email: 'alice@lambac.com',
          role: 'customer',
        });
      });

      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertSucceeds(aliceDb.collection('users').doc('cust_alice').get());
    });

    it('NEGATIVE: Customer Alice CANNOT read Bob customer profile', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('cust_bob').set({
          fullName: 'Bob Customer',
          email: 'bob@lambac.com',
          role: 'customer',
        });
      });

      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(aliceDb.collection('users').doc('cust_bob').get());
    });

    it('NEGATIVE: Customer CANNOT self-escalate role to admin during registration', async () => {
      const hackerDb = testEnv.authenticatedContext('cust_hacker', { email: 'hacker@lambac.com' }).firestore();
      await assertFails(
        hackerDb.collection('users').doc('cust_hacker').set({
          fullName: 'Privilege Escalator',
          email: 'hacker@lambac.com',
          role: 'admin',
          loyaltyPoints: 100000,
        })
      );
    });

    it('POSITIVE: Customer self-registration succeeds with role customer and <= 50 loyalty points', async () => {
      const newCustDb = testEnv.authenticatedContext('cust_new_user', { email: 'new@lambac.com' }).firestore();
      await assertSucceeds(
        newCustDb.collection('users').doc('cust_new_user').set({
          fullName: 'Legitimate Customer',
          email: 'new@lambac.com',
          role: 'customer',
          loyaltyPoints: 50,
        })
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. ORDER PRIVACY & STATUS TAMPERING PREVENTION
  // ---------------------------------------------------------------------------
  describe('3. Order Multi-Tenant Isolation & Status Protection', () => {
    it('NEGATIVE: Customer Alice CANNOT read Bob orders', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_bob_private').set({
          customerId: 'cust_bob',
          customer_name: 'Bob',
          total_amount: 350.0,
          status: 'pending',
        });
      });

      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(aliceDb.collection('orders').doc('ord_bob_private').get());
    });

    it('POSITIVE: Customer Alice CAN read her own order', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_alice_1').set({
          customerId: 'cust_alice',
          customer_name: 'Alice Customer',
          total_amount: 420.0,
          status: 'pending',
        });
      });

      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertSucceeds(aliceDb.collection('orders').doc('ord_alice_1').get());
    });

    it('NEGATIVE: Customer CANNOT mark their order as completed or paid', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_alice_2').set({
          customerId: 'cust_alice',
          customer_name: 'Alice Customer',
          total_amount: 420.0,
          status: 'pending',
          paymentStatus: 'UNPAID',
        });
      });

      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(
        aliceDb.collection('orders').doc('ord_alice_2').update({
          status: 'completed',
          paymentStatus: 'PAID',
        })
      );
    });

    it('POSITIVE: Customer Alice CAN create a valid pickup order for her own UID', async () => {
      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertSucceeds(
        aliceDb.collection('orders').doc('ord_alice_new').set({
          customer_id: 'cust_alice',
          customer_name: 'Alice Customer',
          customer_phone: '09171234567',
          items: [{
            product_id: 'mt-apo-honey',
            product_name: 'Mount Apo Anaerobic Honey Reserve',
            unit_price: 480.0,
            quantity: 1,
            total_price: 480.0,
          }],
          total_amount: 480.0,
          status: 'pending',
          payment_status: 'UNPAID',
          pickup_date: 'Today',
          pickup_time_slot: 'ASAP (~15-20 mins)',
        })
      );
    });

    it('NEGATIVE: Customer Alice CANNOT create an order under Bob UID', async () => {
      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(
        aliceDb.collection('orders').doc('ord_spoofed').set({
          customer_id: 'cust_bob',
          customer_name: 'Bob',
          items: [{ product_id: 'mt-apo-honey', quantity: 1, unit_price: 480.0, total_price: 480.0 }],
          total_amount: 480.0,
          status: 'pending',
          payment_status: 'UNPAID',
        })
      );
    });

    it('NEGATIVE: Customer Alice CANNOT create an order with status completed or paid', async () => {
      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(
        aliceDb.collection('orders').doc('ord_fake_complete').set({
          customer_id: 'cust_alice',
          items: [{ product_id: 'mt-apo-honey', quantity: 1, unit_price: 480.0, total_price: 480.0 }],
          total_amount: 480.0,
          status: 'completed',
          payment_status: 'PAID',
        })
      );
    });

    it('NEGATIVE: Customer Alice CANNOT directly modify product inventory in /products', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('products').doc('mt-apo-honey').set({
          name: 'Mount Apo Honey',
          base_price: 480.0,
          stock_quantity: 20,
        });
      });

      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(
        aliceDb.collection('products').doc('mt-apo-honey').update({
          stock_quantity: 19,
        })
      );
    });

    it('NEGATIVE: Customer Alice CANNOT directly create sales ledger record in /sales', async () => {
      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(
        aliceDb.collection('sales').doc('sale_hacked').set({
          transaction_number: 'TX-MOB-9999',
          total_amount: 500,
          channel: 'mobileApp',
        })
      );
    });

    it('POSITIVE: Customer Alice CAN cancel her own pending order', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_alice_cancellable').set({
          customer_id: 'cust_alice',
          status: 'pending',
          total_amount: 480.0,
        });
      });

      const aliceDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertSucceeds(
        aliceDb.collection('orders').doc('ord_alice_cancellable').update({
          status: 'cancelled',
          status_updated_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
      );
    });

    it('NEGATIVE: Customer Bob CANNOT cancel Alice order', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_alice_protected').set({
          customer_id: 'cust_alice',
          status: 'pending',
          total_amount: 480.0,
        });
      });

      const bobDb = testEnv.authenticatedContext('cust_bob', { email: 'bob@lambac.com' }).firestore();
      await assertFails(
        bobDb.collection('orders').doc('ord_alice_protected').update({
          status: 'cancelled',
          status_updated_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 4. STAFF & BARISTA OPERATIONAL PRIVILEGES
  // ---------------------------------------------------------------------------
  describe('4. Staff / Barista Permissions & Boundaries', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('usr_barista').set({
          fullName: 'Barista Hiro',
          email: 'barista.hiro@lambac.com',
          role: 'employee',
        });
      });
    });

    it('POSITIVE: Barista CAN read customer orders to prepare drinks', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_for_queue').set({
          customerId: 'cust_charlie',
          customer_name: 'Charlie',
          status: 'pending',
        });
      });

      const baristaDb = testEnv.authenticatedContext('usr_barista', { email: 'barista.hiro@lambac.com' }).firestore();
      await assertSucceeds(baristaDb.collection('orders').doc('ord_for_queue').get());
    });

    it('NEGATIVE: Barista CANNOT delete customer orders or audit logs', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_cannot_delete').set({
          customerId: 'cust_charlie',
          status: 'completed',
        });
      });

      const baristaDb = testEnv.authenticatedContext('usr_barista', { email: 'barista.hiro@lambac.com' }).firestore();
      await assertFails(baristaDb.collection('orders').doc('ord_cannot_delete').delete());
    });
  });

  // ---------------------------------------------------------------------------
  // 5. ADMINISTRATOR CONTROL & AUDIT LOG IMMUTABILITY
  // ---------------------------------------------------------------------------
  describe('5. Administrator Governance & Audit Trail Immutability', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('usr_lead_admin').set({
          fullName: 'Lead Admin',
          email: 'jmbautista0228@gmail.com',
          role: 'admin',
        });
      });
    });

    it('POSITIVE: Admin CAN manage products (create, edit price)', async () => {
      const adminDb = testEnv.authenticatedContext('usr_lead_admin', {
        email: 'jmbautista0228@gmail.com',
        email_verified: true,
      }).firestore();

      await assertSucceeds(
        adminDb.collection('products').doc('new_blend').set({
          name: 'Signature Espresso Blend',
          base_price: 490.0,
          is_active: true,
        })
      );
    });

    it('POSITIVE: Admin CAN read security audit logs', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('auditLogs').doc('log_001').set({
          action: 'accountCreated',
          actor_uid: 'usr_lead_admin',
          timestamp: new Date(),
        });
      });

      const adminDb = testEnv.authenticatedContext('usr_lead_admin', {
        email: 'jmbautista0228@gmail.com',
        email_verified: true,
      }).firestore();

      await assertSucceeds(adminDb.collection('auditLogs').doc('log_001').get());
    });

    it('NEGATIVE: Non-admin CANNOT read security audit logs', async () => {
      const custDb = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).firestore();
      await assertFails(custDb.collection('auditLogs').doc('log_001').get());
    });

    it('NEGATIVE: Audit logs are IMMUTABLE (cannot be deleted even by Admin)', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('auditLogs').doc('log_permanent').set({
          action: 'posSaleCompleted',
          actor_uid: 'usr_lead_admin',
          timestamp: new Date(),
        });
      });

      const adminDb = testEnv.authenticatedContext('usr_lead_admin', {
        email: 'jmbautista0228@gmail.com',
        email_verified: true,
      }).firestore();

      // Rule explicitly enforces: allow update, delete: if false;
      await assertFails(adminDb.collection('auditLogs').doc('log_permanent').delete());
    });
  });

  // ---------------------------------------------------------------------------
  // 6. FIRST-ORDER GCASH RESERVATIONS, PROTECTED PAYMENT FIELDS & PROFILE SYNC
  // ---------------------------------------------------------------------------
  describe('6. First-Order GCash Reservations, Protected Payment Fields & Self-Service Profile Updates', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('cust_first_order').set({
          full_name: 'First Order Customer',
          email: 'first@lambac.com',
          role: 'customer',
          status: 'active',
          isActive: true,
          first_order_gcash_completed: false,
          firstOrderGcashCompleted: false,
        });
        await context.firestore().collection('users').doc('usr_barista_2').set({
          full_name: 'Barista Staff',
          email: 'barista2@lambac.com',
          role: 'barista',
          status: 'active',
          isActive: true,
        });
      });
    });

    it('POSITIVE: First-order customer CAN atomically create GCash PENDING order and ACTIVE_PENDING reservation', async () => {
      const custDb = testEnv.authenticatedContext('cust_first_order', { email: 'first@lambac.com' }).firestore();
      const batch = custDb.batch();
      batch.set(custDb.collection('orders').doc('ord_first_gcash'), {
        customer_id: 'cust_first_order',
        customer_name: 'First Order Customer',
        items: [{ product_id: 'mt-apo-honey', quantity: 1, unit_price: 480.0, total_price: 480.0 }],
        total_amount: 480.0,
        status: 'pending',
        payment_method: 'GCash',
        payment_status: 'PENDING',
        is_first_order_gcash: true,
      });
      batch.set(custDb.collection('first_order_reservations').doc('cust_first_order'), {
        customer_id: 'cust_first_order',
        order_id: 'ord_first_gcash',
        order_number: 'LMB-1001',
        payment_method: 'GCash',
        status: 'ACTIVE_PENDING',
        updated_at: new Date().toISOString(),
      });
      await assertSucceeds(batch.commit());
    });

    it('NEGATIVE: First-order customer CANNOT create a Pay at Counter order before completing first GCash order', async () => {
      const custDb = testEnv.authenticatedContext('cust_first_order', { email: 'first@lambac.com' }).firestore();
      await assertFails(
        custDb.collection('orders').doc('ord_first_counter_bypass').set({
          customer_id: 'cust_first_order',
          items: [{ product_id: 'mt-apo-honey', quantity: 1, unit_price: 480.0, total_price: 480.0 }],
          total_amount: 480.0,
          status: 'pending',
          payment_method: 'Pay at Counter',
          payment_status: 'UNPAID',
        })
      );
    });

    it('NEGATIVE: Customer CANNOT create an order with pre-populated payment_reference or paid_at', async () => {
      const custDb = testEnv.authenticatedContext('cust_first_order', { email: 'first@lambac.com' }).firestore();
      await assertFails(
        custDb.collection('orders').doc('ord_fake_ref').set({
          customer_id: 'cust_first_order',
          items: [{ product_id: 'mt-apo-honey', quantity: 1, unit_price: 480.0, total_price: 480.0 }],
          total_amount: 480.0,
          status: 'pending',
          payment_method: 'GCash',
          payment_status: 'PENDING',
          payment_reference: 'pay_spoofed_123',
          paid_at: new Date().toISOString(),
        })
      );
    });

    it('NEGATIVE: Customer CANNOT mark first_order_reservations as COMPLETED from client', async () => {
      const custDb = testEnv.authenticatedContext('cust_first_order', { email: 'first@lambac.com' }).firestore();
      await assertFails(
        custDb.collection('first_order_reservations').doc('cust_first_order').set({
          customer_id: 'cust_first_order',
          order_id: 'ord_first_gcash',
          status: 'COMPLETED',
        })
      );
    });

    it('POSITIVE: Customer CAN update lastLoginAt, favorite_product_ids, and fcm_device_token on own user profile', async () => {
      const custDb = testEnv.authenticatedContext('cust_first_order', { email: 'first@lambac.com' }).firestore();
      await assertSucceeds(
        custDb.collection('users').doc('cust_first_order').update({
          last_login_at: new Date().toISOString(),
          favorite_product_ids: ['mt-apo-honey'],
          fcm_device_token: 'fcm_tok_123',
        })
      );
    });

    it('NEGATIVE: Customer CANNOT self-modify first_order_gcash_completed on own user profile', async () => {
      const custDb = testEnv.authenticatedContext('cust_first_order', { email: 'first@lambac.com' }).firestore();
      await assertFails(
        custDb.collection('users').doc('cust_first_order').update({
          first_order_gcash_completed: true,
        })
      );
    });

    it('NEGATIVE: Barista CANNOT manually mark an unverified GCash order as PAID or completed', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('orders').doc('ord_unpaid_gcash').set({
          customer_id: 'cust_first_order',
          total_amount: 480.0,
          status: 'readyForPickup',
          payment_method: 'GCash',
          payment_status: 'PENDING',
        });
      });

      const baristaDb = testEnv.authenticatedContext('usr_barista_2', { email: 'barista2@lambac.com' }).firestore();
      await assertFails(
        baristaDb.collection('orders').doc('ord_unpaid_gcash').update({
          payment_status: 'PAID',
        })
      );
      await assertFails(
        baristaDb.collection('orders').doc('ord_unpaid_gcash').update({
          status: 'completed',
        })
      );
    });
  });
});
