import {initializeApp, getApps} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {
  LiveMeetupCommandError,
  parseLiveMeetupCommand,
  terminalCommandFields,
} from "./command_schema";
import {LiveMeetupTransactions} from "./live_meetup_transactions";

if (!getApps().length) initializeApp();

export function safeLiveMeetupError(error: unknown): LiveMeetupCommandError {
  return error instanceof LiveMeetupCommandError ?
    error :
    new LiveMeetupCommandError("internal_error", "Live Meetup is unavailable.");
}

export const liveMeetupCommandCreated = onDocumentCreated(
  "live_meetup_commands/{commandId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const started = Date.now();
    try {
      const command = parseLiveMeetupCommand(snapshot.data());
      const result = await new LiveMeetupTransactions(getFirestore())
        .process(snapshot.id, event.id, command);
      if (result) {
        logger.info("live_meetup_command_terminal", {
          type: command.type,
          status: result.superseded === true ? "superseded" : "succeeded",
          latencyMs: Date.now() - started,
        });
      }
    } catch (error) {
      const safe = safeLiveMeetupError(error);
      const current = await snapshot.ref.get();
      if (["succeeded", "superseded", "failed"].includes(current.data()?.status)) return;
      const createdAt = current.data()?.createdAt;
      const fields = createdAt instanceof Timestamp ?
        terminalCommandFields(createdAt, "failed", undefined, safe) :
        {
          status: "failed",
          errorCode: safe.code,
          errorMessage: safe.message,
          processedAt: FieldValue.serverTimestamp(),
          payload: FieldValue.delete(),
          processingEventId: FieldValue.delete(),
          purgeAt: Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
        };
      await snapshot.ref.update(fields);
      logger.warn("live_meetup_command_terminal", {
        status: "failed",
        code: safe.code,
        latencyMs: Date.now() - started,
      });
    }
  },
);
