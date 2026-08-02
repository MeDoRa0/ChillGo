import {createHash} from "crypto";
import {
  DocumentData,
  DocumentReference,
  Firestore,
  Timestamp,
} from "firebase-admin/firestore";

export const NOTIFICATION_RETENTION_MS = 30 * 24 * 60 * 60 * 1000;

export interface NotificationRecordInput {
  sourceEventId: string;
  sourceVersion: string;
  sourceId: string;
  recipientUserId: string;
  category: string;
  crewId: string;
  outingId?: string;
  target: Record<string, string>;
  display: {title: string; body: string; avatarUrl?: string};
  createdAt: Timestamp;
}

export function deterministicNotificationId(
  sourceEventId: string,
  recipientUserId: string,
): string {
  return createHash("sha256")
    .update(`${sourceEventId}\u0000${recipientUserId}`)
    .digest("hex");
}

export class NotificationTransactions {
  constructor(private readonly db: Firestore) {}

  async create(input: NotificationRecordInput): Promise<boolean> {
    const id = deterministicNotificationId(
      input.sourceEventId,
      input.recipientUserId,
    );
    const notificationRef = this.db.collection("notifications").doc(id);
    const summaryRef = this.db.collection("notification_summaries")
      .doc(input.recipientUserId);
    return this.db.runTransaction(async (transaction) => {
      const existing = await transaction.get(notificationRef);
      if (existing.exists) return false;
      const summary = await transaction.get(summaryRef);
      const unreadCount = number(summary.data()?.unreadCount);
      transaction.set(notificationRef, {
        ...input,
        expiresAt: Timestamp.fromMillis(
          input.createdAt.toMillis() + NOTIFICATION_RETENTION_MS,
        ),
        readAt: null,
      });
      transaction.set(summaryRef, {
        userId: input.recipientUserId,
        unreadCount: unreadCount + 1,
        updatedAt: input.createdAt,
      });
      return true;
    });
  }

  async markRead(
    notificationRef: DocumentReference,
    recipientUserId: string,
    now: Timestamp = Timestamp.now(),
  ): Promise<boolean> {
    const summaryRef = this.db.collection("notification_summaries")
      .doc(recipientUserId);
    return this.db.runTransaction(async (transaction) => {
      const [notification, summary] = await Promise.all([
        transaction.get(notificationRef),
        transaction.get(summaryRef),
      ]);
      if (!notification.exists) return false;
      if (notification.data()?.readAt instanceof Timestamp) return true;
      transaction.update(notificationRef, {readAt: now});
      transaction.set(summaryRef, {
        userId: recipientUserId,
        unreadCount: Math.max(0, number(summary.data()?.unreadCount) - 1),
        updatedAt: now,
      });
      return true;
    });
  }

  async remove(ref: DocumentReference, data?: DocumentData): Promise<boolean> {
    const snapshot = data ? undefined : await ref.get();
    const record = data ?? snapshot?.data();
    if (!record || typeof record.recipientUserId !== "string") return false;
    const summaryRef = this.db.collection("notification_summaries")
      .doc(record.recipientUserId);
    return this.db.runTransaction(async (transaction) => {
      const [current, summary] = await Promise.all([
        transaction.get(ref),
        transaction.get(summaryRef),
      ]);
      if (!current.exists) return false;
      transaction.delete(ref);
      const decrement = current.data()?.readAt instanceof Timestamp ? 0 : 1;
      transaction.set(summaryRef, {
        userId: record.recipientUserId,
        unreadCount: Math.max(0, number(summary.data()?.unreadCount) - decrement),
        updatedAt: Timestamp.now(),
      });
      return true;
    });
  }
}

function number(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
