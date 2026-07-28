import {strict as assert} from "assert";
import {initializeApp, getApps} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  LiveMeetupCommand,
  LiveMeetupCommandType,
} from "../../src/live_meetup/command_schema";
import {LiveMeetupTransactions} from "../../src/live_meetup/live_meetup_transactions";

if (!getApps().length) initializeApp({projectId: "chillgo-61439"});
const db = getFirestore();
const describeEmulator = process.env.FIRESTORE_EMULATOR_HOST ? describe : describe.skip;
const attendeeCount = 100;

describeEmulator("live meetup performance profile", function() {
  this.timeout(10 * 60 * 1000);

  it("profiles SC-002, SC-008, and 100 accepted-stop observer trials", async () => {
    await clearProfileCollections();
    await seedAttendees();
    const transactions = new LiveMeetupTransactions(db);
    const statusLatencies = await runInBatches(
      attendeeCount,
      10,
      async (index) => {
        const userId = attendeeId(index);
        const commandId = `status-${index}`;
        const observed = observeDocument(
          db.collection("live_meetup_statuses").doc(`outing-profile_${userId}`),
          (snapshot) => snapshot.data()?.acceptedCommandId === commandId,
        );
        const started = Date.now();
        await submit(transactions, commandId, userId, "set_status", {
          value: index % 3 === 0 ? "getting_ready" :
            index % 3 === 1 ? "on_my_way" : "arrived",
        });
        await observed;
        return Date.now() - started;
      },
    );

    await runInBatches(attendeeCount, 10, async (index) => {
      const userId = attendeeId(index);
      await submit(transactions, `start-${index}`, userId, "start_sharing", {
        sessionId: `session-${index}`,
        sessionToken: `token-${index}`,
        deviceSessionId: `device-${index}`,
        transferExisting: false,
      });
      return 0;
    });
    const locationLatencies = await runInBatches(
      attendeeCount,
      10,
      async (index) => {
        const userId = attendeeId(index);
        const commandId = `location-${index}`;
        const observed = observeDocument(
          db.collection("live_locations").doc(`outing-profile_${userId}`),
          (snapshot) => snapshot.data()?.acceptedCommandId === commandId,
        );
        const started = Date.now();
        await submit(transactions, commandId, userId, "publish_location", {
          sessionId: `session-${index}`,
          sessionToken: `token-${index}`,
          latitude: 30 + index / 10000,
          longitude: 31 + index / 10000,
          accuracyMeters: 10,
          sampleAgeMillis: 0,
        });
        await observed;
        return Date.now() - started;
      },
    );

    const openingLatencies: number[] = [];
    for (let trial = 0; trial < 100; trial++) {
      const started = Date.now();
      const [participants, statuses, locations] = await Promise.all([
        db.collection("outing_participants")
          .where("outingId", "==", "outing-profile").limit(100).get(),
        db.collection("live_meetup_statuses")
          .where("outingId", "==", "outing-profile").limit(100).get(),
        db.collection("live_locations")
          .where("outingId", "==", "outing-profile").limit(100).get(),
        db.collection("meetup_points").doc("outing-profile").get(),
      ]);
      assert.equal(participants.size, attendeeCount);
      assert.equal(statuses.size, attendeeCount);
      assert.equal(locations.size, attendeeCount);
      openingLatencies.push(Date.now() - started);
    }

    const stopLatencies: number[] = [];
    for (let trial = 0; trial < 100; trial++) {
      const sessionId = `stop-session-${trial}`;
      const sessionToken = `stop-token-${trial}`;
      await submit(transactions, `stop-start-${trial}`, attendeeId(0), "start_sharing", {
        sessionId,
        sessionToken,
        deviceSessionId: `stop-device-${trial}`,
        transferExisting: true,
      });
      await submit(transactions, `stop-location-${trial}`, attendeeId(0), "publish_location", {
        sessionId,
        sessionToken,
        latitude: 30,
        longitude: 31,
        accuracyMeters: 10,
        sampleAgeMillis: 0,
      });
      const removed = observeDocument(
        db.collection("live_locations").doc(`outing-profile_${attendeeId(0)}`),
        (snapshot) => !snapshot.exists,
      );
      const started = Date.now();
      await submit(transactions, `stop-${trial}`, attendeeId(0), "stop_sharing", {
        sessionId,
        sessionToken,
      });
      await removed;
      stopLatencies.push(Date.now() - started);
    }

    const profile = {
      status: summarize(statusLatencies),
      location: summarize(locationLatencies),
      opening: summarize(openingLatencies),
      stopToRemoval: summarize(stopLatencies),
    };
    console.log("LIVE_MEETUP_PERFORMANCE", JSON.stringify(profile));
    assert.ok(profile.status.p95 < 5000);
    assert.ok(profile.location.p95 < 5000);
    assert.ok(profile.opening.p95 < 3000);
    assert.ok(profile.stopToRemoval.max < 5000);
  });
});

