import {createHash} from "crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {
  NotificationCommand,
  NotificationCommandError,
  parseNotificationCommand,
  terminalNotificationCommandFields,
} from "./command_schema";
import {authorizeNotification} from "./eligibility";
import {NotificationTransactions} from "./notification_transactions";

if (!getApps().length) initializeApp();

export const notificationCommandCreated = onDocumentCreated(
  "notification_commands/{commandId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    try {
      const command = parseNotificationCommand(snapshot.data());
      const claimed = await snapshot.ref.firestore.runTransaction(async (transaction) => {
        const current = await transaction.get(snapshot.ref);
        if (current.data()?.status !== "pending") return false;
        transaction.update(snapshot.ref, {
          status: "processing",
          processingEventId: event.id,
        });
        return true;
      });
      if (!claimed) return;
      const result = await executeNotificationCommand(command);
      await snapshot.ref.update(
        terminalNotificationCommandFields("succeeded", result),
      );
    } catch (error) {
      const safe = safeNotificationCommandError(error);
      const current = await snapshot.ref.get();
      if (["succeeded", "failed"].includes(current.data()?.status)) return;
      await snapshot.ref.update(
        terminalNotificationCommandFields("failed", undefined, safe),
      );
      logger.warn("notification_command_failed", {code: safe.code});
    }
  },
);

export async function executeNotificationCommand(
  command: NotificationCommand,
): Promise<Record<string, unknown>> {
  const db = getFirestore();
  if (command.type === "register_device") {
    const installationId = String(command.payload.installationId);
    const token = String(command.payload.token);
    const existing = await db.collection("notification_devices")
      .where("userId", "==", command.requestedByUserId).get();
    const id = deviceId(command.requestedByUserId, installationId);
    if (existing.size >= 10 && !existing.docs.some((doc) => doc.id === id)) {
      throw new NotificationCommandError("device_limit", "Device limit reached.");
    }
    const duplicateTokens = await db.collection("notification_devices")
      .where("token", "==", token).get();
    const batch = db.batch();
    for (const duplicate of duplicateTokens.docs) {
      if (duplicate.id !== id) batch.delete(duplicate.ref);
    }
    const now = Timestamp.now();
    batch.set(db.collection("notification_devices").doc(id), {
      userId: command.requestedByUserId,
      installationId,
      token,
      platform: command.payload.platform,
      permissionState: "granted",
      createdAt: existing.docs.find((doc) => doc.id === id)?.data().createdAt ?? now,
      updatedAt: now,
      lastSeenAt: now,
      expiresAt: Timestamp.fromMillis(now.toMillis() + 30 * 24 * 60 * 60 * 1000),
    });
    await batch.commit();
    return {registered: true};
  }
  if (command.type === "unregister_device") {
    await db.collection("notification_devices")
      .doc(deviceId(command.requestedByUserId, String(command.payload.installationId)))
      .delete();
    return {unregistered: true};
  }
  const notificationId = String(command.payload.notificationId);
  const ref = db.collection("notifications").doc(notificationId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    throw new NotificationCommandError("not_found", "Notification unavailable.");
  }
  await authorizeNotification(db, snapshot.data()!, command.requestedByUserId);
  const available = await new NotificationTransactions(db).markRead(
    ref,
    command.requestedByUserId,
  );
  if (!available) {
    throw new NotificationCommandError("not_found", "Notification unavailable.");
  }
  if (command.type === "open") return {target: snapshot.data()!.target};
  return {read: true};
}

export function safeNotificationCommandError(error: unknown): NotificationCommandError {
  return error instanceof NotificationCommandError ? error :
    new NotificationCommandError("internal_error", "Notifications unavailable.");
}

function deviceId(userId: string, installationId: string): string {
  return createHash("sha256")
    .update(`${userId}\u0000${installationId}`)
    .digest("hex");
}
