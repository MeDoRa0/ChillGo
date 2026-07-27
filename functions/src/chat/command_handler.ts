import {initializeApp, getApps} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {ChatTransactions} from "./chat_transactions";
import {ChatCommandError, parseChatCommand} from "./command_schema";

if (!getApps().length) initializeApp();

export function safeChatError(error: unknown): ChatCommandError {
  return error instanceof ChatCommandError ?
    error : new ChatCommandError("internal_error", "Chat service unavailable.");
}

export const chatCommandCreated = onDocumentCreated(
  "chat_commands/{commandId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const started = Date.now();
    try {
      const command = parseChatCommand(snapshot.data());
      const result = await new ChatTransactions(getFirestore())
        .process(snapshot.id, event.id, command);
      if (result) {
        logger.info("chat_command_terminal", {
          status: "succeeded",
          latencyMs: Date.now() - started,
          alreadyAccepted: result.alreadyAccepted === true,
        });
      }
    } catch (error) {
      const safe = safeChatError(error);
      const current = await snapshot.ref.get();
      if (["succeeded", "failed"].includes(current.data()?.status)) return;
      const createdAt = current.data()?.createdAt;
      const deleteAt = createdAt instanceof Timestamp ?
        Timestamp.fromMillis(createdAt.toMillis() + 24 * 60 * 60 * 1000) :
        Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
      await snapshot.ref.update({
        status: "failed",
        errorCode: safe.code,
        errorMessage: safe.message,
        ...(safe.retryAt ? {retryAt: safe.retryAt} : {}),
        processedAt: FieldValue.serverTimestamp(),
        deleteAt,
        payload: FieldValue.delete(),
        processingEventId: FieldValue.delete(),
      });
      logger.warn("chat_command_terminal", {
        status: "failed",
        code: safe.code,
        latencyMs: Date.now() - started,
        rateLimited: safe.code === "rate_limited",
        permissionDenied: safe.code === "permission_denied",
      });
    }
  },
);
