import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {getMessaging, Messaging, MulticastMessage} from "firebase-admin/messaging";
import {logger} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {NotificationCommandError} from "./command_schema";
import {authorizeNotification} from "./eligibility";
import {NotificationTransactions} from "./notification_transactions";

if (!getApps().length) initializeApp();

const OPTIONAL_PREFERENCE: Record<string, string> = {
  voting_update: "votingUpdatesEnabled",
  outing_changed: "outingChangesEnabled",
  attendee_arrived: "arrivalAlertsEnabled",
};

export const notificationDeliveryCreated = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    if (!event.data) return;
    await deliverNotification(
      getFirestore(),
      getMessaging(),
      event.params.notificationId,
      event.data.data(),
    );
  },
);

export async function deliverNotification(
  db: FirebaseFirestore.Firestore,
  messaging: Messaging,
  notificationId: string,
  data: FirebaseFirestore.DocumentData,
): Promise<number> {
  try {
    await authorizeNotification(db, data, String(data.recipientUserId));
  } catch (error) {
    if (!(error instanceof NotificationCommandError)) throw error;
    await new NotificationTransactions(db).remove(
      db.collection("notifications").doc(notificationId),
      data,
    );
    return 0;
  }
  const preferenceField = OPTIONAL_PREFERENCE[String(data.category)];
  if (preferenceField) {
    const preferences = await db.collection("notification_preferences")
      .doc(String(data.recipientUserId)).get();
    if (preferences.exists && preferences.data()?.[preferenceField] === false) return 0;
  }
  const devices = await db.collection("notification_devices")
    .where("userId", "==", data.recipientUserId)
    .where("permissionState", "==", "granted")
    .limit(10)
    .get();
  const freshDevices = devices.docs.filter((doc) =>
    doc.data().expiresAt instanceof Timestamp &&
    doc.data().expiresAt.toMillis() > Date.now() &&
    typeof doc.data().token === "string",
  );
  if (!freshDevices.length) return 0;
  const response = await messaging.sendEachForMulticast(genericAlertMessage(
    freshDevices.map((device) => device.data().token),
    notificationId,
    String(data.category),
  ));
  const invalidTargets = response.responses.flatMap((targetResponse, index) =>
    !targetResponse.success && invalidTokenCode(targetResponse.error?.code) ?
      [freshDevices[index].ref] : [],
  );
  if (invalidTargets.length) {
    const removalBatch = db.batch();
    for (const target of invalidTargets) removalBatch.delete(target);
    await removalBatch.commit();
  }
  logger.info("notification_delivery_terminal", {
    notificationId,
    targets: freshDevices.length,
    successes: response.successCount,
  });
  return response.successCount;
}

export function genericAlertMessage(
  tokens: string[],
  notificationId: string,
  category: string,
): MulticastMessage {
  return {
    tokens,
    notification: {
      title: "ChillGo update",
      body: "Open ChillGo to view your notification.",
    },
    data: {notificationId, category, schemaVersion: "1"},
    android: {priority: "high"},
    apns: {payload: {aps: {sound: "default"}}},
  };
}

export function invalidTokenCode(code: string | undefined): boolean {
  return code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token" ||
    code === "messaging/invalid-argument";
}
