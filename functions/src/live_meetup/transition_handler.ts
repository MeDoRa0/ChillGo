import {initializeApp, getApps} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {PrivacyTransitionCoordinator} from "./privacy_transition_coordinator";
import {
  parseLiveMeetupTransition,
  terminalTransitionFields,
  TransitionError,
} from "./transition_schema";

if (!getApps().length) initializeApp();

export const liveMeetupTransitionCreated = onDocumentCreated(
  {
    document: "live_meetup_transitions/{transitionId}",
    retry: true,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const started = Date.now();
    try {
      const transition = parseLiveMeetupTransition(snapshot.data());
      const claimed = await getFirestore().runTransaction(async (tx) => {
        const current = await tx.get(snapshot.ref);
        const data = current.data();
        if (!data || ["succeeded", "failed"].includes(data.status)) return false;
        if (data.status === "processing" &&
            data.processingEventId !== event.id &&
            data.leaseExpiresAt instanceof Timestamp &&
            data.leaseExpiresAt.toMillis() > Date.now()) return false;
        tx.update(snapshot.ref, {
          status: "processing",
          phase: data.phase ?? "authorize",
          processingEventId: event.id,
          leaseExpiresAt: Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
        });
        return true;
      });
      if (!claimed) return;
      const result = await new PrivacyTransitionCoordinator(getFirestore())
        .run(snapshot.id, transition);
      await snapshot.ref.update(
        terminalTransitionFields(transition.createdAt, "succeeded", result),
      );
      logger.info("live_meetup_transition_terminal", {
        type: transition.type,
        status: "succeeded",
        latencyMs: Date.now() - started,
      });
    } catch (error) {
      if (!(error instanceof TransitionError)) {
        logger.error("live_meetup_transition_retry", {
          latencyMs: Date.now() - started,
        });
        throw error;
      }
      const current = await snapshot.ref.get();
      const createdAt = current.data()?.createdAt;
      await snapshot.ref.update(createdAt instanceof Timestamp ?
        terminalTransitionFields(createdAt, "failed", undefined, error) :
        {
          status: "failed",
          errorCode: error.code,
          processedAt: FieldValue.serverTimestamp(),
          purgeAt: Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
        });
      logger.warn("live_meetup_transition_terminal", {
        status: "failed",
        code: error.code,
        latencyMs: Date.now() - started,
      });
    }
  },
);
