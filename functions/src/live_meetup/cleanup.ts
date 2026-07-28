import {initializeApp, getApps} from "firebase-admin/app";
import {
  DocumentData,
  Firestore,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {
  onDocumentDeleted,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {PrivacyTransitionCoordinator} from "./privacy_transition_coordinator";
import {
  LiveMeetupTransition,
  terminalTransitionFields,
} from "./transition_schema";

if (!getApps().length) initializeApp();
const PRESENCE = ["live_meetup_statuses", "live_meetup_shares", "live_locations"];
const REPAIR_LIMIT = 100;

export async function deletePresenceForOuting(
  outingId: string,
  userId?: string,
): Promise<number> {
  const db = getFirestore();
  let deleted = 0;
  for (const collection of PRESENCE) {
    let query = db.collection(collection).where("outingId", "==", outingId);
    if (userId) query = query.where("userId", "==", userId);
    const snapshot = await query.limit(REPAIR_LIMIT).get();
    if (snapshot.empty) continue;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
    await batch.commit();
    deleted += snapshot.size;
  }
  return deleted;
}

export const liveMeetupOutingLifecycleRepair = onDocumentUpdated(
  "outings/{outingId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return;
    if (after.status !== "meeting" ||
        after.liveMeetupCleanupPending === true ||
        after.deletionPending === true) {
      await deletePresenceForOuting(event.params.outingId);
    }
  },
);

export const liveMeetupParticipantEligibilityRepair = onDocumentUpdated(
  "outing_participants/{participantId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return;
    if (after.attendanceStatus !== "accepted" ||
        after.liveMeetupCleanupPending === true) {
      await deletePresenceForOuting(after.outingId, after.userId);
    }
  },
);

export const liveMeetupParticipantRemovalRepair = onDocumentDeleted(
  "outing_participants/{participantId}",
  async (event) => {
    const before = event.data?.data();
    if (before) await deletePresenceForOuting(before.outingId, before.userId);
  },
);

export const liveMeetupMembershipRemovalRepair = onDocumentDeleted(
  "crew_memberships/{membershipId}",
  async (event) => {
    const before = event.data?.data();
    if (!before) return;
    const outings = await getFirestore().collection("outings")
      .where("crewId", "==", before.crewId).get();
    for (const outing of outings.docs) {
      await deletePresenceForOuting(outing.id, before.userId);
    }
  },
);

export const liveMeetupCleanupScheduled = onSchedule(
  "every 1 minutes",
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const {deleted, resumed} = await runLiveMeetupRepair(db, now);
    logger.info("live_meetup_cleanup", {deleted, resumed});
  },
);

export async function runLiveMeetupRepair(
  db: Firestore,
  now: Timestamp,
): Promise<{deleted: number; resumed: number}> {
  let deleted = 0;
  for (const [collection, field] of [
    ["live_locations", "expiresAt"],
    ["live_meetup_commands", "purgeAt"],
    ["live_meetup_time_probes", "requestedAt"],
  ] as const) {
    const cutoff = collection === "live_meetup_time_probes" ?
      Timestamp.fromMillis(now.toMillis() - 10 * 60 * 1000) : now;
    const snapshot = await db.collection(collection)
      .where(field, "<=", cutoff).limit(REPAIR_LIMIT).get();
    if (snapshot.empty) continue;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
    await batch.commit();
    deleted += snapshot.size;
  }
  return {
    deleted,
    resumed: await resumeAbandonedTransitions(db, now),
  };
}

async function resumeAbandonedTransitions(
  db: Firestore,
  now: Timestamp,
): Promise<number> {
  const abandoned = await db.collection("live_meetup_transitions")
    .where("status", "in", ["pending", "processing"])
    .limit(20).get();
  let resumed = 0;
  for (const doc of abandoned.docs) {
    const transitionState = doc.data();
    const lease = transitionState.leaseExpiresAt;
    if (transitionState.status === "processing" &&
        lease instanceof Timestamp &&
        lease.toMillis() > now.toMillis()) continue;
    try {
      const transition = recoverTransition(transitionState);
      const result = await new PrivacyTransitionCoordinator(db)
        .run(doc.id, transition);
      await doc.ref.update(
        terminalTransitionFields(transition.createdAt, "succeeded", result),
      );
      resumed++;
    } catch (_) {
      logger.warn("live_meetup_transition_repair_deferred", {
        transitionId: doc.id,
      });
    }
  }
  return resumed;
}

export function recoverTransition(data: DocumentData): LiveMeetupTransition {
  const common = {
    type: data.type,
    crewId: data.crewId,
    requestedByUserId: data.requestedByUserId,
    status: "pending" as const,
    createdAt: data.createdAt,
    purgeAt: data.purgeAt,
  };
  switch (data.type) {
  case "end_outing":
    return {...common, type: data.type, outingId: data.outingId,
      targetOutingStatus: data.targetOutingStatus};
  case "change_attendance":
    return {...common, type: data.type, outingId: data.outingId,
      targetUserId: data.targetUserId,
      targetAttendanceStatus: data.targetAttendanceStatus};
  case "remove_participant":
    return {...common, type: data.type, outingId: data.outingId,
      targetUserId: data.targetUserId};
  case "remove_membership":
    return {...common, type: data.type, targetUserId: data.targetUserId};
  case "delete_crew":
    return {...common, type: data.type};
  default:
    throw new Error("Unknown transition.");
  }
}
