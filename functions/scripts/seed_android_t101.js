const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'chillgo-61439' });

const crewId = 'android-t101-crew';
const password = 'Android-T101-pass';
const users = [
  ['android-alice', 'alice@android.test', 'Alice', 'owner'],
  ['android-bob', 'bob@android.test', 'Bob', 'member'],
  ['android-carol', 'carol@android.test', 'Carol', 'member'],
];

async function seedUser(uid, email, displayName) {
  try {
    await getAuth().createUser({ uid, email, password, displayName });
  } catch (error) {
    if (error.code !== 'auth/uid-already-exists') throw error;
    await getAuth().updateUser(uid, { email, password, displayName });
  }
  await getFirestore().collection('users').doc(uid).set({
    username: uid,
    displayName,
    avatarUrl: null,
    createdAt: Timestamp.now(),
  });
}

async function clearSeedData() {
  const db = getFirestore();
  const writer = db.bulkWriter();
  for (const collectionName of [
    'agreement_commands',
    'agreement_results',
    'agreement_votes',
    'agreement_proposals',
    'agreement_rounds',
    'outing_participants',
    'outings',
    'crew_memberships',
    'crews',
  ]) {
    const snapshot = await db.collection(collectionName).get();
    for (const document of snapshot.docs) {
      const data = document.data();
      if (
        document.id.startsWith('android-') ||
        String(data.outingId ?? '').startsWith('android-') ||
        data.crewId === crewId
      ) {
        writer.delete(document.ref);
      }
    }
  }
  await writer.close();
}

function outingRecord(status, creator = 'android-bob') {
  const now = Timestamp.now();
  return {
    crewId,
    title: `Android ${status}`,
    scheduledAt: Timestamp.fromDate(new Date('2030-01-01T10:00:00Z')),
    locationText: 'Android Test Cafe',
    status,
    createdByUserId: creator,
    createdAt: now,
    updatedAt: now,
    agreementRoundSequence: 1,
  };
}

function participantRecord(outingId, uid, status = 'accepted') {
  const displayName = users.find(([id]) => id === uid)?.[2] || uid;
  return {
    outingId,
    crewId,
    userId: uid,
    username: uid,
    displayName,
    addedByUserId: 'android-bob',
    addedAt: Timestamp.now(),
    isCreatorParticipant: uid === 'android-bob',
    attendanceStatus: status,
    respondedAt: status === 'invited' ? null : Timestamp.now(),
  };
}

async function seedDeletionOuting(status) {
  const db = getFirestore();
  const outingId = `android-delete-${status}`;
  await db.collection('outings').doc(outingId).set(outingRecord(status));
  await db.collection('outing_participants').doc(`${outingId}_android-bob`).set(
    participantRecord(outingId, 'android-bob'),
  );
  for (const [collection, suffix] of [
    ['agreement_rounds', 'round'],
    ['agreement_proposals', 'proposal'],
    ['agreement_votes', 'vote'],
    ['agreement_results', 'result'],
  ]) {
    await db.collection(collection).doc(`${outingId}-${suffix}`).set({
      outingId,
      crewId,
      roundId: `${outingId}-round`,
    });
  }
}

