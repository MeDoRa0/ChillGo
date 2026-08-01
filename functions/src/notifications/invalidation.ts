import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {
  onDocumentDeleted,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {NotificationTransactions} from "./notification_transactions";

if (!getApps().length) initializeApp();

export const crewInvitationNotificationInvalidated = onDocumentDeleted(
  "crew_invitations/{invitationId}",
  async (event) => {
    await removeWhere("sourceId", event.params.invitationId);
  },
);

export const outingParticipantNotificationInvalidated = onDocumentUpdated(
  "outing_participants/{participantId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || typeof after.userId !== "string" ||
        typeof after.outingId !== "string") return;
    if (before.attendanceStatus === "invited" &&
        after.attendanceStatus !== "invited") {
      await removeWhere("sourceId", event.params.participantId);
    }
    if (after.notificationCleanupPending === true ||
        after.liveMeetupCleanupPending === true) {
      await removeForRecipient("outingId", after.outingId, after.userId);
    }
  },
);

export const outingParticipantNotificationDeleted = onDocumentDeleted(
  "outing_participants/{participantId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || typeof data.userId !== "string" ||
        typeof data.outingId !== "string") return;
    await removeForRecipient("outingId", data.outingId, data.userId);
  },
);

export const crewMembershipNotificationDeleted = onDocumentDeleted(
  "crew_memberships/{membershipId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || typeof data.userId !== "string" ||
        typeof data.crewId !== "string") return;
    await removeForRecipient("crewId", data.crewId, data.userId);
  },
);

export const crewMembershipNotificationInvalidated = onDocumentUpdated(
  "crew_memberships/{membershipId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after || after.notificationCleanupPending !== true ||
        typeof after.userId !== "string" || typeof after.crewId !== "string") return;
    await removeForRecipient("crewId", after.crewId, after.userId);
  },
);

export const outingNotificationsDeleted = onDocumentDeleted(
  "outings/{outingId}",
  async (event) => {
    await removeWhere("outingId", event.params.outingId);
  },
);

export const outingNotificationsInvalidated = onDocumentUpdated(
  "outings/{outingId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return;
    if (after.deletionPending === true ||
        after.notificationCleanupPending === true) {
      await removeWhere("outingId", event.params.outingId);
      return;
    }
    if (after.status !== "meeting") {
      await removeWhere("outingId", event.params.outingId, "attendee_arrived");
    }
  },
);

async function removeWhere(
  field: string,
  value: string,
  category?: string,
): Promise<number> {
  const db = getFirestore();
  let query: FirebaseFirestore.Query = db.collection("notifications")
    .where(field, "==", value);
  if (category) query = query.where("category", "==", category);
  const snapshot = await query.limit(200).get();
  const transactions = new NotificationTransactions(db);
  let removed = 0;
  for (const notification of snapshot.docs) {
    if (await transactions.remove(notification.ref, notification.data())) removed++;
  }
  return removed;
}

async function removeForRecipient(
  field: string,
  value: string,
  recipientUserId: string,
): Promise<number> {
  const db = getFirestore();
  const snapshot = await db.collection("notifications")
    .where(field, "==", value)
    .where("recipientUserId", "==", recipientUserId)
    .limit(200)
    .get();
  const transactions = new NotificationTransactions(db);
  let removed = 0;
  for (const notification of snapshot.docs) {
    if (await transactions.remove(notification.ref, notification.data())) removed++;
  }
  return removed;
}
