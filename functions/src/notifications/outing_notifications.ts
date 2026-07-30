import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

if (!getApps().length) initializeApp();

export const outingCreatedNotifications = onDocumentCreated(
  "outings/{outingId}",
  async (event) => {
    const outing = event.data;
    if (!outing) return;

    const data = outing.data();
    const crewId = data["crewId"];
    const creatorUserId = data["createdByUserId"];
    const outingTitle = data["title"];
    if (
      typeof crewId !== "string" ||
      typeof creatorUserId !== "string" ||
      typeof outingTitle !== "string"
    ) {
      return;
    }

    const firestore = getFirestore();
    const [creator, memberships] = await Promise.all([
      firestore.collection("users").doc(creatorUserId).get(),
      firestore
        .collection("crew_memberships")
        .where("crewId", "==", crewId)
        .get(),
    ]);
    const creatorData = creator.data();
    const creatorDisplayName =
      typeof creatorData?.["displayName"] === "string" &&
          creatorData["displayName"].trim().length > 0
      ? creatorData["displayName"].trim()
      : "A crew member";
    const createdAt = Timestamp.now();
    const writer = firestore.bulkWriter();

    for (const membership of memberships.docs) {
      const recipientUserId = membership.data()["userId"];
      if (recipientUserId === creatorUserId || typeof recipientUserId !== "string") {
        continue;
      }
      writer.set(
        firestore.collection("notifications").doc(`${outing.id}_${recipientUserId}`),
        {
          recipientUserId,
          category: "outing_review",
          crewId,
          outingId: outing.id,
          creatorDisplayName,
          outingTitle,
          createdAt,
        },
        {merge: true},
      );
    }
    await writer.close();
  },
);
