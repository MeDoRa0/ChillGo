const testing = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'chillgo-61439';

describe('Firebase Security Rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
      storage: {
        rules: fs.readFileSync(path.resolve(__dirname, '../storage.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 9199,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  describe('Firestore profile rules', () => {
    it('allows an authenticated user to create and update their own profile', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const aliceDoc = aliceDb.collection('users').doc('alice');

      await testing.assertSucceeds(aliceDoc.set({
        username: 'alice',
        displayName: 'Alice',
        avatarUrl: null,
        createdAt: '2026-06-29T16:15:00.000Z',
      }));
      await testing.assertSucceeds(aliceDoc.update({ displayName: 'Alice Smith' }));
    });

    it('denies creating or updating another user profile', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const bobDoc = aliceDb.collection('users').doc('bob');

      await testing.assertFails(bobDoc.set({
        username: 'bob',
        displayName: 'Bob',
        createdAt: '2026-06-29T16:15:00.000Z',
      }));
      await testing.assertFails(bobDoc.update({ displayName: 'Robert' }));
    });

    it('allows authenticated profile reads and denies unauthenticated reads', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: '2026-06-29T16:15:00.000Z',
        });
      });

      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const unauthDb = testEnv.unauthenticatedContext().firestore();

      await testing.assertSucceeds(aliceDb.collection('users').doc('bob').get());
      await testing.assertFails(unauthDb.collection('users').doc('bob').get());
    });

    it('enforces username creation ownership and immutability', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      const usernameDoc = aliceDb.collection('usernames').doc('alice');

      await testing.assertSucceeds(usernameDoc.set({ uid: 'alice' }));
      await testing.assertFails(aliceDb.collection('usernames').doc('alice2').set({ uid: 'bob' }));
      await testing.assertFails(usernameDoc.update({ uid: 'bob' }));
      await testing.assertFails(unauthDb.collection('usernames').doc('guest').set({ uid: 'guest' }));
    });
  });

  describe('Storage avatar rules', () => {
    it('allows a user to upload and read their own image avatar', async () => {
      const aliceStorage = testEnv.authenticatedContext('alice').storage();
      const avatarRef = aliceStorage.ref('avatars/alice');

      await testing.assertSucceeds(
        avatarRef.put(Buffer.from('avatar'), { contentType: 'image/jpeg' }),
      );
      await testing.assertSucceeds(avatarRef.getDownloadURL());
    });

    it('denies avatar uploads for other users, non-images, and large files', async () => {
      const aliceStorage = testEnv.authenticatedContext('alice').storage();

      await testing.assertFails(
        aliceStorage.ref('avatars/bob').put(Buffer.from('avatar'), { contentType: 'image/jpeg' }),
      );
      await testing.assertFails(
        aliceStorage.ref('avatars/alice').put(Buffer.from('not-image'), { contentType: 'text/plain' }),
      );
      await testing.assertFails(
        aliceStorage.ref('avatars/alice').put(Buffer.alloc(512 * 1024), { contentType: 'image/jpeg' }),
      );
    });

    it('denies unauthenticated avatar reads and writes', async () => {
      const unauthStorage = testEnv.unauthenticatedContext().storage();

      await testing.assertFails(
        unauthStorage.ref('avatars/alice').put(Buffer.from('avatar'), { contentType: 'image/jpeg' }),
      );
      await testing.assertFails(unauthStorage.ref('avatars/alice').getDownloadURL());
    });
  });
});