async function submit(
  transactions: LiveMeetupTransactions,
  commandId: string,
  userId: string,
  type: LiveMeetupCommandType,
  payload: Record<string, unknown>,
): Promise<void> {
  const createdAt = Timestamp.now();
  const command = {
    type,
    outingId: "outing-profile",
    crewId: "crew-profile",
    requestedByUserId: userId,
    payload,
    status: "pending",
    createdAt,
    purgeAt: Timestamp.fromMillis(createdAt.toMillis() + 60 * 60 * 1000),
  } as LiveMeetupCommand;
  await db.collection("live_meetup_commands").doc(commandId).set(command);
  await transactions.process(commandId, `event-${commandId}`, command);
}

function observeDocument(
  ref: FirebaseFirestore.DocumentReference,
  accepted: (snapshot: FirebaseFirestore.DocumentSnapshot) => boolean,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      unsubscribe();
      reject(new Error("Observer latency exceeded five seconds."));
    }, 5000);
    const unsubscribe = ref.onSnapshot((snapshot) => {
      if (!accepted(snapshot)) return;
      clearTimeout(timeout);
      unsubscribe();
      resolve();
    }, reject);
  });
}

async function runInBatches(
  count: number,
  batchSize: number,
  operation: (index: number) => Promise<number>,
): Promise<number[]> {
  const latencies: number[] = [];
  for (let start = 0; start < count; start += batchSize) {
    latencies.push(...await Promise.all(
      Array.from(
        {length: Math.min(batchSize, count - start)},
        (_, offset) => operation(start + offset),
      ),
    ));
  }
  return latencies;
}

function summarize(latencies: number[]): {p95: number; max: number; median: number} {
  const sorted = [...latencies].sort((left, right) => left - right);
  return {
    median: sorted[Math.floor(sorted.length * 0.5)],
    p95: sorted[Math.ceil(sorted.length * 0.95) - 1],
    max: sorted.at(-1)!,
  };
}

function attendeeId(index: number): string {
  return `user-${index.toString().padStart(3, "0")}`;
}

async function seedAttendees(): Promise<void> {
  const timestamp = Timestamp.now();
  await Promise.all([
    db.collection("crews").doc("crew-profile").set({
      ownerId: attendeeId(0), name: "Profile Crew", createdAt: timestamp,
    }),
    db.collection("outings").doc("outing-profile").set({
      crewId: "crew-profile",
      createdByUserId: attendeeId(0),
      status: "meeting",
      locationText: "Profile point",
      updatedAt: timestamp,
    }),
  ]);
  const writer = db.bulkWriter();
  for (let index = 0; index < attendeeCount; index++) {
    const userId = attendeeId(index);
    writer.set(db.collection("crew_memberships").doc(`crew-profile_${userId}`), {
      crewId: "crew-profile", userId,
      role: index === 0 ? "owner" : "member",
      joinedAt: timestamp,
    });
    writer.set(
      db.collection("outing_participants").doc(`outing-profile_${userId}`),
      {
        outingId: "outing-profile", crewId: "crew-profile", userId,
        attendanceStatus: "accepted", displayName: `Attendee ${index}`,
      },
    );
  }
  await writer.close();
}

async function clearProfileCollections(): Promise<void> {
  for (const collection of [
    "live_meetup_commands", "live_meetup_statuses", "live_meetup_shares",
    "live_locations", "meetup_points", "outing_participants",
    "crew_memberships", "outings", "crews",
  ]) {
    const snapshot = await db.collection(collection).get();
    const writer = db.bulkWriter();
    for (const doc of snapshot.docs) writer.delete(doc.ref);
    await writer.close();
  }
}
