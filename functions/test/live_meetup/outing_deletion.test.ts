import {strict as assert} from "assert";
import {getApps, initializeApp} from "firebase-admin/app";
import {
  OutingDeletionService,
  OUTING_DELETION_SWEEP_PASSES,
  OUTING_OWNED_COLLECTIONS,
} from "../../src/outings/outing_deletion";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {LiveMeetupTransactions} from "../../src/live_meetup/live_meetup_transactions";
import {SetStatusCommand} from "../../src/live_meetup/command_schema";

if (!getApps().length) initializeApp({projectId: "chillgo-61439"});

describe("outing deletion Phase 6 coverage", () => {
  it("sweeps protected collections and meetup point twice", () => {
    for (const collection of [
      "live_meetup_statuses",
      "live_meetup_shares",
      "live_locations",
      "meetup_points",
    ]) assert.ok(OUTING_OWNED_COLLECTIONS.includes(collection));
    assert.equal(OUTING_DELETION_SWEEP_PASSES, 2);
  });
});

const describeEmulator = process.env.FIRESTORE_EMULATOR_HOST ? describe : describe.skip;

describeEmulator("outing deletion Phase 6 emulator sweep", function() {
  this.timeout(30000);
  const db = getFirestore();

  it("terminates work, scrubs commands, resweeps, and rejects delayed recreation", async () => {
    const timestamp = Timestamp.now();
    await Promise.all([
      db.collection("outings").doc("outing-delete").set({
        crewId: "crew", createdByUserId: "alice", status: "meeting",
      }),
      ...["live_meetup_statuses", "live_meetup_shares", "live_locations"]
        .map((collection) => db.collection(collection).doc(`${collection}-record`).set({
          outingId: "outing-delete", crewId: "crew", userId: "alice",
        })),
      db.collection("meetup_points").doc("outing-delete").set({
        outingId: "outing-delete", crewId: "crew",
      }),
      db.collection("live_meetup_commands").doc("pending-command").set({
        type: "set_status", outingId: "outing-delete", crewId: "crew",
        requestedByUserId: "alice", payload: {value: "arrived"},
        status: "pending", createdAt: timestamp,
        purgeAt: Timestamp.fromMillis(timestamp.toMillis() + 3600000),
      }),
      db.collection("live_meetup_transitions").doc("pending-transition").set({
        type: "end_outing", outingId: "outing-delete", crewId: "crew",
        targetOutingStatus: "completed", requestedByUserId: "alice",
        status: "pending", createdAt: timestamp,
        purgeAt: Timestamp.fromMillis(timestamp.toMillis() + 3600000),
      }),
    ]);

    const deletion = new OutingDeletionService(db);
    await deletion.deleteAlreadyPending("outing-delete");
    await deletion.deleteAlreadyPending("outing-delete");

    assert.equal((await db.collection("outings").doc("outing-delete").get()).exists,
      false);
    for (const collection of OUTING_OWNED_COLLECTIONS) {
      assert.equal(
        (await db.collection(collection)
          .where("outingId", "==", "outing-delete").get()).size,
        0,
      );
    }
    const command = (await db.collection("live_meetup_commands")
      .doc("pending-command").get()).data();
    if (command) {
      assert.equal(command.status, "failed");
      assert.equal("payload" in command, false);
    }
    const transition = (await db.collection("live_meetup_transitions")
      .doc("pending-transition").get()).data();
    if (transition) {
      assert.equal(transition.status, "failed");
      assert.equal("targetOutingStatus" in transition, false);
    }

    const delayedAt = Timestamp.now();
    const delayed: SetStatusCommand = {
      type: "set_status",
      outingId: "outing-delete",
      crewId: "crew",
      requestedByUserId: "alice",
      payload: {value: "arrived"},
      status: "pending",
      createdAt: delayedAt,
      purgeAt: Timestamp.fromMillis(delayedAt.toMillis() + 3600000),
    };
    await db.collection("live_meetup_commands").doc("delayed").set(delayed);
    await assert.rejects(
      new LiveMeetupTransactions(db).process("delayed", "event-delayed", delayed),
    );
    assert.equal(
      (await db.collection("live_meetup_statuses")
        .where("outingId", "==", "outing-delete").get()).size,
      0,
    );
  });
});
