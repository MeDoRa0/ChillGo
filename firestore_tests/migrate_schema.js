const path = require('path');

const projectId = 'chillgo-61439';
const shouldApply = process.argv.includes('--apply');
const firebaseToolsRoot = path.join(
  process.env.APPDATA,
  'npm',
  'node_modules',
  'firebase-tools',
  'lib',
);
const firebaseAuth = require(path.join(firebaseToolsRoot, 'auth.js'));
const firebaseApi = require(path.join(firebaseToolsRoot, 'apiv2.js'));
const firestoreApi = require(path.join(firebaseToolsRoot, 'gcp', 'firestore.js'));

const collectionDates = new Map([
  ['users', ['createdAt']],
  ['crews', ['createdAt']],
  ['crew_memberships', ['joinedAt']],
  ['crew_invitations', ['createdAt']],
  [
    'outings',
    ['scheduledAt', 'createdAt', 'updatedAt', 'cancelledAt', 'archivedAt'],
  ],
  ['outing_participants', ['addedAt']],
]);

function initializeFirebaseCliAuth() {
  const account = firebaseAuth.getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI authentication is required.');
  firebaseAuth.setActiveAccount({}, account);
}

async function readCollection(collectionName) {
  const query = { from: [{ collectionId: collectionName }] };
  const response = await firestoreApi.queryCollection(projectId, query);
  return response.documents;
}

function timestampFields(document, dateFields) {
  const fields = structuredClone(document.fields || {});
  for (const field of dateFields) {
    const rawDate = fields[field];
    if (!rawDate || rawDate.timestampValue) continue;
    if (!rawDate.stringValue) {
      throw new Error(`${document.name}.${field} has an unsupported date type.`);
    }
    const parsedDate = new Date(rawDate.stringValue);
    if (Number.isNaN(parsedDate.getTime())) {
      throw new Error(`${document.name}.${field} is not a valid date.`);
    }
    fields[field] = { timestampValue: parsedDate.toISOString() };
  }
  delete fields.id;
  return fields;
}

function synchronizeCachedProfile(fields, profiles) {
  const userId = fields.userId?.stringValue;
  if (!userId) return;
  const profile = profiles.get(userId);
  if (!profile) throw new Error(`Missing user profile for ${userId}.`);

  fields.username = structuredClone(profile.username);
  fields.displayName = structuredClone(profile.displayName);
  if (profile.avatarUrl && !profile.avatarUrl.nullValue) {
    fields.avatarUrl = structuredClone(profile.avatarUrl);
  } else {
    delete fields.avatarUrl;
  }
}

function fieldsChanged(before, after) {
  return JSON.stringify(before) !== JSON.stringify(after);
}

async function collectMigrations() {
  const users = await readCollection('users');
  const profiles = new Map(
    users.map((document) => [document.name.split('/').pop(), document.fields]),
  );
  const migrations = [];
  const counts = {};

  for (const [collectionName, dateFields] of collectionDates) {
    const documents = collectionName === 'users' ? users : await readCollection(collectionName);
    let changedDocuments = 0;
    for (const document of documents) {
      const fields = timestampFields(document, dateFields);
      if (collectionName === 'crew_memberships' || collectionName === 'outing_participants') {
        synchronizeCachedProfile(fields, profiles);
      }
      if (fieldsChanged(document.fields, fields)) {
        migrations.push({ document, fields });
        changedDocuments++;
      }
    }
    counts[collectionName] = {
      scanned: documents.length,
      changed: changedDocuments,
    };
  }
  return { migrations, counts };
}

async function applyMigrations(migrations) {
  const client = new firebaseApi.Client({
    auth: true,
    apiVersion: 'v1',
    urlPrefix: 'https://firestore.googleapis.com',
  });
  const commitPath = `projects/${projectId}/databases/(default)/documents:commit`;
  const batchLimit = 450;
  for (let start = 0; start < migrations.length; start += batchLimit) {
    const writes = migrations.slice(start, start + batchLimit).map(({ document, fields }) => ({
      update: { name: document.name, fields },
      currentDocument: { updateTime: document.updateTime },
    }));
    await client.post(commitPath, { writes });
  }
}

async function main() {
  initializeFirebaseCliAuth();
  const { migrations, counts } = await collectMigrations();
  console.table(counts);
  console.log(`${migrations.length} document(s) require migration.`);
  if (!shouldApply) {
    console.log('Dry run only. Pass --apply to commit these changes.');
    return;
  }
  await applyMigrations(migrations);
  console.log(`Migrated ${migrations.length} document(s) in ${projectId}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
