import {createHash} from "crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {
  NotificationCategory,
  parseNotificationEvent,
  resolveEligibleNotifications,
} from "./eligibility";
import {NotificationTransactions} from "./notification_transactions";

if (!getApps().length) initializeApp();

const EVENT_RETENTION_MS = 24 * 60 * 60 * 1000;

export const notificationEventCreated = onDocumentCreated(
  "notification_events/{eventId}",
  async (event) => {
    if (!event.data) return;
    const db = getFirestore();
    const parsed = parseNotificationEvent(event.data.data());
    const records = await resolveEligibleNotifications(db, parsed);
    const transactions = new NotificationTransactions(db);
    let created = 0;
    for (const record of records.slice(0, 100)) {
      const workId = deterministicId(parsed.sourceEventId, record.recipientUserId);
      const workRef = db.collection("notification_recipient_work").doc(workId);
      const claimed = await db.runTransaction(async (transaction) => {
        const work = await transaction.get(workRef);
        if (work.exists && work.data()?.status === "succeeded") return false;
        transaction.set(workRef, {
          sourceEventId: parsed.sourceEventId,
          recipientUserId: record.recipientUserId,
          status: "processing",
          updatedAt: Timestamp.now(),
          purgeAt: Timestamp.fromMillis(Date.now() + EVENT_RETENTION_MS),
        });
        return true;
      });
      if (!claimed) continue;
      const wasCreated = await transactions.create(record);
      await workRef.set({
        status: "succeeded",
        notificationId: deterministicId(
          parsed.sourceEventId,
          record.recipientUserId,
        ),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      if (wasCreated) created++;
    }
    logger.info("notification_event_terminal", {
      category: parsed.category,
      recipients: records.length,
      created,
    });
  },
);

export const crewInvitationNotificationEvent = onDocumentCreated(
  "crew_invitations/{invitationId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || typeof data.crewId !== "string" ||
        typeof data.invitedUserId !== "string") return;
    await writeEvent({
      stableKey: `crew_invitation:${event.params.invitationId}`,
      category: "crew_invitation",
      sourceId: event.params.invitationId,
      sourceVersion: "1",
      crewId: data.crewId,
      recipientUserId: data.invitedUserId,
    });
  },
);

export const crewMembershipNotificationEvent = onDocumentCreated(
  "crew_memberships/{membershipId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.role !== "member" || typeof data.crewId !== "string" ||
        typeof data.userId !== "string") return;
    await writeEvent({
      stableKey: `crew_member_joined:${event.params.membershipId}`,
      category: "crew_member_joined",
      sourceId: event.params.membershipId,
      sourceVersion: "1",
      crewId: data.crewId,
      actorUserId: data.userId,
    });
  },
);

export const outingInvitationNotificationEvent = onDocumentCreated(
  "outing_participants/{participantId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.isCreatorParticipant === true ||
        data.attendanceStatus !== "invited" ||
        typeof data.crewId !== "string" || typeof data.outingId !== "string" ||
        typeof data.userId !== "string") return;
    await writeEvent({
      stableKey: `outing_invitation:${event.params.participantId}`,
      category: "outing_invitation",
      sourceId: event.params.participantId,
      sourceVersion: "1",
      crewId: data.crewId,
      outingId: data.outingId,
      recipientUserId: data.userId,
    });
  },
);

export const outingChangedNotificationEvent = onDocumentUpdated(
  "outings/{outingId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || typeof after.crewId !== "string") return;
    if (before.status === "planning" && after.status === "confirmed") return;
    const changedFields = ["title", "description", "scheduledAt", "locationText"]
      .filter((field) => !same(before[field], after[field]));
    if (!changedFields.length) return;
    await writeEvent({
      stableKey: `outing_changed:${event.id}`,
      category: "outing_changed",
      sourceId: event.params.outingId,
      sourceVersion: event.id,
      crewId: after.crewId,
      outingId: event.params.outingId,
      actorUserId: typeof after.updatedByUserId === "string" ?
        after.updatedByUserId : undefined,
      changedFields,
    });
  },
);

