import {getApps, initializeApp} from "firebase-admin/app";
import {
  DocumentSnapshot,
  FieldPath,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {NotificationCommandError} from "./command_schema";
import {authorizeNotification} from "./eligibility";
import {NotificationTransactions} from "./notification_transactions";

if (!getApps().length) initializeApp();

const PAGE_SIZE = 50;
const SCAN_SIZE = 100;
const MAX_SCANS = 5;

interface CenterCursor {
  createdAt: Timestamp;
  notificationId: string;
}

export class NotificationCenterQueryService {
  constructor(private readonly db: FirebaseFirestore.Firestore) {}

  async page(
    userId: string,
    initialCursor?: CenterCursor,
  ): Promise<Record<string, unknown>> {
    const notifications: Record<string, unknown>[] = [];
    let cursor = initialCursor;
    let lastScanned: DocumentSnapshot | undefined;
    let exhausted = false;

    for (let scan = 0; scan < MAX_SCANS && notifications.length < PAGE_SIZE; scan++) {
      let query = this.db.collection("notifications")
        .where("recipientUserId", "==", userId)
        .orderBy("createdAt", "desc")
        .orderBy(FieldPath.documentId(), "desc")
        .limit(SCAN_SIZE);
      if (cursor) query = query.startAfter(cursor.createdAt, cursor.notificationId);
      const snapshot = await query.get();
      if (snapshot.empty) {
        exhausted = true;
        break;
      }
      for (const notification of snapshot.docs) {
        lastScanned = notification;
        cursor = {
          createdAt: notification.get("createdAt"),
          notificationId: notification.id,
        };
        try {
          await authorizeNotification(this.db, notification.data(), userId);
          notifications.push(serializeNotification(notification));
          if (notifications.length === PAGE_SIZE) break;
        } catch (error) {
          if (!(error instanceof NotificationCommandError)) throw error;
          await new NotificationTransactions(this.db).remove(
            notification.ref,
            notification.data(),
          );
        }
      }
      if (snapshot.size < SCAN_SIZE) {
        exhausted = true;
        break;
      }
    }

    const scannedCreatedAt = lastScanned?.get("createdAt");
    const nextCursor = !exhausted && scannedCreatedAt instanceof Timestamp ? {
      createdAt: scannedCreatedAt.toDate().toISOString(),
      notificationId: lastScanned!.id,
    } : null;
    return {items: notifications, nextCursor};
  }
}

export const notificationCenterPage = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) throw new HttpsError("unauthenticated", "Sign in required.");
    return new NotificationCenterQueryService(getFirestore()).page(
      userId,
      parseCursor(request.data),
    );
  },
);

function parseCursor(payload: unknown): CenterCursor | undefined {
  if (!payload || typeof payload !== "object") return undefined;
  const rawCursor = (payload as {cursor?: unknown}).cursor;
  if (!rawCursor || typeof rawCursor !== "object") return undefined;
  const cursor = rawCursor as {createdAt?: unknown; notificationId?: unknown};
  if (typeof cursor.createdAt !== "string" ||
      typeof cursor.notificationId !== "string" ||
      cursor.notificationId.length > 200) {
    throw new HttpsError("invalid-argument", "Invalid notification cursor.");
  }
  const createdAt = new Date(cursor.createdAt);
  if (Number.isNaN(createdAt.getTime())) {
    throw new HttpsError("invalid-argument", "Invalid notification cursor.");
  }
  return {
    createdAt: Timestamp.fromDate(createdAt),
    notificationId: cursor.notificationId,
  };
}

function serializeNotification(
  snapshot: DocumentSnapshot,
): Record<string, unknown> {
  const notification = snapshot.data()!;
  return {
    id: snapshot.id,
    recipientUserId: notification.recipientUserId,
    category: notification.category,
    target: notification.target,
    display: notification.display,
    createdAt: timestampIso(notification.createdAt),
    expiresAt: timestampIso(notification.expiresAt),
    readAt: notification.readAt instanceof Timestamp ?
      notification.readAt.toDate().toISOString() : null,
  };
}

function timestampIso(timestamp: unknown): string {
  if (!(timestamp instanceof Timestamp)) {
    throw new Error("Trusted notification timestamp is invalid.");
  }
  return timestamp.toDate().toISOString();
}
