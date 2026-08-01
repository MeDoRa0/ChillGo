import {DocumentData, Firestore, Timestamp} from "firebase-admin/firestore";
import {NotificationCommandError} from "./command_schema";
import {NotificationRecordInput} from "./notification_transactions";

export const NOTIFICATION_CATEGORIES = [
  "crew_invitation",
  "outing_invitation",
  "voting_update",
  "agreement_confirmed",
  "agreement_reopened",
  "outing_changed",
  "attendee_arrived",
] as const;

export type NotificationCategory = typeof NOTIFICATION_CATEGORIES[number];

export interface NotificationEvent {
  sourceEventId: string;
  sourceVersion: string;
  sourceId: string;
  category: NotificationCategory;
  crewId: string;
  outingId?: string;
  actorUserId?: string;
  recipientUserId?: string;
  changedFields?: string[];
  createdAt: Timestamp;
}

export function parseNotificationEvent(data: DocumentData): NotificationEvent {
  if (!NOTIFICATION_CATEGORIES.includes(data.category) ||
      !strings(data, ["sourceEventId", "sourceVersion", "sourceId", "crewId"]) ||
      !(data.createdAt instanceof Timestamp)) {
    throw new Error("Invalid notification event.");
  }
  return {
    sourceEventId: data.sourceEventId,
    sourceVersion: data.sourceVersion,
    sourceId: data.sourceId,
    category: data.category,
    crewId: data.crewId,
    ...(typeof data.outingId === "string" ? {outingId: data.outingId} : {}),
    ...(typeof data.actorUserId === "string" ? {actorUserId: data.actorUserId} : {}),
    ...(typeof data.recipientUserId === "string" ?
      {recipientUserId: data.recipientUserId} : {}),
    ...(Array.isArray(data.changedFields) ?
      {changedFields: data.changedFields.filter((value: unknown) =>
        typeof value === "string")} : {}),
    createdAt: data.createdAt,
  };
}

export async function resolveEligibleNotifications(
  db: Firestore,
  event: NotificationEvent,
): Promise<NotificationRecordInput[]> {
  if (event.category === "crew_invitation") {
    return resolveCrewInvitation(db, event);
  }
  const outingId = event.outingId;
  if (!outingId) return [];
  const [outingSnapshot, crewSnapshot] = await Promise.all([
    db.collection("outings").doc(outingId).get(),
    db.collection("crews").doc(event.crewId).get(),
  ]);
  if (!outingSnapshot.exists || deniedOuting(outingSnapshot.data()!) ||
      !crewSnapshot.exists || crewSnapshot.data()?.deletionPending === true) return [];
  const outing = outingSnapshot.data()!;
  if (outing.crewId !== event.crewId) return [];
  if (event.category === "outing_invitation") {
    return resolveOutingInvitation(db, event, outing);
  }
  const recipients = await eligibleParticipants(db, event.crewId, outingId);
  const excludesActor = event.category === "voting_update" ||
    event.category === "attendee_arrived";
  const filtered = recipients.filter((participant) =>
    (!excludesActor || participant.userId !== event.actorUserId) &&
    (event.category !== "voting_update" ||
      (outing.status === "planning" &&
       participant.attendanceStatus === "accepted")) &&
    (event.category !== "attendee_arrived" ||
      (outing.status === "meeting" &&
       participant.attendanceStatus === "accepted" &&
       participant.liveMeetupCleanupPending !== true)),
  );
  const display = await displayForEvent(db, event, outing);
  return filtered.map((participant) => recordForEvent(
    event,
    participant.userId,
    display,
  ));
}

export async function authorizeNotification(
  db: Firestore,
  notification: DocumentData,
  userId: string,
  now: Timestamp = Timestamp.now(),
): Promise<void> {
  if (notification.recipientUserId !== userId ||
      !NOTIFICATION_CATEGORIES.includes(notification.category) ||
      typeof notification.crewId !== "string" ||
      typeof notification.sourceId !== "string") {
    throw new NotificationCommandError("permission_denied", "Notification unavailable.");
  }
  if (!(notification.expiresAt instanceof Timestamp) ||
      notification.expiresAt.toMillis() <= now.toMillis()) {
    throw new NotificationCommandError("expired", "Notification expired.");
  }
  if (notification.category === "crew_invitation") {
    const [invitation, crew] = await Promise.all([
      db.collection("crew_invitations").doc(String(notification.sourceId)).get(),
      db.collection("crews").doc(String(notification.crewId)).get(),
    ]);
    if (!invitation.exists || invitation.data()?.invitedUserId !== userId ||
        invitation.data()?.crewId !== notification.crewId || !crew.exists ||
        crew.data()?.deletionPending === true) {
      throw unavailable();
    }
    return;
  }
  const outingId = notification.outingId;
  if (typeof outingId !== "string") throw unavailable();
  const [outing, crew, membership, participant] = await Promise.all([
    db.collection("outings").doc(outingId).get(),
    db.collection("crews").doc(notification.crewId).get(),
    db.collection("crew_memberships").doc(`${notification.crewId}_${userId}`).get(),
    db.collection("outing_participants").doc(`${outingId}_${userId}`).get(),
  ]);
  if (!outing.exists || outing.data()?.crewId !== notification.crewId ||
      deniedOuting(outing.data()!) || !crew.exists ||
      crew.data()?.deletionPending === true || !membership.exists ||
      membership.data()?.notificationCleanupPending === true || !participant.exists ||
      participant.data()?.notificationCleanupPending === true) {
    throw unavailable();
  }
  if (notification.category === "outing_invitation" &&
      participant.data()?.attendanceStatus !== "invited") throw unavailable();
  if (notification.category === "attendee_arrived" &&
      (outing.data()?.status !== "meeting" ||
       membership.data()?.liveMeetupCleanupPending === true ||
       participant.data()?.liveMeetupCleanupPending === true ||
       participant.data()?.attendanceStatus !== "accepted")) throw unavailable();
}

