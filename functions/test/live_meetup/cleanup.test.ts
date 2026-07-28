import {strict as assert} from "assert";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  deletePresenceForOuting,
  recoverTransition,
  runLiveMeetupRepair,
} from "../../src/live_meetup/cleanup";

describe("live meetup cleanup recovery", () => {
  it("recovers abandoned progress without trusting progress fields", () => {
    const createdAt = Timestamp.fromMillis(1000);
    const recovered = recoverTransition({
      type: "change_attendance",
      outingId: "outing",
      crewId: "crew",
      targetUserId: "user",
      targetAttendanceStatus: "declined",
      requestedByUserId: "user",
      status: "processing",
      phase: "delete_presence",
      cursor: "sensitive-progress",
      processingEventId: "old-event",
      createdAt,
      purgeAt: Timestamp.fromMillis(3601000),
    });
    assert.deepEqual(recovered, {
      type: "change_attendance",
      outingId: "outing",
      crewId: "crew",
      targetUserId: "user",
      targetAttendanceStatus: "declined",
      requestedByUserId: "user",
      status: "pending",
      createdAt,
      purgeAt: Timestamp.fromMillis(3601000),
    });
  });
});

const describeEmulator = process.env.FIRESTORE_EMULATOR_HOST ? describe : describe.skip;

describeEmulator("live meetup cleanup emulator recovery", function() {
  this.timeout(30000);
  const db = getFirestore();

  beforeEach(async () => {
    for (const collection of [
      "live_meetup_transitions", "live_meetup_commands",
      "live_meetup_time_probes", "live_meetup_statuses",
      "live_meetup_shares", "live_locations", "outing_participants",
      "crew_memberships", "outings", "crews",
    ]) {
      const snapshot = await db.collection(collection).get();
      const writer = db.bulkWriter();
      for (const doc of snapshot.docs) writer.delete(doc.ref);
      await writer.close();
    }
  });

  it("deletes expired records and resumes an abandoned transition once", async () => {
    const current = Timestamp.now();
    const createdAt = Timestamp.fromMillis(current.toMillis() - 5 * 60 * 1000);
    await Promise.all([
      db.collection("crews").doc("crew").set({ownerId: "alice"}),
      db.collection("crew_memberships").doc("crew_bob").set({
        crewId: "crew", userId: "bob", role: "member",
      }),
      db.collection("outings").doc("outing").set({
        crewId: "crew", createdByUserId: "alice", status: "confirmed",
      }),
      db.collection("outing_participants").doc("outing_bob").set({
        outingId: "outing", crewId: "crew", userId: "bob",
        attendanceStatus: "accepted", isCreatorParticipant: false,
      }),
      db.collection("live_meetup_statuses").doc("outing_bob").set({
        outingId: "outing", crewId: "crew", userId: "bob",
      }),
      db.collection("live_locations").doc("expired").set({
        outingId: "other", userId: "other",
        expiresAt: Timestamp.fromMillis(current.toMillis() - 1),
      }),
      db.collection("live_meetup_commands").doc("expired").set({
        purgeAt: Timestamp.fromMillis(current.toMillis() - 1),
      }),
      db.collection("live_meetup_time_probes").doc("expired").set({
        requestedAt: Timestamp.fromMillis(current.toMillis() - 11 * 60 * 1000),
      }),
      db.collection("live_meetup_transitions").doc("abandoned").set({
        type: "change_attendance",
        outingId: "outing",
        crewId: "crew",
        targetUserId: "bob",
        targetAttendanceStatus: "declined",
        requestedByUserId: "bob",
        status: "processing",
        phase: "delete_presence",
        cursor: "live_meetup_statuses:outing:outing_bob",
        processingEventId: "lost-worker",
        leaseExpiresAt: Timestamp.fromMillis(current.toMillis() - 1),
        createdAt,
        purgeAt: Timestamp.fromMillis(createdAt.toMillis() + 60 * 60 * 1000),
      }),
    ]);

    const first = await runLiveMeetupRepair(db, current);
    const second = await runLiveMeetupRepair(db, current);

    assert.deepEqual(first, {deleted: 3, resumed: 1});
    assert.deepEqual(second, {deleted: 0, resumed: 0});
    assert.equal(
      (await db.collection("outing_participants").doc("outing_bob").get())
        .data()?.attendanceStatus,
      "declined",
    );
    assert.equal(
      (await db.collection("live_meetup_statuses").doc("outing_bob").get()).exists,
      false,
    );
    assert.equal(
      (await db.collection("live_meetup_transitions").doc("abandoned").get())
        .data()?.status,
      "succeeded",
    );
  });

  it("makes overlapping unexpected-change cleanup idempotent", async () => {
    for (const collection of [
      "live_meetup_statuses", "live_meetup_shares", "live_locations",
    ]) {
      await db.collection(collection).doc("outing_bob").set({
        outingId: "outing", crewId: "crew", userId: "bob",
      });
    }

    await Promise.all([
      deletePresenceForOuting("outing", "bob"),
      deletePresenceForOuting("outing", "bob"),
    ]);

    for (const collection of [
      "live_meetup_statuses", "live_meetup_shares", "live_locations",
    ]) {
      assert.equal(
        (await db.collection(collection).doc("outing_bob").get()).exists,
        false,
      );
    }
  });
});
