import {strict as assert} from "assert";
import {getApps, initializeApp} from "firebase-admin/app";
import {FieldPath, getFirestore, Timestamp} from "firebase-admin/firestore";
import {ChatCleanupService} from "../../src/chat/cleanup";
import {OutingDeletionService} from "../../src/outings/outing_deletion";
import {seedEligibleChat} from "./chat_test_utils";

if (!getApps().length) initializeApp({projectId: "chillgo-61439"});
const db = getFirestore();
const emulatorEnabled = !!process.env.FIRESTORE_EMULATOR_HOST;

async function clear(): Promise<void> {
  for (const name of [
    "users", "crews", "crew_memberships", "outings", "outing_participants",
    "chat_messages", "chat_commands", "chat_read_states", "chat_rate_limits", "chat_time_probes",
  ]) {
    const snapshot = await db.collection(name).get();
    const batch = db.batch();
    for (const document of snapshot.docs) batch.delete(document.ref);
    if (!snapshot.empty) await batch.commit();
  }
}

async function createCommand(
  id: string,
  clientMessageId = id,
  requestedByUserId = "user-1",
): Promise<FirebaseFirestore.DocumentReference> {
  const ref = db.collection("chat_commands").doc(id);
  await ref.set({
    type: "send_message",
    outingId: "outing-1",
    crewId: "crew-1",
    requestedByUserId,
    clientMessageId,
    payload: {text: `Message ${clientMessageId}`},
    status: "pending",
    createdAt: Timestamp.now(),
  });
  return ref;
}

async function waitTerminal(ref: FirebaseFirestore.DocumentReference): Promise<FirebaseFirestore.DocumentData> {
  const deadline = Date.now() + 15_000;
  while (Date.now() < deadline) {
    const snapshot = await ref.get();
    if (["succeeded", "failed"].includes(snapshot.data()?.status)) return snapshot.data()!;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`Command ${ref.id} did not become terminal`);
}