export const votingUpdateNotificationEvent = onDocumentCreated(
  "agreement_proposals/{proposalId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.isSeed === true || typeof data.crewId !== "string" ||
        typeof data.outingId !== "string" ||
        typeof data.authorUserId !== "string") return;
    await writeEvent({
      stableKey: `voting_update:${event.params.proposalId}`,
      category: "voting_update",
      sourceId: event.params.proposalId,
      sourceVersion: "1",
      crewId: data.crewId,
      outingId: data.outingId,
      actorUserId: data.authorUserId,
    });
  },
);

export const agreementRoundCreatedNotificationEvent = onDocumentCreated(
  "agreement_rounds/{roundId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || typeof data.reopenReason !== "string" ||
        typeof data.crewId !== "string" || typeof data.outingId !== "string") return;
    await writeEvent({
      stableKey: `agreement_reopened:${event.params.roundId}`,
      category: "agreement_reopened",
      sourceId: event.params.roundId,
      sourceVersion: "1",
      crewId: data.crewId,
      outingId: data.outingId,
      actorUserId: typeof data.openedByUserId === "string" ?
        data.openedByUserId : undefined,
    });
  },
);

export const agreementRoundConfirmedNotificationEvent = onDocumentUpdated(
  "agreement_rounds/{roundId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === "confirmed" ||
        after.status !== "confirmed" || typeof after.crewId !== "string" ||
        typeof after.outingId !== "string") return;
    await writeEvent({
      stableKey: `agreement_confirmed:${event.params.roundId}`,
      category: "agreement_confirmed",
      sourceId: event.params.roundId,
      sourceVersion: "1",
      crewId: after.crewId,
      outingId: after.outingId,
      actorUserId: typeof after.confirmedByUserId === "string" ?
        after.confirmedByUserId : undefined,
    });
  },
);

export const attendeeArrivedNotificationEvent = onDocumentUpdated(
  "live_meetup_statuses/{statusId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.value === "arrived" ||
        after.value !== "arrived" || typeof after.crewId !== "string" ||
        typeof after.outingId !== "string" || typeof after.userId !== "string") return;
    await writeEvent({
      stableKey: `attendee_arrived:${after.outingId}:${after.userId}`,
      category: "attendee_arrived",
      sourceId: event.params.statusId,
      sourceVersion: "1",
      crewId: after.crewId,
      outingId: after.outingId,
      actorUserId: after.userId,
    });
  },
);

export const attendeeInitiallyArrivedNotificationEvent = onDocumentCreated(
  "live_meetup_statuses/{statusId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.value !== "arrived" || typeof data.crewId !== "string" ||
        typeof data.outingId !== "string" || typeof data.userId !== "string") return;
    await writeEvent({
      stableKey: `attendee_arrived:${data.outingId}:${data.userId}`,
      category: "attendee_arrived",
      sourceId: event.params.statusId,
      sourceVersion: "1",
      crewId: data.crewId,
      outingId: data.outingId,
      actorUserId: data.userId,
    });
  },
);

interface EventInput {
  stableKey: string;
  category: NotificationCategory;
  sourceId: string;
  sourceVersion: string;
  crewId: string;
  outingId?: string;
  actorUserId?: string;
  recipientUserId?: string;
  changedFields?: string[];
}

export async function writeEvent(input: EventInput): Promise<void> {
  const sourceEventId = deterministicId(input.stableKey);
  const createdAt = Timestamp.now();
  await getFirestore().collection("notification_events").doc(sourceEventId).set({
    sourceEventId,
    category: input.category,
    sourceId: input.sourceId,
    sourceVersion: input.sourceVersion,
    crewId: input.crewId,
    ...(input.outingId ? {outingId: input.outingId} : {}),
    ...(input.actorUserId ? {actorUserId: input.actorUserId} : {}),
    ...(input.recipientUserId ? {recipientUserId: input.recipientUserId} : {}),
    ...(input.changedFields ? {changedFields: input.changedFields} : {}),
    createdAt,
    purgeAt: Timestamp.fromMillis(createdAt.toMillis() + EVENT_RETENTION_MS),
  }, {merge: false});
}

function deterministicId(...parts: string[]): string {
  return createHash("sha256").update(parts.join("\u0000")).digest("hex");
}

function same(left: unknown, right: unknown): boolean {
  if (left instanceof Timestamp && right instanceof Timestamp) {
    return left.isEqual(right);
  }
  return left === right;
}
