import {strict as assert} from "assert";
import {getApps, initializeApp} from "firebase-admin/app";
import {
  PRESENCE_COLLECTIONS,
  PRIVACY_TRANSITION_BATCH_SIZE,
  PrivacyTransitionCoordinator,
  validTerminalChange,
} from "../../src/live_meetup/privacy_transition_coordinator";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {LiveMeetupTransactions} from "../../src/live_meetup/live_meetup_transactions";
import {SetStatusCommand} from "../../src/live_meetup/command_schema";
import {EndOutingTransition} from "../../src/live_meetup/transition_schema";

if (!getApps().length) initializeApp({projectId: "chillgo-61439"});

describe("privacy transition coordinator invariants", () => {
  it("covers every protected presence collection in bounded batches", () => {
    assert.deepEqual(PRESENCE_COLLECTIONS, [
      "live_meetup_statuses",
      "live_meetup_shares",
      "live_locations",
    ]);
    assert.ok(PRIVACY_TRANSITION_BATCH_SIZE > 0);
    assert.ok(PRIVACY_TRANSITION_BATCH_SIZE < 500);
  });

  it("allows only explicit lifecycle terminal edges", () => {
    assert.equal(validTerminalChange("meeting", "completed"), true);
    assert.equal(validTerminalChange("draft", "cancelled"), true);
    assert.equal(validTerminalChange("planning", "cancelled"), true);
    assert.equal(validTerminalChange("confirmed", "cancelled"), true);
    assert.equal(validTerminalChange("completed", "archived"), true);
    assert.equal(validTerminalChange("confirmed", "completed"), false);
    assert.equal(validTerminalChange("meeting", "archived"), false);
    assert.equal(validTerminalChange("completed", "meeting"), false);
  });
});

const describeEmulator = process.env.FIRESTORE_EMULATOR_HOST ? describe : describe.skip;

describeEmulator("privacy transition coordinator emulator ordering", function() {
  this.timeout(60000);
  const db = getFirestore();

  it("denies access, cursors bounded deletion, verifies empty, then finalizes", async () => {
    const timestamp = Timestamp.now();
    await Promise.all([
      db.collection("crews").doc("crew-order").set({ownerId: "alice"}),
      db.collection("crew_memberships").doc("crew-order_alice").set({
        crewId: "crew-order", userId: "alice", role: "owner",
      }),
      db.collection("outings").doc("outing-order").set({
        crewId: "crew-order", createdByUserId: "alice", status: "meeting",
      }),
      db.collection("outing_participants").doc("outing-order_alice").set({
        outingId: "outing-order", crewId: "crew-order", userId: "alice",
        attendanceStatus: "accepted", isCreatorParticipant: true,
      }),
    ]);
    const writer = db.bulkWriter();
    for (let index = 0; index < PRIVACY_TRANSITION_BATCH_SIZE + 1; index++) {
      writer.set(db.collection("live_meetup_statuses").doc(`order-${index}`), {
        outingId: "outing-order", crewId: "crew-order", userId: `user-${index}`,
      });
    }
    await writer.close();
    const transition: EndOutingTransition = {
      type: "end_outing",
      outingId: "outing-order",
      crewId: "crew-order",
      targetOutingStatus: "completed",
      requestedByUserId: "alice",
      status: "pending",
      createdAt: timestamp,
      purgeAt: Timestamp.fromMillis(timestamp.toMillis() + 3600000),
    };
    const transitionRef = db.collection("live_meetup_transitions").doc("order");
    await transitionRef.set(transition);
    const observedPhases = new Set<string>();
    let observedCursor = false;
    const unsubscribeProgress = transitionRef.onSnapshot((snapshot) => {
      const state = snapshot.data();
      if (typeof state?.phase === "string") observedPhases.add(state.phase);
      if (typeof state?.cursor === "string") observedCursor = true;
    });
    let resolvePending!: () => void;
    const pendingObserved = new Promise<void>((resolve) => {
      resolvePending = resolve;
    });
    const unsubscribeOuting = db.collection("outings").doc("outing-order")
      .onSnapshot((snapshot) => {
        if (snapshot.data()?.liveMeetupCleanupPending === true) resolvePending();
      });

    const coordinator = new PrivacyTransitionCoordinator(db);
    const running = coordinator.run(transitionRef.id, transition);
    await pendingObserved;
    const commandAt = Timestamp.now();
    const racedCommand: SetStatusCommand = {
      type: "set_status",
      outingId: "outing-order",
      crewId: "crew-order",
      requestedByUserId: "alice",
      payload: {value: "arrived"},
      status: "pending",
      createdAt: commandAt,
      purgeAt: Timestamp.fromMillis(commandAt.toMillis() + 3600000),
    };
    await db.collection("live_meetup_commands").doc("raced").set(racedCommand);
    await assert.rejects(
      new LiveMeetupTransactions(db).process("raced", "event-raced", racedCommand),
    );
    await running;
    await coordinator.run(transitionRef.id, transition);
    unsubscribeProgress();
    unsubscribeOuting();

    assert.equal(
      (await db.collection("live_meetup_statuses")
        .where("outingId", "==", "outing-order").get()).size,
      0,
    );
    assert.equal(
      (await db.collection("outings").doc("outing-order").get()).data()?.status,
      "completed",
    );
    assert.equal(observedCursor, true);
    for (const phase of [
      "authorize", "deny_access", "delete_presence", "verify_empty", "finalize",
    ]) assert.equal(observedPhases.has(phase), true);
    assert.equal(
      (await db.collection("live_meetup_statuses").doc("outing-order_alice").get())
        .exists,
      false,
    );
  });
});
