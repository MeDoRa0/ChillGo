import {initializeApp, App, deleteApp} from "firebase-admin/app";
import {getAuth, Auth} from "firebase-admin/auth";
import {getFirestore, Firestore, Timestamp} from "firebase-admin/firestore";

let sequence = 0;

export interface ChatTestHarness {
  app: App;
  auth: Auth;
  db: Firestore;
  cleanup(): Promise<void>;
}

export function createChatTestHarness(projectId = "chillgo-61439"): ChatTestHarness {
  const app = initializeApp({projectId}, `chat-test-${++sequence}`);
  const auth = getAuth(app);
  const db = getFirestore(app);
  return {app, auth, db, cleanup: async () => deleteApp(app)};
}

export async function seedEligibleChat(
  db: Firestore,
  options: {
    outingId?: string;
    crewId?: string;
    userId?: string;
    status?: string;
  } = {},
): Promise<void> {
  const outingId = options.outingId ?? "outing-1";
  const crewId = options.crewId ?? "crew-1";
  const userId = options.userId ?? "user-1";
  const now = Timestamp.fromDate(new Date("2026-07-22T12:00:00Z"));
  await Promise.all([
    db.collection("users").doc(userId).set({
      username: userId,
      displayName: "Chat Tester",
      avatarUrl: null,
      createdAt: now,
    }),
    db.collection("crews").doc(crewId).set({
      name: "Chat Crew",
      ownerId: userId,
      createdAt: now,
    }),
    db.collection("crew_memberships").doc(`${crewId}_${userId}`).set({
      crewId,
      userId,
      role: "owner",
      joinedAt: now,
      username: userId,
      displayName: "Chat Tester",
    }),
    db.collection("outings").doc(outingId).set({
      crewId,
      title: "Chat Outing",
      locationText: "Trail",
      scheduledAt: now,
      status: options.status ?? "planning",
      createdByUserId: userId,
      createdAt: now,
      updatedAt: now,
      agreementRoundSequence: 0,
    }),
    db.collection("outing_participants").doc(`${outingId}_${userId}`).set({
      outingId,
      crewId,
      userId,
      username: userId,
      displayName: "Chat Tester",
      addedByUserId: userId,
      addedAt: now,
      isCreatorParticipant: true,
      attendanceStatus: "accepted",
      respondedAt: now,
    }),
  ]);
}

export function chatCommand(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    type: "send_message",
    outingId: "outing-1",
    crewId: "crew-1",
    requestedByUserId: "user-1",
    clientMessageId: "client-message-0001",
    payload: {text: "Hello"},
    status: "pending",
    createdAt: Timestamp.now(),
    ...overrides,
  };
}
