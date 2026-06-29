const testing = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'chillgo-61439';

describe('Firestore Security Rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it('should allow user to read/write their own document', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    const aliceDoc = aliceDb.collection('users').doc('alice');
    
    await testing.assertSucceeds(aliceDoc.set({ username: 'alice' }));
    await testing.assertSucceeds(aliceDoc.get());
  });

  it('should deny user to read/write other user document', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    const bobDoc = aliceDb.collection('users').doc('bob');
    
    await testing.assertFails(bobDoc.set({ username: 'bob' }));
    await testing.assertFails(bobDoc.get());
  });

  it('should deny unauthenticated user to read/write any document', async () => {
    const unauthDb = testEnv.unauthenticatedContext().firestore();
    const aliceDoc = unauthDb.collection('users').doc('alice');
    
    await testing.assertFails(aliceDoc.set({ username: 'alice' }));
    await testing.assertFails(aliceDoc.get());
  });
});