function resolveCrewInvitation(
  db: Firestore,
  event: NotificationEvent,
): Promise<NotificationRecordInput[]> {
  return Promise.all([
    db.collection("crew_invitations").doc(event.sourceId).get(),
    db.collection("crews").doc(event.crewId).get(),
  ]).then(([invitation, crew]) => {
    const recipient = invitation.data()?.invitedUserId;
    if (!invitation.exists || !crew.exists || crew.data()?.deletionPending === true ||
        invitation.data()?.crewId !== event.crewId || typeof recipient !== "string" ||
        (event.recipientUserId && event.recipientUserId !== recipient)) return [];
    return [recordForEvent(event, recipient, {
      title: "Crew invitation",
      body: `You were invited to ${safeLabel(crew.data()?.name, "a crew")}.`,
    })];
  });
}

async function resolveOutingInvitation(
  db: Firestore,
  event: NotificationEvent,
  outing: DocumentData,
): Promise<NotificationRecordInput[]> {
  if (!event.recipientUserId) return [];
  const [participant, membership] = await Promise.all([
    db.collection("outing_participants").doc(event.sourceId).get(),
    db.collection("crew_memberships")
      .doc(`${event.crewId}_${event.recipientUserId}`).get(),
  ]);
  if (!participant.exists || !membership.exists ||
      participant.data()?.crewId !== event.crewId ||
      participant.data()?.outingId !== event.outingId ||
      participant.data()?.userId !== event.recipientUserId ||
      participant.data()?.attendanceStatus !== "invited" ||
      participant.data()?.isCreatorParticipant === true) return [];
  return [recordForEvent(event, event.recipientUserId, {
    title: "Outing invitation",
    body: `You were invited to ${safeLabel(outing.title, "an outing")}.`,
  })];
}

async function eligibleParticipants(
  db: Firestore,
  crewId: string,
  outingId: string,
): Promise<DocumentData[]> {
  const [participants, memberships] = await Promise.all([
    db.collection("outing_participants").where("outingId", "==", outingId).get(),
    db.collection("crew_memberships").where("crewId", "==", crewId).get(),
  ]);
  const members = new Set(memberships.docs
    .filter((doc) => doc.data().notificationCleanupPending !== true &&
      doc.data().liveMeetupCleanupPending !== true)
    .map((doc) => doc.data().userId));
  return participants.docs.map((doc) => doc.data()).filter((participant) =>
    typeof participant.userId === "string" && members.has(participant.userId) &&
    participant.notificationCleanupPending !== true,
  );
}

function recordForEvent(
  event: NotificationEvent,
  recipientUserId: string,
  display: {title: string; body: string},
): NotificationRecordInput {
  const targetType = event.category === "crew_invitation" ? "invitations" :
    event.category === "attendee_arrived" ? "live_meetup" : "agreement";
  return {
    sourceEventId: event.sourceEventId,
    sourceVersion: event.sourceVersion,
    sourceId: event.sourceId,
    recipientUserId,
    category: event.category,
    crewId: event.crewId,
    ...(event.outingId ? {outingId: event.outingId} : {}),
    target: {
      type: targetType,
      crewId: event.crewId,
      ...(event.outingId ? {outingId: event.outingId} : {}),
    },
    display,
    createdAt: event.createdAt,
  };
}

async function displayForEvent(
  db: Firestore,
  event: NotificationEvent,
  outing: DocumentData,
): Promise<{title: string; body: string}> {
  const outingName = safeLabel(outing.title, "your outing");
  switch (event.category) {
  case "voting_update":
    return {title: "New outing proposal", body: `Voting was updated for ${outingName}.`};
  case "agreement_confirmed":
    return {
      title: "Plan confirmed",
      body: confirmedPlanBody(outingName, outing),
    };
  case "agreement_reopened":
    return {title: "Voting reopened", body: `Voting is open again for ${outingName}.`};
  case "outing_changed": {
    const fields = (event.changedFields ?? []).slice(0, 4).join(", ");
    return {
      title: "Outing updated",
      body: fields ? `${outingName} changed: ${fields}.` : `${outingName} was updated.`,
    };
  }
  case "attendee_arrived": {
    const actor = event.actorUserId ? await db.collection("outing_participants")
      .doc(`${event.outingId}_${event.actorUserId}`).get() : undefined;
    const attendee = safeLabel(actor?.data()?.displayName, "An attendee");
    return {title: "Attendee arrived", body: `${attendee} arrived for ${outingName}.`};
  }
  default:
    return {title: "ChillGo update", body: `Open ${outingName} for details.`};
  }
}

function confirmedPlanBody(outingName: string, outing: DocumentData): string {
  const scheduledAt = outing.scheduledAt instanceof Timestamp ?
    outing.scheduledAt.toDate().toISOString() : undefined;
  const location = safeLabel(outing.locationText, "the confirmed location");
  return scheduledAt ?
    `${outingName} is set for ${scheduledAt} at ${location}.` :
    `The plan for ${outingName} is confirmed at ${location}.`;
}

function deniedOuting(data: DocumentData): boolean {
  return data.deletionPending === true || data.notificationCleanupPending === true ||
    data.liveMeetupCleanupPending === true;
}

function unavailable(): NotificationCommandError {
  return new NotificationCommandError("unavailable", "Notification unavailable.");
}

function safeLabel(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim() ? value.trim().slice(0, 120) : fallback;
}

function strings(data: DocumentData, keys: string[]): boolean {
  return keys.every((key) => typeof data[key] === "string" && data[key].length > 0);
}
