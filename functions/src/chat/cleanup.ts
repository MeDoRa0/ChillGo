import {Firestore, Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {getFirestore} from "firebase-admin/firestore";

export const CHAT_CLEANUP_BATCH_SIZE = 400;
export const CHAT_CLEANUP_MAX_BATCHES = 5;

interface CleanupTarget {
  collection: string;
  field: string;
  cutoff: Timestamp;
  statuses?: string[];
}

export function cleanupTargets(now: Timestamp): CleanupTarget[] {
  return [
    {collection: "chat_messages", field: "expiresAt", cutoff: now},
    {collection: "chat_commands", field: "deleteAt", cutoff: now},
    {
      collection: "chat_commands",
      field: "createdAt",
      cutoff: Timestamp.fromMillis(now.toMillis() - 24 * 60 * 60 * 1000),
      statuses: ["pending", "processing"],
    },
    {collection: "chat_read_states", field: "cursorExpiresAt", cutoff: now},
    {collection: "chat_rate_limits", field: "purgeAfter", cutoff: now},
    {
      collection: "chat_time_probes",
      field: "requestedAt",
      cutoff: Timestamp.fromMillis(now.toMillis() - 10 * 60 * 1000),
    },
  ];
}

export class ChatCleanupService {
  constructor(private readonly db: Firestore) {}

  async run(now: Timestamp = Timestamp.now()): Promise<number> {
    let deleted = 0;
    for (const target of cleanupTargets(now)) {
      try {
        deleted += await this.deleteTarget(target);
      } catch (error) {
        logger.error("chat_cleanup_failure", {
          collection: target.collection,
          cutoff: target.cutoff.toDate().toISOString(),
          code: safeErrorCode(error),
        });
      }
    }
    logger.info("chat_cleanup_terminal", {deleted});
    return deleted;
  }

  private async deleteTarget(target: CleanupTarget): Promise<number> {
    let total = 0;
    for (let batchNumber = 0; batchNumber < CHAT_CLEANUP_MAX_BATCHES; batchNumber++) {
      let query: FirebaseFirestore.Query = this.db.collection(target.collection)
        .where(target.field, "<=", target.cutoff)
        .limit(CHAT_CLEANUP_BATCH_SIZE);
      if (target.statuses) query = query.where("status", "in", target.statuses);
      const snapshot = await query.get();
      if (snapshot.empty) break;
      const batch = this.db.batch();
      for (const document of snapshot.docs) batch.delete(document.ref);
      await batch.commit();
      total += snapshot.size;
      logger.info("chat_cleanup_batch", {
        collection: target.collection,
        batchSize: snapshot.size,
        cutoff: target.cutoff.toDate().toISOString(),
      });
      if (snapshot.size < CHAT_CLEANUP_BATCH_SIZE) break;
    }
    return total;
  }
}

export function safeErrorCode(error: unknown): string {
  if (error && typeof error === "object" && "code" in error &&
      typeof (error as {code?: unknown}).code === "string") {
    return (error as {code: string}).code;
  }
  return "unknown";
}

export const chatCleanupScheduled = onSchedule(
  {schedule: "every 1 minutes", timeZone: "UTC"},
  async () => {
    await new ChatCleanupService(getFirestore()).run();
  },
);
