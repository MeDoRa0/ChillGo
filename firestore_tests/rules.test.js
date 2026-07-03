const testing = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'chillgo-61439';
const FIRESTORE_EMULATOR_PORT = 65080;
const STORAGE_EMULATOR_PORT = 65199;

describe('Firebase Security Rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
        host: '127.0.0.1',
        port: FIRESTORE_EMULATOR_PORT,
      },
      storage: {
        rules: fs.readFileSync(path.resolve(__dirname, '../storage.rules'), 'utf8'),
        host: '127.0.0.1',
        port: STORAGE_EMULATOR_PORT,
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

  describe('Firestore crew rules', () => {
    it('allows crew creation by authenticated owner and allows members to read it', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      const crewDoc = aliceDb.collection('crews').doc('crew1');
      const aliceMembership = aliceDb.collection('crew_memberships').doc('crew1_alice');
      const batch = aliceDb.batch();

      batch.set(crewDoc, {
        id: 'crew1',
        name: 'Weekend Hikers',
        ownerId: 'alice',
        createdAt: '2026-07-01T00:00:00Z',
      });
      batch.set(aliceMembership, {
        id: 'crew1_alice',
        crewId: 'crew1',
        userId: 'alice',
        role: 'owner',
        joinedAt: '2026-07-01T00:00:00Z',
        username: 'alice',
        displayName: 'Alice',
      });

      await testing.assertSucceeds(batch.commit());
      await testing.assertSucceeds(crewDoc.get());

      // Bob tries to read the crew but fails because he is not a member yet
      await testing.assertFails(bobDb.collection('crews').doc('crew1').get());

      // Bob tries to create membership directly without invitation and fails
      const bobMembership = bobDb.collection('crew_memberships').doc('crew1_bob');
      await testing.assertFails(bobMembership.set({
        id: 'crew1_bob',
        crewId: 'crew1',
        userId: 'bob',
        role: 'member',
        joinedAt: '2026-07-01T00:00:00Z',
        username: 'bob',
        displayName: 'Bob',
      }));
    });

    it('denies non-owner crew updates, deletes, and invitations', async () => {
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('charlie').set({
          username: 'charlie',
          displayName: 'Charlie',
          createdAt: '2026-07-01T00:00:00Z',
        });
        await adminDb.collection('crews').doc('crew1').set({
          id: 'crew1',
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: '2026-07-01T00:00:00Z',
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          id: 'crew1_alice',
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: '2026-07-01T00:00:00Z',
          username: 'alice',
          displayName: 'Alice',
        });
        await adminDb.collection('crew_memberships').doc('crew1_bob').set({
          id: 'crew1_bob',
          crewId: 'crew1',
          userId: 'bob',
          role: 'member',
          joinedAt: '2026-07-01T00:00:00Z',
          username: 'bob',
          displayName: 'Bob',
        });
      });

      await testing.assertFails(
        bobDb.collection('crews').doc('crew1').update({ name: 'Renamed Crew' }),
      );
      await testing.assertFails(bobDb.collection('crews').doc('crew1').delete());
      await testing.assertFails(
        bobDb.collection('crew_invitations').doc('crew1_charlie').set({
          id: 'crew1_charlie',
          crewId: 'crew1',
          invitedUserId: 'charlie',
          invitedByUserId: 'bob',
          createdAt: '2026-07-01T00:00:00Z',
          crewName: 'Weekend Hikers',
          invitedByUsername: 'bob',
          invitedByDisplayName: 'Bob',
          invitedUsername: 'charlie',
        }),
      );
    });

    it('allows owner to send invitations and invited user to accept membership', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt: '2026-07-01T00:00:00Z',
        });
        await adminDb.collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: '2026-07-01T00:00:00Z',
        });
        await adminDb.collection('crews').doc('crew1').set({
          id: 'crew1',
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: '2026-07-01T00:00:00Z',
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          id: 'crew1_alice',
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: '2026-07-01T00:00:00Z',
          username: 'alice',
          displayName: 'Alice',
        });
      });

      // Alice invites Bob
      const invitationDoc = aliceDb.collection('crew_invitations').doc('crew1_bob');
      await testing.assertSucceeds(invitationDoc.set({
        id: 'crew1_bob',
        crewId: 'crew1',
        invitedUserId: 'bob',
        invitedByUserId: 'alice',
        createdAt: '2026-07-01T00:00:00Z',
        crewName: 'Weekend Hikers',
        invitedByUsername: 'alice',
        invitedByDisplayName: 'Alice',
        invitedUsername: 'bob',
      }));

      // Bob reads the invitation
      await testing.assertSucceeds(bobDb.collection('crew_invitations').doc('crew1_bob').get());

      // Bob accepts the invitation: creates membership and deletes invitation
      const bobMembership = bobDb.collection('crew_memberships').doc('crew1_bob');
      await testing.assertSucceeds(bobMembership.set({
        id: 'crew1_bob',
        crewId: 'crew1',
        userId: 'bob',
        role: 'member',
        joinedAt: '2026-07-01T00:00:00Z',
        username: 'bob',
        displayName: 'Bob',
      }));
      await testing.assertSucceeds(bobDb.collection('crew_invitations').doc('crew1_bob').delete());

      // Now Bob is a member, he can read the crew details
      await testing.assertSucceeds(bobDb.collection('crews').doc('crew1').get());

      // Bob leaves the crew (deletes membership)
      await testing.assertSucceeds(bobDb.collection('crew_memberships').doc('crew1_bob').delete());

      // Owner cannot leave/delete their own membership directly (unless deleting the crew)
      await testing.assertFails(aliceDb.collection('crew_memberships').doc('crew1_alice').delete());
    });
  });
});
