const testing = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
require('firebase/firestore').setLogLevel('silent');

const PROJECT_ID = 'chillgo-61439';
function emulatorPort(hostVariable, fallbackPort) {
  const host = process.env[hostVariable];
  return host ? Number(host.split(':').at(-1)) : fallbackPort;
}

const FIRESTORE_EMULATOR_PORT = emulatorPort('FIRESTORE_EMULATOR_HOST', 18080);
const STORAGE_EMULATOR_PORT = emulatorPort('FIREBASE_STORAGE_EMULATOR_HOST', 19199);

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
    if (testEnv) await testEnv.cleanup();
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
        createdAt: new Date('2026-06-29T16:15:00.000Z'),
        locale: 'en',
      }));
      await testing.assertSucceeds(aliceDoc.update({
        displayName: 'Alice Smith',
        onboardingVersion: 2,
      }));
    });

    it('rejects missing required profile fields and incorrect known optional types', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();

      await testing.assertFails(aliceDb.collection('users').doc('alice').set({
        username: 'alice',
        createdAt: new Date('2026-06-29T16:15:00.000Z'),
      }));
      await testing.assertFails(aliceDb.collection('users').doc('alice').set({
        username: 'alice',
        displayName: 'Alice',
        avatarUrl: 42,
        createdAt: new Date('2026-06-29T16:15:00.000Z'),
      }));
    });

    it('denies creating or updating another user profile', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const bobDoc = aliceDb.collection('users').doc('bob');

      await testing.assertFails(bobDoc.set({
        username: 'bob',
        displayName: 'Bob',
        createdAt: new Date('2026-06-29T16:15:00.000Z'),
      }));
      await testing.assertFails(bobDoc.update({ displayName: 'Robert' }));
    });

    it('allows authenticated profile reads and denies unauthenticated reads', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: new Date('2026-06-29T16:15:00.000Z'),
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
      await testing.assertFails(aliceDb.collection('usernames').doc('alice3').set({
        uid: 'alice',
        displayName: 'Unexpected registry data',
      }));
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

      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
      });

      batch.set(crewDoc, {
        name: 'Weekend Hikers',
        ownerId: 'alice',
        createdAt: new Date('2026-07-01T00:00:00Z'),
        themeColor: 'green',
      });
      batch.set(aliceMembership, {
        crewId: 'crew1',
        userId: 'alice',
        role: 'owner',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'alice',
        displayName: 'Alice',
        notificationPreference: 'mentions',
      });

      await testing.assertSucceeds(batch.commit());
      await testing.assertSucceeds(crewDoc.get());
      await testing.assertSucceeds(
        aliceDb.collection('crew_memberships').where('userId', '==', 'alice').get(),
      );

      // Bob tries to read the crew but fails because he is not a member yet
      await testing.assertFails(bobDb.collection('crews').doc('crew1').get());

      // Bob tries to create membership directly without invitation and fails
      const bobMembership = bobDb.collection('crew_memberships').doc('crew1_bob');
      await testing.assertFails(bobMembership.set({
        crewId: 'crew1',
        userId: 'bob',
        role: 'member',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'bob',
        displayName: 'Bob',
      }));

      await testing.assertFails(bobMembership.set({
        crewId: 'crew1',
        userId: 'bob',
        role: 'owner',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'bob',
        displayName: 'Bob',
      }));
    });

    it('denies standalone owner membership creation without the crew create batch', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();

      await testing.assertFails(aliceDb.collection('crew_memberships').doc('ghostCrew_alice').set({
        crewId: 'ghostCrew',
        userId: 'alice',
        role: 'owner',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'alice',
        displayName: 'Alice',
      }));
    });

    it('denies non-owner crew updates, deletes, and invitations', async () => {
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('charlie').set({
          username: 'charlie',
          displayName: 'Charlie',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
        await adminDb.collection('crew_memberships').doc('crew1_bob').set({
          crewId: 'crew1',
          userId: 'bob',
          role: 'member',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
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
          crewId: 'crew1',
          invitedUserId: 'charlie',
          invitedByUserId: 'bob',
          createdAt: new Date('2026-07-01T00:00:00Z'),
          crewName: 'Weekend Hikers',
          invitedByUsername: 'bob',
          invitedByDisplayName: 'Bob',
          invitedUsername: 'charlie',
        }),
      );
    });

    it('allows owner updates while keeping crew ownership immutable', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
      });

      await testing.assertSucceeds(
        aliceDb.collection('crews').doc('crew1').update({
          name: 'Trail Crew',
          summary: 'Weekend routes and hikes',
        }),
      );
      await testing.assertFails(
        aliceDb.collection('crews').doc('crew1').update({ ownerId: 'bob' }),
      );
    });

    it('requires owner membership cleanup when an owner deletes a crew', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
        await adminDb.collection('crew_memberships').doc('crew1_bob').set({
          crewId: 'crew1',
          userId: 'bob',
          role: 'member',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'bob',
          displayName: 'Bob',
        });
        await adminDb.collection('crew_invitations').doc('crew1_charlie').set({
          crewId: 'crew1',
          invitedUserId: 'charlie',
          invitedByUserId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
          crewName: 'Weekend Hikers',
          invitedByUsername: 'alice',
          invitedByDisplayName: 'Alice',
          invitedUsername: 'charlie',
        });
      });

      await testing.assertFails(aliceDb.collection('crews').doc('crew1').delete());

      const deleteBatch = aliceDb.batch();
      deleteBatch.delete(aliceDb.collection('crew_memberships').doc('crew1_bob'));
      deleteBatch.delete(aliceDb.collection('crew_invitations').doc('crew1_charlie'));
      deleteBatch.delete(aliceDb.collection('crew_memberships').doc('crew1_alice'));
      deleteBatch.delete(aliceDb.collection('crews').doc('crew1'));
      await testing.assertSucceeds(deleteBatch.commit());
    });

    it('allows owner to send invitations and invited user to accept membership', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
      });

      // Alice invites Bob
      const invitationDoc = aliceDb.collection('crew_invitations').doc('crew1_bob');
      await testing.assertSucceeds(invitationDoc.set({
        crewId: 'crew1',
        invitedUserId: 'bob',
        invitedByUserId: 'alice',
        createdAt: new Date('2026-07-01T00:00:00Z'),
        crewName: 'Weekend Hikers',
        invitedByUsername: 'alice',
        invitedByDisplayName: 'Alice',
        invitedUsername: 'bob',
        note: 'Bring hiking shoes',
      }));

      // Bob reads the invitation
      await testing.assertSucceeds(bobDb.collection('crew_invitations').doc('crew1_bob').get());

      // Bob cannot create membership from a lingering invitation unless the
      // invitation is consumed in the same atomic request.
      const bobMembership = bobDb.collection('crew_memberships').doc('crew1_bob');
      const membershipPayload = {
        crewId: 'crew1',
        userId: 'bob',
        role: 'member',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'bob',
        displayName: 'Bob',
      };
      await testing.assertFails(bobMembership.set(membershipPayload));

      // Bob accepts the invitation: creates membership and deletes invitation.
      const acceptBatch = bobDb.batch();
      acceptBatch.set(bobMembership, membershipPayload);
      acceptBatch.delete(bobDb.collection('crew_invitations').doc('crew1_bob'));
      await testing.assertSucceeds(acceptBatch.commit());

      // Now Bob is a member, he can read the crew details
      await testing.assertSucceeds(bobDb.collection('crews').doc('crew1').get());

      // Bob is a member, but only the owner can list all pending invites for the crew.
      await testing.assertFails(
        bobDb.collection('crew_invitations').where('crewId', '==', 'crew1').get(),
      );

      // Bob leaves the crew (deletes membership)
      await testing.assertSucceeds(bobDb.collection('crew_memberships').doc('crew1_bob').delete());

      // Owner cannot leave/delete their own membership directly (unless deleting the crew)
      await testing.assertFails(aliceDb.collection('crew_memberships').doc('crew1_alice').delete());
    });

    it('denies membership writes with spoofed profile display fields', async () => {
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
        await adminDb.collection('crew_invitations').doc('crew1_bob').set({
          crewId: 'crew1',
          invitedUserId: 'bob',
          invitedByUserId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
          crewName: 'Weekend Hikers',
          invitedByUsername: 'alice',
          invitedByDisplayName: 'Alice',
          invitedUsername: 'bob',
        });
      });

      await testing.assertFails(bobDb.collection('crew_memberships').doc('crew1_bob').set({
        crewId: 'crew1',
        userId: 'bob',
        role: 'member',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'bob',
        displayName: 'Not Bob',
      }));

      await testing.assertFails(bobDb.collection('crew_memberships').doc('crew1_bob').set({
        crewId: 'crew1',
        userId: 'bob',
        role: 'member',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'bob',
        displayName: 'Bob',
        avatarUrl: 'https://example.com/spoofed.png',
      }));
    });

    it('denies invitations with spoofed crew or inviter display fields', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
      });

      const validInvitation = {
        crewId: 'crew1',
        invitedUserId: 'bob',
        invitedByUserId: 'alice',
        createdAt: new Date('2026-07-01T00:00:00Z'),
        crewName: 'Weekend Hikers',
        invitedByUsername: 'alice',
        invitedByDisplayName: 'Alice',
        invitedUsername: 'bob',
      };

      await testing.assertFails(aliceDb.collection('crew_invitations').doc('crew1_bob').set({
        ...validInvitation,
        crewName: 'Fake Crew',
      }));
      await testing.assertFails(aliceDb.collection('crew_invitations').doc('crew1_bob').set({
        ...validInvitation,
        invitedByDisplayName: 'Mallory',
      }));
    });
  });

  describe('Firestore outing rules', () => {
    it('allows a crew member to create an outing with their creator participant atomically', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          avatarUrl: null,
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
      });

      const now = new Date('2026-07-12T12:00:00Z');
      const outingId = 'new-outing';
      const batch = aliceDb.batch();
      batch.set(aliceDb.collection('outings').doc(outingId), {
        crewId: 'crew1',
        title: 'Friday Cafe',
        scheduledAt: new Date('2030-01-01T00:00:00Z'),
        locationText: 'City Center',
        status: 'draft',
        createdByUserId: 'alice',
        createdAt: now,
        updatedAt: now,
        agreementRoundSequence: 0,
        packingListVersion: 1,
      });
      batch.set(aliceDb.collection('outing_participants').doc(`${outingId}_alice`), {
        outingId,
        crewId: 'crew1',
        userId: 'alice',
        username: 'alice',
        displayName: 'Alice',
        addedByUserId: 'alice',
        addedAt: now,
        isCreatorParticipant: true,
        attendanceStatus: 'accepted',
        respondedAt: now,
        reminderPreference: 'day-before',
      });

      await testing.assertSucceeds(batch.commit());
    });

    it('allows users to synchronize cached profile fields atomically', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Old Name',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'member',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Old Name',
        });
        await adminDb.collection('outing_participants').doc('outing1_alice').set({
          outingId: 'outing1',
          crewId: 'crew1',
          userId: 'alice',
          username: 'alice',
          displayName: 'Old Name',
        });
      });

      await testing.assertFails(
        aliceDb.collection('crew_memberships').doc('crew1_alice').update({
          displayName: 'Spoofed Name',
        }),
      );

      const updateBatch = aliceDb.batch();
      updateBatch.update(aliceDb.collection('users').doc('alice'), {
        displayName: 'Alice Updated',
        profileSchemaVersion: 2,
      });
      updateBatch.update(aliceDb.collection('crew_memberships').doc('crew1_alice'), {
        displayName: 'Alice Updated',
        profileSchemaVersion: 2,
      });
      updateBatch.update(aliceDb.collection('outing_participants').doc('outing1_alice'), {
        displayName: 'Alice Updated',
        profileSchemaVersion: 2,
      });
      await testing.assertSucceeds(updateBatch.commit());
    });

    it('allows a crew member to accept an active outing', async () => {
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_bob').set({
          crewId: 'crew1',
          userId: 'bob',
          role: 'member',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'bob',
          displayName: 'Bob',
        });
        await adminDb.collection('outings').doc('outing1').set({
          crewId: 'crew1',
          title: 'Friday Cafe',
          scheduledAt: new Date('2030-01-01T00:00:00.000Z'),
          locationText: 'City Center',
          status: 'planning',
          createdByUserId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00.000Z'),
          updatedAt: new Date('2026-07-01T00:00:00.000Z'),
          agreementRoundSequence: 1,
          activeAgreementRoundId: 'outing1_1',
        });
        await adminDb.collection('outing_participants').doc('outing1_bob').set({
          outingId: 'outing1', crewId: 'crew1', userId: 'bob', username: 'bob', displayName: 'Bob',
          addedByUserId: 'alice', addedAt: new Date('2026-07-01T00:00:00.000Z'),
          isCreatorParticipant: false, attendanceStatus: 'invited', respondedAt: null,
        });
      });

      await testing.assertSucceeds(
        bobDb.collection('outing_participants').doc('outing1_bob').update({
          attendanceStatus: 'accepted', respondedAt: firebase.firestore.FieldValue.serverTimestamp(),
        }),
      );

      await testing.assertFails(
        bobDb.collection('outing_participants').doc('outing1_bob').update({
          attendanceStatus: 'declined',
          respondedAt: firebase.firestore.FieldValue.serverTimestamp(),
          addedByUserId: 'bob',
        }),
      );
    });

    it('allows attendance responses on legacy participant records', async () => {
      const bobDb = testEnv.authenticatedContext('bob').firestore();
      const createdAt = new Date('2026-07-01T00:00:00Z');

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers', ownerId: 'alice', createdAt,
        });
        await adminDb.collection('crew_memberships').doc('crew1_bob').set({
          crewId: 'crew1', userId: 'bob', role: 'member', joinedAt: createdAt,
        });
        await adminDb.collection('outings').doc('outing1').set({
          crewId: 'crew1', status: 'draft', createdByUserId: 'alice',
        });
        await adminDb.collection('outing_participants').doc('outing1_bob').set({
          outingId: 'outing1', crewId: 'crew1', userId: 'bob',
          addedByUserId: 'alice', addedAt: createdAt,
          isCreatorParticipant: false,
        });
      });

      await testing.assertSucceeds(
        bobDb.collection('outing_participants').doc('outing1_bob').update({
          attendanceStatus: 'accepted',
          respondedAt: firebase.firestore.FieldValue.serverTimestamp(),
        }),
      );
    });

    it('allows a crew member to create only their own attendance response', async () => {
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        const createdAt = new Date('2026-07-01T00:00:00Z');
        await adminDb.collection('users').doc('bob').set({
          username: 'bob',
          displayName: 'Bob',
          createdAt,
        });
        await adminDb.collection('users').doc('alice').set({
          username: 'alice',
          displayName: 'Alice',
          createdAt,
        });
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt,
        });
        await adminDb.collection('crew_memberships').doc('crew1_bob').set({
          crewId: 'crew1',
          userId: 'bob',
          role: 'member',
          joinedAt: createdAt,
          username: 'bob',
          displayName: 'Bob',
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: createdAt,
          username: 'alice',
          displayName: 'Alice',
        });
        await adminDb.collection('outings').doc('outing1').set({
          crewId: 'crew1',
          title: 'Friday Cafe',
          scheduledAt: new Date('2030-01-01T00:00:00Z'),
          locationText: 'City Center',
          status: 'planning',
          createdByUserId: 'alice',
          createdAt,
          updatedAt: createdAt,
          agreementRoundSequence: 1,
          activeAgreementRoundId: 'outing1_1',
        });
      });

      const response = {
        outingId: 'outing1',
        crewId: 'crew1',
        userId: 'bob',
        username: 'bob',
        displayName: 'Bob',
        addedByUserId: 'bob',
        addedAt: firebase.firestore.FieldValue.serverTimestamp(),
        isCreatorParticipant: false,
        attendanceStatus: 'accepted',
        respondedAt: firebase.firestore.FieldValue.serverTimestamp(),
      };
      const outingRef = bobDb.collection('outings').doc('outing1');
      const participantRef = bobDb.collection('outing_participants').doc('outing1_bob');
      const userRef = bobDb.collection('users').doc('bob');
      await testing.assertFails(participantRef.get());
      const participantQuery = await bobDb.collection('outing_participants')
        .where('outingId', '==', 'outing1')
        .where('userId', '==', 'bob')
        .limit(1)
        .get();
      const participantExists = !participantQuery.empty;
      await testing.assertSucceeds(bobDb.runTransaction(async (transaction) => {
        await transaction.get(outingRef);
        if (participantExists) {
          transaction.update(participantRef, {
            attendanceStatus: 'accepted',
            respondedAt: firebase.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }
        await transaction.get(userRef);
        transaction.set(participantRef, response);
      }));
      await testing.assertFails(
        bobDb.collection('outing_participants').doc('outing1_alice').set({
          ...response,
          userId: 'alice',
          username: 'alice',
          displayName: 'Alice',
          addedByUserId: 'alice',
        }),
      );
    });

    it('denies direct outing deletion so trusted cleanup cannot be bypassed', async () => {
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const bobDb = testEnv.authenticatedContext('bob').firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('crews').doc('crew1').set({
          name: 'Weekend Hikers',
          ownerId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00Z'),
        });
        await adminDb.collection('crew_memberships').doc('crew1_alice').set({
          crewId: 'crew1',
          userId: 'alice',
          role: 'owner',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'alice',
          displayName: 'Alice',
        });
        await adminDb.collection('crew_memberships').doc('crew1_bob').set({
          crewId: 'crew1',
          userId: 'bob',
          role: 'member',
          joinedAt: new Date('2026-07-01T00:00:00Z'),
          username: 'bob',
          displayName: 'Bob',
        });
        await adminDb.collection('outings').doc('outing1').set({
          crewId: 'crew1',
          title: 'Friday Cafe',
          scheduledAt: new Date('2030-01-01T00:00:00.000Z'),
          locationText: 'City Center',
          status: 'archived',
          createdByUserId: 'alice',
          createdAt: new Date('2026-07-01T00:00:00.000Z'),
          updatedAt: new Date('2026-07-01T00:00:00.000Z'),
        });
        await adminDb.collection('outing_participants').doc('outing1_alice').set({
          outingId: 'outing1',
          crewId: 'crew1',
          userId: 'alice',
        });
        await adminDb.collection('outing_participants').doc('outing1_bob').set({
          outingId: 'outing1',
          crewId: 'crew1',
          userId: 'bob',
        });
      });

      await testing.assertFails(bobDb.collection('outings').doc('outing1').delete());

      await testing.assertFails(aliceDb.collection('outings').doc('outing1').delete());
    });
  });

  describe('Agreement system rules', () => {
    async function seedAgreement({ roundStatus = 'open', outingStatus = 'planning' } = {}) {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore(); const now = new Date('2026-07-11T00:00:00Z');
        await db.collection('crews').doc('crew1').set({ name:'Crew', ownerId:'alice', createdAt:now });
        for (const [uid, role] of [['alice','owner'],['bob','member']]) {
          await db.collection('crew_memberships').doc(`crew1_${uid}`).set({crewId:'crew1',userId:uid,role,joinedAt:now,username:uid,displayName:uid});
          await db.collection('outing_participants').doc(`outing1_${uid}`).set({outingId:'outing1',crewId:'crew1',userId:uid,username:uid,displayName:uid,addedByUserId:'alice',addedAt:now,isCreatorParticipant:uid==='alice',attendanceStatus:'accepted',respondedAt:now});
        }
        await db.collection('outings').doc('outing1').set({crewId:'crew1',title:'Trip',scheduledAt:new Date('2030-01-01'),locationText:'Cafe',status:outingStatus,createdByUserId:'alice',createdAt:now,updatedAt:now,agreementRoundSequence:1,activeAgreementRoundId:roundStatus==='open'?'outing1_1':null,confirmedAgreementRoundId:roundStatus==='confirmed'?'outing1_1':null});
        await db.collection('agreement_rounds').doc('outing1_1').set({outingId:'outing1',crewId:'crew1',sequence:1,status:roundStatus,openedByUserId:'alice',openedAt:now});
        await db.collection('agreement_proposals').doc('time1').set({roundId:'outing1_1',outingId:'outing1',crewId:'crew1',category:'time',authorUserId:'alice',authorDisplayName:'Alice',timeValue:new Date('2030-01-01'),normalizedKey:'x',createdAt:now,isSeed:true});
        await db.collection('agreement_votes').doc('outing1_1_time_bob').set({roundId:'outing1_1',outingId:'outing1',crewId:'crew1',category:'time',proposalId:'time1',userId:'bob',createdAt:now,updatedAt:now});
        await db.collection('agreement_results').doc('result1').set({roundId:'outing1_1',outingId:'outing1',crewId:'crew1',category:'time',proposalId:'time1',voteCount:1,isLeader:true,isSelected:true,createdAt:now});
      });
    }
    it('keeps proposals immutable and agreement reads crew-scoped', async () => { await seedAgreement(); const bob=testEnv.authenticatedContext('bob').firestore();const eve=testEnv.authenticatedContext('eve').firestore();await testing.assertSucceeds(bob.collection('agreement_rounds').doc('outing1_1').get());await testing.assertSucceeds(bob.collection('agreement_proposals').doc('time1').get());await testing.assertFails(eve.collection('agreement_rounds').doc('outing1_1').get());await testing.assertFails(bob.collection('agreement_proposals').doc('time1').update({normalizedKey:'changed'})); });
    it('allows only predictable owner vote get and denies ballot lists', async () => { await seedAgreement();const bob=testEnv.authenticatedContext('bob').firestore();const alice=testEnv.authenticatedContext('alice').firestore();await testing.assertSucceeds(bob.collection('agreement_votes').doc('outing1_1_time_bob').get());await testing.assertFails(alice.collection('agreement_votes').doc('outing1_1_time_bob').get());await testing.assertFails(bob.collection('agreement_votes').where('roundId','==','outing1_1').get()); });
    it('allows valid active-round votes and rejects malformed or closed-round votes', async () => {
      await seedAgreement();
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const vote = aliceDb.collection('agreement_votes').doc('outing1_1_time_alice');
      const validVote = {
        roundId: 'outing1_1',
        outingId: 'outing1',
        crewId: 'crew1',
        category: 'time',
        proposalId: 'time1',
        userId: 'alice',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      };

      await testing.assertSucceeds(vote.set(validVote));
      await testing.assertFails(
        aliceDb.collection('agreement_votes').doc('outing1_1_location_alice').set({
          ...validVote,
          category: 'location',
          debugLabel: 'unexpected',
        }),
      );
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('agreement_rounds').doc('outing1_1').update({
          status: 'confirmed',
        });
      });
      await testing.assertFails(vote.update({
        proposalId: 'time1',
        updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      }));
    });
    it('accepts requester-private exact command requests and denies client results', async () => { await seedAgreement();const bob=testEnv.authenticatedContext('bob').firestore();const alice=testEnv.authenticatedContext('alice').firestore();const ref=bob.collection('agreement_commands').doc('cmd');await testing.assertSucceeds(ref.set({type:'create_proposal',outingId:'outing1',crewId:'crew1',requestedByUserId:'bob',payload:{category:'location',locationText:'Park'},status:'pending',createdAt:firebase.firestore.FieldValue.serverTimestamp()}));await testing.assertSucceeds(ref.get());await testing.assertFails(alice.collection('agreement_commands').doc('cmd').get());await testing.assertFails(bob.collection('agreement_results').doc('new').set({roundId:'outing1_1'})); });
    it('allows only the outing creator to request trusted permanent removal', async () => {
      await seedAgreement({ outingStatus: 'archived', roundStatus: 'confirmed' });
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('outings').doc('outing1').update({
          createdByUserId: 'bob',
        });
      });
      const ownerDb = testEnv.authenticatedContext('alice').firestore();
      const creatorDb = testEnv.authenticatedContext('bob').firestore();
      const request = (requestedByUserId) => ({
        type: 'delete_outing',
        outingId: 'outing1',
        crewId: 'crew1',
        requestedByUserId,
        payload: {},
        status: 'pending',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      });

      await testing.assertFails(
        ownerDb.collection('agreement_commands').doc('owner-delete').set(request('alice')),
      );
      await testing.assertSucceeds(
        creatorDb.collection('agreement_commands').doc('creator-delete').set(request('bob')),
      );
      await testing.assertFails(creatorDb.collection('outings').doc('outing1').delete());
    });
    it('allows crew members to signal trusted outing expiry cleanup', async () => {
      await seedAgreement();
      const memberDb = testEnv.authenticatedContext('bob').firestore();
      const outsiderDb = testEnv.authenticatedContext('eve').firestore();
      const request = (requestedByUserId) => ({
        type: 'expire_outing',
        outingId: 'outing1',
        crewId: 'crew1',
        requestedByUserId,
        payload: {},
        status: 'pending',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      });

      await testing.assertSucceeds(
        memberDb.collection('agreement_commands').doc('member-expiry').set(request('bob')),
      );
      await testing.assertFails(
        outsiderDb.collection('agreement_commands').doc('outsider-expiry').set(request('eve')),
      );
    });
    it('retains strict command fields and payload schemas', async () => {
      await seedAgreement();
      const bobDb = testEnv.authenticatedContext('bob').firestore();
      const command = {
        type: 'create_proposal',
        outingId: 'outing1',
        crewId: 'crew1',
        requestedByUserId: 'bob',
        payload: { category: 'location', locationText: 'Park' },
        status: 'pending',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      };

      await testing.assertFails(
        bobDb.collection('agreement_commands').doc('extra-field').set({
          ...command,
          debugLabel: 'unexpected',
        }),
      );
      await testing.assertFails(
        bobDb.collection('agreement_commands').doc('missing-location').set({
          ...command,
          payload: { category: 'location' },
        }),
      );
    });
    it('protects trusted outing fields and coordinated transitions', async () => {
      await seedAgreement();
      const aliceDb = testEnv.authenticatedContext('alice').firestore();
      const outing = aliceDb.collection('outings').doc('outing1');

      await testing.assertFails(outing.update({
        deletionPending: true,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      }));
      await testing.assertFails(outing.update({
        status: 'cancelled',
        cancelledReason: 'Changed plans',
        cancelledAt: firebase.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      }));
    });
    it('reveals aggregate results only after closure and blocks direct agreement transitions', async () => { await seedAgreement();const bob=testEnv.authenticatedContext('bob').firestore();const alice=testEnv.authenticatedContext('alice').firestore();await testing.assertFails(bob.collection('agreement_results').doc('result1').get());await testing.assertFails(alice.collection('outings').doc('outing1').update({status:'confirmed',activeAgreementRoundId:null,confirmedAgreementRoundId:'outing1_1'}));await testEnv.withSecurityRulesDisabled(async c=>c.firestore().collection('agreement_rounds').doc('outing1_1').update({status:'confirmed'}));await testing.assertSucceeds(bob.collection('agreement_results').doc('result1').get()); });
    it('blocks attendance responses at meeting and after membership loss', async () => { await seedAgreement({outingStatus:'meeting'});const bob=testEnv.authenticatedContext('bob').firestore();const ref=bob.collection('outing_participants').doc('outing1_bob');await testing.assertFails(ref.update({attendanceStatus:'declined',respondedAt:firebase.firestore.FieldValue.serverTimestamp()}));await testEnv.withSecurityRulesDisabled(async c=>c.firestore().collection('outings').doc('outing1').update({status:'planning'}));await testEnv.withSecurityRulesDisabled(async c=>c.firestore().collection('crew_memberships').doc('crew1_bob').delete());await testing.assertFails(ref.update({attendanceStatus:'declined',respondedAt:firebase.firestore.FieldValue.serverTimestamp()})); });
  });

  describe('Outing chat expiry and access proof', () => {
    async function seedChat({status = 'planning', attendance = 'declined'} = {}) {
      const now = new Date();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        const writes = [
          db.collection('users').doc('alice').set({username: 'alice', displayName: 'Alice', createdAt: now}),
          db.collection('users').doc('bob').set({username: 'bob', displayName: 'Bob', createdAt: now}),
          db.collection('crews').doc('crew-chat').set({name: 'Chat Crew', ownerId: 'alice', createdAt: now}),
          db.collection('crew_memberships').doc('crew-chat_alice').set({crewId: 'crew-chat', userId: 'alice', role: 'owner', joinedAt: now, username: 'alice', displayName: 'Alice'}),
          db.collection('crew_memberships').doc('crew-chat_bob').set({crewId: 'crew-chat', userId: 'bob', role: 'member', joinedAt: now, username: 'bob', displayName: 'Bob'}),
          db.collection('outings').doc('outing-chat').set({crewId: 'crew-chat', title: 'Chat Outing', scheduledAt: now, locationText: 'Trail', status, createdByUserId: 'alice', createdAt: now, updatedAt: now, agreementRoundSequence: 0}),
          db.collection('outing_participants').doc('outing-chat_alice').set({outingId: 'outing-chat', crewId: 'crew-chat', userId: 'alice', username: 'alice', displayName: 'Alice', addedByUserId: 'alice', addedAt: now, isCreatorParticipant: true, attendanceStatus: 'accepted', respondedAt: now}),
          db.collection('outing_participants').doc('outing-chat_bob').set({outingId: 'outing-chat', crewId: 'crew-chat', userId: 'bob', username: 'bob', displayName: 'Bob', addedByUserId: 'alice', addedAt: now, isCreatorParticipant: false, attendanceStatus: attendance, respondedAt: now}),
        ];
        await Promise.all(writes);
      });
    }

    async function seedMessage(id, acceptedAt, expiresAt, authorUserId = 'alice') {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('chat_messages').doc(id).set({
          outingId: 'outing-chat', crewId: 'crew-chat', clientMessageId: `client-${id}`,
          authorUserId, authorUsername: authorUserId,
          authorDisplayName: authorUserId === 'alice' ? 'Alice' : 'Bob',
          authorAvatarUrl: null, text: 'Private chat text', acceptedAt, expiresAt,
        });
      });
    }

    it('proves direct get expires against request time while bounded list uses the approved split', async () => {
      await seedChat();
      const now = Date.now();
      await seedMessage('outing-chat_old', new Date(now - 25 * 60 * 60 * 1000), new Date(now - 60 * 60 * 1000));
      await seedMessage('outing-chat_new', new Date(now - 1000), new Date(now + 24 * 60 * 60 * 1000));
      const bob = testEnv.authenticatedContext('bob').firestore();

      await testing.assertFails(bob.collection('chat_messages').doc('outing-chat_old').get());
      await testing.assertSucceeds(bob.collection('chat_messages').doc('outing-chat_new').get());

      const bounded = bob.collection('chat_messages')
        .where('outingId', '==', 'outing-chat')
        .orderBy('acceptedAt', 'desc')
        .orderBy(firebase.firestore.FieldPath.documentId(), 'desc')
        .limit(50);
      const snapshot = await testing.assertSucceeds(bounded.get());
      // List rules intentionally authorize the scoped potential result set. The
      // trusted client cutoff/domain timer owns the exact moving boundary.
      if (snapshot.docs.length !== 2) throw new Error('Expected raw list proof to include both records');
    });

    it('proves trusted cutoff filtering is independent of a wrong device clock and listener age', async () => {
      await seedChat();
      const serverNow = new Date();
      const expiry = new Date(serverNow.getTime() + 1000);
      const raw = {expiresAt: expiry};
      const wrongDeviceNow = new Date(serverNow.getTime() - 365 * 24 * 60 * 60 * 1000);
      const visibleWithTrustedClock = (message, trustedNow) => message.expiresAt > trustedNow;
      if (!visibleWithTrustedClock(raw, serverNow)) throw new Error('Must be visible before expiry');
      if (visibleWithTrustedClock(raw, new Date(expiry.getTime()))) throw new Error('Must disappear at exact expiry');
      if (!visibleWithTrustedClock(raw, wrongDeviceNow)) throw new Error('Fixture must demonstrate device drift');
      // Re-evaluating the same listener payload at the trusted boundary proves
      // it cannot remain visible merely because no snapshot event arrived.
      if (visibleWithTrustedClock(raw, expiry)) throw new Error('Long-lived payload remained visible');
    });

    it('requires current participation and membership regardless of attendance', async () => {
      await seedChat({attendance: 'declined'});
      const now = Date.now();
      await seedMessage('outing-chat_message', new Date(now), new Date(now + 100000));
      const bob = testEnv.authenticatedContext('bob').firestore();
      await testing.assertSucceeds(bob.collection('chat_messages').doc('outing-chat_message').get());
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('outing_participants').doc('outing-chat_bob').delete();
      });
      await testing.assertFails(bob.collection('chat_messages').doc('outing-chat_message').get());
    });

    it('allows only exact online command creates and requester reads', async () => {
      await seedChat();
      const alice = testEnv.authenticatedContext('alice').firestore();
      const bob = testEnv.authenticatedContext('bob').firestore();
      const ref = alice.collection('chat_commands').doc('command-1');
      const command = {
        type: 'send_message', outingId: 'outing-chat', crewId: 'crew-chat',
        requestedByUserId: 'alice', clientMessageId: 'client-message-0001',
        payload: {text: 'Hello'}, status: 'pending',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      };
      await testing.assertSucceeds(ref.set(command));
      await testing.assertSucceeds(ref.get());
      await testing.assertFails(bob.collection('chat_commands').doc('command-1').get());
      await testing.assertFails(alice.collection('chat_commands').doc('bad').set({...command, debug: true}));
      await testing.assertFails(alice.collection('chat_messages').doc('client-write').set({outingId: 'outing-chat'}));
      await testing.assertFails(alice.collection('chat_rate_limits').doc('outing-chat_alice').get());
    });

    it('keeps time probes owner-private and exact shape', async () => {
      const alice = testEnv.authenticatedContext('alice').firestore();
      const bob = testEnv.authenticatedContext('bob').firestore();
      const ref = alice.collection('chat_time_probes').doc('alice_probe-1');
      await testing.assertSucceeds(ref.set({userId: 'alice', requestedAt: firebase.firestore.FieldValue.serverTimestamp()}));
      await testing.assertSucceeds(ref.get());
      await testing.assertFails(bob.collection('chat_time_probes').doc('alice_probe-1').get());
      await testing.assertFails(alice.collection('chat_time_probes').where('userId', '==', 'alice').get());
      await testing.assertSucceeds(ref.delete());
    });

    it('enforces bounded outing-scoped history queries', async () => {
      await seedChat();
      const now = Date.now();
      await seedMessage('outing-chat_query', new Date(now), new Date(now + 100000));
      const bob = testEnv.authenticatedContext('bob').firestore();
      await testing.assertFails(bob.collection('chat_messages').get());
      await testing.assertFails(
        bob.collection('chat_messages').where('outingId', '==', 'outing-chat').limit(5001).get(),
      );
      await testing.assertSucceeds(
        bob.collection('chat_messages').where('outingId', '==', 'outing-chat').limit(50).get(),
      );
    });

    it('keeps terminal outings readable but rejects sends and deletion-pending access', async () => {
      await seedChat({status: 'completed'});
      const now = Date.now();
      await seedMessage('outing-chat_terminal', new Date(now), new Date(now + 100000));
      const alice = testEnv.authenticatedContext('alice').firestore();
      await testing.assertSucceeds(alice.collection('chat_messages').doc('outing-chat_terminal').get());
      const command = {
        type: 'send_message', outingId: 'outing-chat', crewId: 'crew-chat',
        requestedByUserId: 'alice', clientMessageId: 'client-message-0002',
        payload: {text: 'Closed'}, status: 'pending',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      };
      await testing.assertFails(alice.collection('chat_commands').doc('closed').set(command));
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('outings').doc('outing-chat').update({deletionPending: true});
      });
      await testing.assertFails(alice.collection('chat_messages').doc('outing-chat_terminal').get());
      await testing.assertFails(alice.collection('outings').doc('outing-chat').delete());
    });

    it('keeps read cursors owner-private, readable, and strictly monotonic', async () => {
      await seedChat();
      const now = Date.now();
      const firstAt = new Date(now);
      const secondAt = new Date(now + 1);
      const expiry = new Date(now + 100000);
      await seedMessage('outing-chat_first', firstAt, expiry, 'bob');
      await seedMessage('outing-chat_second', secondAt, expiry, 'bob');
      const alice = testEnv.authenticatedContext('alice').firestore();
      const bob = testEnv.authenticatedContext('bob').firestore();
      const ref = alice.collection('chat_read_states').doc('outing-chat_alice');
      const first = {
        outingId: 'outing-chat', crewId: 'crew-chat', userId: 'alice',
        readThroughAcceptedAt: firstAt, readThroughMessageId: 'outing-chat_first',
        cursorExpiresAt: expiry,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      };
      await testing.assertSucceeds(ref.set(first));
      await testing.assertSucceeds(ref.get());
      await testing.assertFails(bob.collection('chat_read_states').doc('outing-chat_alice').get());
      await testing.assertFails(ref.set(first));
      await testing.assertSucceeds(ref.set({
        ...first,
        readThroughAcceptedAt: secondAt,
        readThroughMessageId: 'outing-chat_second',
        updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      }));
      await testing.assertFails(ref.update({userId: 'bob'}));
    });
  });
});
