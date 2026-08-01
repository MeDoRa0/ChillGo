import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {NotificationTransactions} from "./notification_transactions";

export const NOTIFICATION_CLEANUP_BATCH_SIZE = 200;

export class NotificationCleanupService {
  constructor(private readonly db: FirebaseFirestore.Firestore) {}

  async run(now: Timestamp = Timestamp.now()): Promise<number> {
    let removed = 0;
    const expired = await this.db.collection("notifications")
      .where("expiresAt", "<=", now)
      .limit(NOTIFICATION_CLEANUP_BATCH_SIZE)
      .get();
    const transactions = new NotificationTransactions(this.db);
    for (const notification of expired.docs) {
      if (await transactions.remove(notification.ref, notification.data())) removed++;
    }
    const retainedCollections = new Map([
      ["notification_commands", "purgeAt"],
      ["notification_events", "purgeAt"],
      ["notification_recipient_work", "purgeAt"],
      ["notification_devices", "expiresAt"],
      ["notification_transitions", "purgeAt"],
    ]);
    for (const [collection, expiryField] of retainedCollections) {
      const stale = await this.db.collection(collection)
        .where(expiryField, "<=", now)
        .limit(NOTIFICATION_CLEANUP_BATCH_SIZE)
        .get();
      if (!stale.empty) {
        const batch = this.db.batch();
        for (const document of stale.docs) batch.delete(document.ref);
        await batch.commit();
        removed += stale.size;
      }
    }
    logger.info("notification_cleanup_terminal", {removed});
    return removed;
  }
}

export const notificationCleanupScheduled = onSchedule(
  {schedule: "every 1 minutes", timeZone: "UTC"},
  async () => {
    await new NotificationCleanupService(getFirestore()).run();
  },
);