async function seedPerformanceOuting() {
  const db = getFirestore();
  const outingId = 'android-performance';
  const roundId = `${outingId}_1`;
  await db.collection('outings').doc(outingId).set({
    ...outingRecord('planning'),
    activeAgreementRoundId: roundId,
  });
  for (const uid of ['android-bob', 'android-carol']) {
    await db.collection('outing_participants').doc(`${outingId}_${uid}`).set(
      participantRecord(outingId, uid),
    );
  }
  await db.collection('agreement_rounds').doc(roundId).set({
    outingId,
    crewId,
    sequence: 1,
    status: 'open',
    openedByUserId: 'android-bob',
    openedAt: Timestamp.now(),
  });
  for (const [id, category, value] of [
    ['android-time-a', 'time', Timestamp.fromDate(new Date('2030-01-01T10:00:00Z'))],
    ['android-time-b', 'time', Timestamp.fromDate(new Date('2030-01-02T10:00:00Z'))],
    ['android-location-a', 'location', 'Android Cafe'],
    ['android-location-b', 'location', 'Android Park'],
  ]) {
    await db.collection('agreement_proposals').doc(id).set({
      roundId,
      outingId,
      crewId,
      category,
      authorUserId: 'android-bob',
      authorDisplayName: 'Bob',
      normalizedKey: id,
      createdAt: Timestamp.now(),
      isSeed: false,
      ...(category === 'time' ? { timeValue: value } : { locationText: value }),
    });
  }
  await db.collection('agreement_votes').doc(`${roundId}_time_android-bob`).set({
    roundId,
    outingId,
    crewId,
    category: 'time',
    proposalId: 'android-time-a',
    userId: 'android-bob',
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
}

async function seedConfirmationOutings() {
  const db = getFirestore();
  const writer = db.bulkWriter();
  for (let index = 0; index < 100; index += 1) {
    const outingId = `android-confirm-${index}`;
    const roundId = `${outingId}_1`;
    const timeId = `${outingId}-time`;
    const locationId = `${outingId}-location`;
    writer.set(db.collection('outings').doc(outingId), {
      ...outingRecord('planning'),
      activeAgreementRoundId: roundId,
    });
    writer.set(db.collection('outing_participants').doc(`${outingId}_android-bob`), participantRecord(outingId, 'android-bob'));
    writer.set(db.collection('agreement_rounds').doc(roundId), {
      outingId, crewId, sequence: 1, status: 'open', openedByUserId: 'android-bob', openedAt: Timestamp.now(),
    });
    writer.set(db.collection('agreement_proposals').doc(timeId), {
      roundId, outingId, crewId, category: 'time', authorUserId: 'android-bob', authorDisplayName: 'Bob',
      normalizedKey: timeId, createdAt: Timestamp.now(), isSeed: false,
      timeValue: Timestamp.fromDate(new Date('2030-01-01T10:00:00Z')),
    });
    writer.set(db.collection('agreement_proposals').doc(locationId), {
      roundId, outingId, crewId, category: 'location', authorUserId: 'android-bob', authorDisplayName: 'Bob',
      normalizedKey: locationId, createdAt: Timestamp.now(), isSeed: false, locationText: 'Android Cafe',
    });
    for (const [category, proposalId] of [['time', timeId], ['location', locationId]]) {
      writer.set(db.collection('agreement_votes').doc(`${roundId}_${category}_android-bob`), {
        roundId, outingId, crewId, category, proposalId, userId: 'android-bob',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      });
    }
  }
  await writer.close();
}

async function seedDecisionOuting(outingId, { tie }) {
  const db = getFirestore();
  const roundId = `${outingId}_1`;
  const timeA = `${outingId}-time-a`;
  const timeB = `${outingId}-time-b`;
  const location = `${outingId}-location`;
  await db.collection('outings').doc(outingId).set({
    ...outingRecord('planning'),
    activeAgreementRoundId: roundId,
  });
  for (const uid of ['android-bob', 'android-carol']) {
    await db.collection('outing_participants').doc(`${outingId}_${uid}`).set(
      participantRecord(outingId, uid),
    );
  }
  await db.collection('agreement_rounds').doc(roundId).set({
    outingId, crewId, sequence: 1, status: 'open', openedByUserId: 'android-bob', openedAt: Timestamp.now(),
  });
  for (const [id, category, extra] of [
    [timeA, 'time', { timeValue: Timestamp.fromDate(new Date('2030-02-01T10:00:00Z')) }],
    [timeB, 'time', { timeValue: Timestamp.fromDate(new Date('2030-02-02T10:00:00Z')) }],
    [location, 'location', { locationText: 'Android Decision Cafe' }],
  ]) {
    await db.collection('agreement_proposals').doc(id).set({
      roundId, outingId, crewId, category, authorUserId: 'android-bob', authorDisplayName: 'Bob',
      normalizedKey: id, createdAt: Timestamp.now(), isSeed: false, ...extra,
    });
  }
  const votes = [
    ['android-bob', 'time', timeA],
    ['android-carol', 'time', tie ? timeB : timeA],
    ['android-bob', 'location', location],
    ['android-carol', 'location', location],
  ];
  for (const [uid, category, proposalId] of votes) {
    await db.collection('agreement_votes').doc(`${roundId}_${category}_${uid}`).set({
      roundId, outingId, crewId, category, proposalId, userId: uid,
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
  }
}

async function main() {
  for (const [uid, email, displayName] of users) await seedUser(uid, email, displayName);
  await clearSeedData();
  const db = getFirestore();
  await db.collection('crews').doc(crewId).set({
    name: 'Android T101 Crew',
    ownerId: 'android-alice',
    createdAt: Timestamp.now(),
  });
  for (const [uid, , displayName, role] of users) {
    await db.collection('crew_memberships').doc(`${crewId}_${uid}`).set({
      crewId, userId: uid, role, joinedAt: Timestamp.now(), username: uid, displayName,
    });
  }
  for (const status of ['draft', 'planning', 'confirmed', 'meeting', 'completed', 'archived', 'cancelled']) {
    await seedDeletionOuting(status);
  }
  await db.collection('outings').doc('android-owner-check').set(outingRecord('archived'));
  await db.collection('outing_participants').doc('android-owner-check_android-bob').set(
    participantRecord('android-owner-check', 'android-bob'),
  );
  await seedPerformanceOuting();
  await seedDecisionOuting('android-tie', { tie: true });
  await seedDecisionOuting('android-eligibility', { tie: true });
  await seedConfirmationOutings();
  console.log(JSON.stringify({ crewId, password, users: users.map(([uid, email]) => ({ uid, email })) }));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