async function waitUntil(
  predicate: () => boolean,
  description: string,
): Promise<void> {
  const deadline = Date.now() + 15_000;
  while (Date.now() < deadline) {
    if (predicate()) return;
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
  throw new Error(`Timed out waiting for ${description}`);
}

(emulatorEnabled ? describe : describe.skip)("outing chat integrated emulators", function() {
  this.timeout(60_000);
  beforeEach(clear);

  it("accepts a command, scrubs text, and converges a lost-ack retry", async () => {
    await seedEligibleChat(db);
    const first = await waitTerminal(await createCommand("command-1", "stable-client-message"));
    assert.equal(first.status, "succeeded");
    assert.equal(first.payload, undefined);
    const retry = await waitTerminal(await createCommand("command-2", "stable-client-message"));
    assert.equal(retry.status, "succeeded");
    assert.equal(retry.result.alreadyAccepted, true);
    assert.equal((await db.collection("chat_messages").get()).size, 1);
    const message = (await db.collection("chat_messages").limit(1).get()).docs[0].data();
    assert.equal(message.authorUserId, "user-1");
    assert.equal(message.authorUsername, "user-1");
    assert.equal(message.authorDisplayName, "Chat Tester");
  });

  it("enforces the rolling per-participant limit with a safe retry time", async () => {
    await seedEligibleChat(db);
    for (let index = 0; index < 30; index++) {
      const terminal = await waitTerminal(
        await createCommand(`rate-command-${index}`, `rate-message-${index}`),
      );
      assert.equal(terminal.status, "succeeded");
    }
    const limited = await waitTerminal(
      await createCommand("rate-command-limited", "rate-message-limited"),
    );
    assert.equal(limited.status, "failed");
    assert.equal(limited.errorCode, "rate_limited");
    assert.ok(limited.retryAt instanceof Timestamp);
    assert.equal((await db.collection("chat_messages").get()).size, 30);
  });

  it("revalidates eligibility and terminal lifecycle in trusted processing", async () => {
    await seedEligibleChat(db, {status: "completed"});
    const closed = await waitTerminal(await createCommand("closed"));
    assert.equal(closed.errorCode, "invalid_outing_state");
    await db.collection("outings").doc("outing-1").update({status: "planning"});
    await db.collection("outing_participants").doc("outing-1_user-1").delete();
    const removed = await waitTerminal(await createCommand("removed"));
    assert.equal(removed.errorCode, "permission_denied");
  });

  it("hard-deletes expired records while leaving future messages intact", async () => {
    const now = Timestamp.now();
    await db.collection("chat_messages").doc("expired").set({expiresAt: Timestamp.fromMillis(now.toMillis() - 1)});
    await db.collection("chat_messages").doc("future").set({expiresAt: Timestamp.fromMillis(now.toMillis() + 60_000)});
    await new ChatCleanupService(db).run(now);
    assert.equal((await db.collection("chat_messages").doc("expired").get()).exists, false);
    assert.equal((await db.collection("chat_messages").doc("future").get()).exists, true);
  });

  it("marks deletion, cascades chat data, and rejects recreation", async () => {
    await seedEligibleChat(db);
    await db.collection("chat_messages").doc("owned").set({outingId: "outing-1"});
    await db.collection("chat_read_states").doc("owned").set({outingId: "outing-1"});
    await new OutingDeletionService(db).deleteCreatorOwned("outing-1", "crew-1", "user-1", "delete-command");
    assert.equal((await db.collection("outings").doc("outing-1").get()).exists, false);
    assert.equal((await db.collection("chat_messages").where("outingId", "==", "outing-1").get()).empty, true);
    const result = await waitTerminal(await createCommand("after-delete"));
    assert.equal(result.errorCode, "not_found");
  });

  it("profiles 100 accepted sends and a newest page across 5,000 messages", async function() {
    this.timeout(120_000);
    await seedEligibleChat(db);

    const participantBatch = db.batch();
    for (let index = 0; index < 100; index++) {
      const userId = `perf-user-${index}`;
      participantBatch.set(db.collection("users").doc(userId), {
        username: userId,
        displayName: `Performance Participant ${index}`,
        avatarUrl: null,
        createdAt: Timestamp.now(),
      });
      participantBatch.set(db.collection("crew_memberships").doc(`crew-1_${userId}`), {
        crewId: "crew-1",
        userId,
        role: "member",
        joinedAt: Timestamp.now(),
        username: userId,
        displayName: `Performance Participant ${index}`,
      });
      participantBatch.set(db.collection("outing_participants").doc(`outing-1_${userId}`), {
        outingId: "outing-1",
        crewId: "crew-1",
        userId,
        username: userId,
        displayName: `Performance Participant ${index}`,
        addedByUserId: "user-1",
        addedAt: Timestamp.now(),
        isCreatorParticipant: false,
        attendanceStatus: "accepted",
        respondedAt: Timestamp.now(),
      });
    }
    await participantBatch.commit();

    const observed = new Set<string>();
    let observerReady = false;
    const unsubscribe = db.collection("chat_messages")
      .where("outingId", "==", "outing-1")
      .onSnapshot((snapshot) => {
        for (const change of snapshot.docChanges()) observed.add(change.doc.id);
        observerReady = true;
      });
    await waitUntil(() => observerReady, "the conversation observer");

    const sendLatencies: number[] = [];
    try {
      for (let offset = 0; offset < 100; offset += 5) {
        await Promise.all(Array.from({length: 5}, async (_, batchIndex) => {
          const index = offset + batchIndex;
          const userId = `perf-user-${index}`;
          const clientMessageId = `perf-message-${index}`;
          const expectedMessageId = `outing-1_${clientMessageId}`;
          const startedAt = Date.now();
          const terminal = await waitTerminal(
            await createCommand(`perf-command-${index}`, clientMessageId, userId),
          );
          assert.equal(terminal.status, "succeeded");
          await waitUntil(
            () => observed.has(expectedMessageId),
            `observer delivery of ${expectedMessageId}`,
          );
          sendLatencies.push(Date.now() - startedAt);
        }));
      }
    } finally {
      unsubscribe();
    }
    assert.equal(sendLatencies.length, 100);
    assert.ok(
      sendLatencies.every((latency) => latency < 3_000),
      `Expected every accepted-send observation under 3s; max=${Math.max(...sendLatencies)}ms`,
    );

    const base = Date.now() - 5_000_000;
    for (let offset = 100; offset < 5_000; offset += 400) {
      const batch = db.batch();
      for (let index = offset; index < Math.min(offset + 400, 5_000); index++) {
        const acceptedAt = Timestamp.fromMillis(base + index);
        batch.set(db.collection("chat_messages").doc(`history-${index}`), {
          outingId: "outing-1",
          crewId: "crew-1",
          clientMessageId: `history-${index}`,
          authorUserId: "user-1",
          authorUsername: "user-1",
          authorDisplayName: "Chat Tester",
          authorAvatarUrl: null,
          text: `History ${index}`,
          acceptedAt,
          expiresAt: Timestamp.fromMillis(acceptedAt.toMillis() + 24 * 60 * 60 * 1000),
        });
      }
      await batch.commit();
    }

    const newestStartedAt = Date.now();
    const newest = await db.collection("chat_messages")
      .where("outingId", "==", "outing-1")
      .orderBy("acceptedAt", "desc")
      .orderBy(FieldPath.documentId(), "desc")
      .limit(50)
      .get();
    const newestLatency = Date.now() - newestStartedAt;
    assert.equal(newest.size, 50);
    assert.ok(newestLatency < 3_000, `Expected newest page under 3s; got ${newestLatency}ms`);
    console.info(JSON.stringify({
      event: "chat_performance_profile",
      participants: 100,
      messages: 5_000,
      acceptedSendMaxMs: Math.max(...sendLatencies),
      acceptedSendP95Ms: sendLatencies.sort((a, b) => a - b)[94],
      newestPageMs: newestLatency,
    }));
  });
});
