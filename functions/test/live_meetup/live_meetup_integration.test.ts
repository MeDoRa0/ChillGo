import {strict as assert} from "assert";
import {initializeApp, getApps} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {EndOutingTransition, ChangeAttendanceTransition} from "../../src/live_meetup/transition_schema";

if (!getApps().length) initializeApp({projectId: "chillgo-61439"});
const db = getFirestore();
const now = () => Timestamp.now();

const describeEmulator = process.env.FIRESTORE_EMULATOR_HOST ? describe : describe.skip;

describeEmulator("live meetup privacy transition integration", function() {
  this.timeout(30000);

  beforeEach(async () => {
    for (const collection of [
      "live_meetup_transitions", "live_meetup_statuses",
      "live_meetup_shares", "live_locations", "outing_participants",
      "crew_memberships", "outings", "crews",
    ]) {
      const snapshot = await db.collection(collection).get();
      const writer = db.bulkWriter();
      for (const doc of snapshot.docs) writer.delete(doc.ref);
      await writer.close();
    }
  });

  it("deletes presence before acknowledging accepted-to-declined", async () => {
    await seedBase("confirmed");
    await seedPresence("bob");
    const createdAt = now();
    const transition: ChangeAttendanceTransition = {
      type: "change_attendance",
      outingId: "outing",
      crewId: "crew",
      targetUserId: "bob",
      targetAttendanceStatus: "declined",
      requestedByUserId: "bob",
      status: "pending",
      createdAt,
      purgeAt: Timestamp.fromMillis(createdAt.toMillis() + 3600000),
    };
    const ref = db.collection("live_meetup_transitions").doc("decline");
    await ref.set(transition);

    const terminal = await waitForTerminal(ref);

    await assertPresenceAbsent("bob");
    assert.equal(terminal.status, "succeeded");
    assert.equal(
      (await db.collection("outing_participants").doc("outing_bob").get())
        .data()?.attendanceStatus,
      "declined",
    );
    const retryRef = db.collection("live_meetup_transitions").doc("decline-retry");
    await retryRef.set({...transition, createdAt: now(),
      purgeAt: Timestamp.fromMillis(Date.now() + 3600000)});
    assert.equal((await waitForTerminal(retryRef)).status, "succeeded");
  });

  it("cleans 100 attendees in bounded batches before completing an outing", async () => {
    await seedBase("meeting");
    const writer = db.bulkWriter();
    for (let index = 0; index < 100; index++) {
      const userId = `user-${index}`;
      for (const collection of [
        "live_meetup_statuses", "live_meetup_shares", "live_locations",
      ]) {
        writer.set(db.collection(collection).doc(`outing_${userId}`), {
          outingId: "outing",
          crewId: "crew",
          userId,
          expiresAt: Timestamp.fromMillis(Date.now() + 120000),
        });
      }
    }
    await writer.close();
    const createdAt = now();
    const transition: EndOutingTransition = {
      type: "end_outing",
      outingId: "outing",
      crewId: "crew",
      targetOutingStatus: "completed",
      requestedByUserId: "alice",
      status: "pending",
      createdAt,
      purgeAt: Timestamp.fromMillis(createdAt.toMillis() + 3600000),
    };
    const ref = db.collection("live_meetup_transitions").doc("complete");
    await ref.set(transition);
    const started = Date.now();

    const terminal = await waitForTerminal(ref);

    for (const collection of [
      "live_meetup_statuses", "live_meetup_shares", "live_locations",
    ]) {
      assert.equal(
        (await db.collection(collection).where("outingId", "==", "outing").get()).size,
        0,
      );
    }
    assert.equal((await db.collection("outings").doc("outing").get()).data()?.status,
      "completed");
    assert.equal(terminal.status, "succeeded");
    assert.ok(Date.now() - started < 30000);
  });

  it("finalizes Cancelled and Archived only after anomalous presence is absent", async () => {
    for (const scenario of [
      {current: "confirmed", target: "cancelled" as const},
      {current: "completed", target: "archived" as const},
    ]) {
      await seedBase(scenario.current);
      await seedPresence("bob");
      const createdAt = now();
      const transition: EndOutingTransition = {
        type: "end_outing",
        outingId: "outing",
        crewId: "crew",
        targetOutingStatus: scenario.target,
        requestedByUserId: "alice",
        status: "pending",
        createdAt,
        purgeAt: Timestamp.fromMillis(createdAt.toMillis() + 3600000),
      };
      const ref = db.collection("live_meetup_transitions").doc(`end-${scenario.target}`);
      await ref.set(transition);
      assert.equal((await waitForTerminal(ref)).status, "succeeded");
      await assertPresenceAbsent("bob");
      assert.equal(
        (await db.collection("outings").doc("outing").get()).data()?.status,
        scenario.target,
      );
      await clearPresenceAndOuting();
    }
  });
});

async function seedBase(status: string): Promise<void> {
  const timestamp = now();
  await Promise.all([
    db.collection("crews").doc("crew").set({
      ownerId: "alice", name: "Crew", createdAt: timestamp,
    }),
    db.collection("crew_memberships").doc("crew_alice").set({
      crewId: "crew", userId: "alice", role: "owner", joinedAt: timestamp,
    }),
    db.collection("crew_memberships").doc("crew_bob").set({
      crewId: "crew", userId: "bob", role: "member", joinedAt: timestamp,
    }),
    db.collection("outings").doc("outing").set({
      crewId: "crew", createdByUserId: "alice", status,
      locationText: "Cafe", updatedAt: timestamp,
    }),
    db.collection("outing_participants").doc("outing_bob").set({
      outingId: "outing", crewId: "crew", userId: "bob",
      attendanceStatus: "accepted", isCreatorParticipant: false,
    }),
  ]);
}

async function seedPresence(userId: string): Promise<void> {
  await Promise.all([
    db.collection("live_meetup_statuses").doc(`outing_${userId}`).set({
      outingId: "outing", crewId: "crew", userId,
    }),
    db.collection("live_meetup_shares").doc(`outing_${userId}`).set({
      outingId: "outing", crewId: "crew", userId,
    }),
    db.collection("live_locations").doc(`outing_${userId}`).set({
      outingId: "outing", crewId: "crew", userId,
      expiresAt: Timestamp.fromMillis(Date.now() + 120000),
    }),
  ]);
}

async function assertPresenceAbsent(userId: string): Promise<void> {
  for (const collection of [
    "live_meetup_statuses", "live_meetup_shares", "live_locations",
  ]) {
    assert.equal(
      (await db.collection(collection).doc(`outing_${userId}`).get()).exists,
      false,
    );
  }
}

async function waitForTerminal(
  ref: FirebaseFirestore.DocumentReference,
): Promise<FirebaseFirestore.DocumentData> {
  const deadline = Date.now() + 30000;
  while (Date.now() < deadline) {
    const snapshot = await ref.get();
    if (["succeeded", "failed"].includes(snapshot.data()?.status)) {
      return snapshot.data()!;
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error("Transition did not reach a terminal state.");
}

async function clearPresenceAndOuting(): Promise<void> {
  for (const collection of [
    "live_meetup_transitions", "live_meetup_statuses",
    "live_meetup_shares", "live_locations", "outing_participants",
    "crew_memberships", "outings", "crews",
  ]) {
    const snapshot = await db.collection(collection).get();
    const writer = db.bulkWriter();
    for (const doc of snapshot.docs) writer.delete(doc.ref);
    await writer.close();
  }
}
