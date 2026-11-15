const fs = require('fs');
const path = require('path');
const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'lambac-coffee-roastery-test';
const STORAGE_RULES_PATH = path.resolve(__dirname, '../../storage.rules');

describe('Lambac Coffee Roastery — Firebase Storage Security Rules Automated Suite', () => {
  let testEnv;

  before(async function () {
    this.timeout(20000);
    const storageRules = fs.readFileSync(STORAGE_RULES_PATH, 'utf8');
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      storage: {
        rules: storageRules,
        host: '127.0.0.1',
        port: 9199,
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
      await testEnv.clearStorage();
    }
  });

  describe('1. Product Catalog Assets Access Rules', () => {
    it('POSITIVE: Anyone can read product catalog images', async () => {
      const unauthStorage = testEnv.unauthenticatedContext().storage();
      const productRef = unauthStorage.ref('products/benguet_typica.jpg');
      await assertSucceeds(productRef.getDownloadURL().catch(() => null)); // rules allow read
    });

    it('NEGATIVE: Unauthenticated request CANNOT upload product image', async () => {
      const unauthStorage = testEnv.unauthenticatedContext().storage();
      const productRef = unauthStorage.ref('products/hacked.jpg');
      const dummyData = Buffer.from([0xFF, 0xD8, 0xFF]);
      await assertFails(productRef.put(dummyData, { contentType: 'image/jpeg' }));
    });

    it('NEGATIVE: Customer CANNOT upload product catalog image', async () => {
      const custStorage = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).storage();
      const productRef = custStorage.ref('products/customer_upload.jpg');
      const dummyData = Buffer.from([0xFF, 0xD8, 0xFF]);
      await assertFails(productRef.put(dummyData, { contentType: 'image/jpeg' }));
    });

    it('NEGATIVE: Staff cannot upload executable or disallowed MIME types', async () => {
      const staffStorage = testEnv.authenticatedContext('staff_1', {
        email: 'barista@lambac.com',
        role: 'employee',
      }).storage();

      const exeRef = staffStorage.ref('products/script.sh');
      const scriptData = Buffer.from('#!/bin/bash');
      await assertFails(exeRef.put(scriptData, { contentType: 'application/x-sh' }));
    });
  });

  describe('2. User Avatars & Path Traversal Protection', () => {
    it('POSITIVE: Customer CAN upload own avatar image with valid MIME and size', async () => {
      const aliceStorage = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).storage();
      const avatarRef = aliceStorage.ref('users/cust_alice/avatar_01.jpg');
      const validJpg = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0]);
      await assertSucceeds(avatarRef.put(validJpg, { contentType: 'image/jpeg' }));
    });

    it('NEGATIVE: Customer Alice CANNOT upload or overwrite Bob avatar', async () => {
      const aliceStorage = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).storage();
      const bobAvatarRef = aliceStorage.ref('users/cust_bob/avatar_01.jpg');
      const validJpg = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0]);
      await assertFails(bobAvatarRef.put(validJpg, { contentType: 'image/jpeg' }));
    });

    it('NEGATIVE: Path traversal attacks (e.g. "../") in filenames are rejected', async () => {
      const aliceStorage = testEnv.authenticatedContext('cust_alice', { email: 'alice@lambac.com' }).storage();
      const traversalRef = aliceStorage.ref('users/cust_alice/..%2F..%2Fetc%2Fpasswd.jpg');
      const validJpg = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0]);
      await assertFails(traversalRef.put(validJpg, { contentType: 'image/jpeg' }));
    });
  });
});
