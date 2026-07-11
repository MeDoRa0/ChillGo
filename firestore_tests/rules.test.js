const testing = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'chillgo-61439';
const FIRESTORE_EMULATOR_PORT = Number(process.env.FIRESTORE_EMULATOR_PORT || 65080);
const STORAGE_EMULATOR_PORT = Number(process.env.STORAGE_EMULATOR_PORT || 65199);

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
        createdAt: new Date('2026-06-29T16:15:00.000Z'),
      }));
      await testing.assertSucceeds(aliceDoc.update({ displayName: 'Alice Smith' }));
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
      });
      batch.set(aliceMembership, {
        crewId: 'crew1',
        userId: 'alice',
        role: 'owner',
        joinedAt: new Date('2026-07-01T00:00:00Z'),
        username: 'alice',
        displayName: 'Alice',
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

    it('allows owner to update only the crew name', async () => {
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
        aliceDb.collection('crews').doc('crew1').update({ name: 'Trail Crew' }),
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
      });
      updateBatch.update(aliceDb.collection('crew_memberships').doc('crew1_alice'), {
        displayName: 'Alice Updated',
      });
      updateBatch.update(aliceDb.collection('outing_participants').doc('outing1_alice'), {
        displayName: 'Alice Updated',
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
        });
      });

      await testing.assertSucceeds(
        bobDb.collection('outing_participants').doc('outing1_bob').set({
          outingId: 'outing1',
          crewId: 'crew1',
          userId: 'bob',
          username: 'bob',
          displayName: 'Bob',
          addedByUserId: 'bob',
          addedAt: new Date('2026-07-01T00:00:00.000Z'),
          isCreatorParticipant: false,
        }),
      );
    });

    it('allows only the creator to delete an outing with its participants', async () => {
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

      const deleteBatch = aliceDb.batch();
      deleteBatch.delete(aliceDb.collection('outing_participants').doc('outing1_alice'));
      deleteBatch.delete(aliceDb.collection('outing_participants').doc('outing1_bob'));
      deleteBatch.delete(aliceDb.collection('outings').doc('outing1'));
      await testing.assertSucceeds(deleteBatch.commit());
    });
  });
});
