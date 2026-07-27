import {
  FieldValue,
  Firestore,
  Timestamp,
} from "firebase-admin/firestore";
import {
  ChatCommandError,
  SendMessageCommand,
} from "./command_schema";

const MESSAGE_LIFETIME_MS = 24 * 60 * 60 * 1000;
const RATE_WINDOW_MS = 60 * 1000;
const RATE_LIMIT = 30;

export function pruneRateWindow(values: Timestamp[], acceptedAt: Timestamp): Timestamp[] {
  const boundary = acceptedAt.toMillis() - RATE_WINDOW_MS;
  return values
    .filter((value) => value.toMillis() > boundary)
    .sort((left, right) => left.toMillis() - right.toMillis());
}

export function deterministicMessageId(command: SendMessageCommand): string {
  return `${command.outingId}_${command.clientMessageId}`;
}

export function claimDecision(
  data: FirebaseFirestore.DocumentData | undefined,
  eventId: string,
): "claim" | "terminal" | "owned_by_other" {
  if (!data || ["succeeded", "failed"].includes(data.status)) return "terminal";
  if (data.status === "processing" && data.processingEventId !== eventId) {
    return "owned_by_other";
  }
  return "claim";
}

export class ChatTransactions {
  constructor(
    private readonly db: Firestore,
    private readonly trustedNow: () => Timestamp = Timestamp.now,
  ) {}

  async process(
    commandId: string,
    eventId: string,
    command: SendMessageCommand,
  ): Promise<Record<string, unknown> | null> {
    const commandRef = this.db.collection("chat_commands").doc(commandId);
    const claimed = await this.db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(commandRef);
      const data = snapshot.data();
      if (claimDecision(data, eventId) !== "claim") return false;
      transaction.update(commandRef, {status: "processing", processingEventId: eventId});
      return true;
    });
    if (!claimed) return null;
    return this.accept(commandRef, command);
  }

  private async accept(
    commandRef: FirebaseFirestore.DocumentReference,
    command: SendMessageCommand,
  ): Promise<Record<string, unknown>> {
    const outingRef = this.db.collection("outings").doc(command.outingId);
    const membershipRef = this.db.collection("crew_memberships")
      .doc(`${command.crewId}_${command.requestedByUserId}`);
    const participantRef = this.db.collection("outing_participants")
      .doc(`${command.outingId}_${command.requestedByUserId}`);
    const userRef = this.db.collection("users").doc(command.requestedByUserId);
    const messageRef = this.db.collection("chat_messages")
      .doc(deterministicMessageId(command));
    const bucketRef = this.db.collection("chat_rate_limits")
      .doc(`${command.outingId}_${command.requestedByUserId}`);
    const acceptedAt = this.trustedNow();
    const expiresAt = Timestamp.fromMillis(acceptedAt.toMillis() + MESSAGE_LIFETIME_MS);
    const deleteAt = Timestamp.fromMillis(command.createdAt.toMillis() + MESSAGE_LIFETIME_MS);

    return this.db.runTransaction(async (transaction) => {
      const [outing, membership, participant, user, existing, bucket] = await Promise.all([
        transaction.get(outingRef),
        transaction.get(membershipRef),
        transaction.get(participantRef),
        transaction.get(userRef),
        transaction.get(messageRef),
        transaction.get(bucketRef),
      ]);
      if (!outing.exists) throw new ChatCommandError("not_found", "Chat is unavailable.");
      const outingData = outing.data()!;
      if (outingData.deletionPending === true) {
        throw new ChatCommandError("outing_deleting", "Chat is unavailable.");
      }
      if (outingData.crewId !== command.crewId || !membership.exists || !participant.exists) {
        throw new ChatCommandError("permission_denied", "Chat is unavailable.");
      }
      if (!["draft", "planning", "confirmed", "meeting"].includes(outingData.status)) {
        throw new ChatCommandError("invalid_outing_state", "This chat is read-only.");
      }

      if (existing.exists) {
        const data = existing.data()!;
        if (data.outingId !== command.outingId ||
            data.authorUserId !== command.requestedByUserId ||
            data.text !== command.payload.text) {
          throw new ChatCommandError(
            "message_identity_conflict",
            "This message cannot be retried with the same identity.",
          );
        }
        const result = {
          messageId: existing.id,
          acceptedAt: data.acceptedAt,
          expiresAt: data.expiresAt,
          alreadyAccepted: true,
        };
        transaction.update(commandRef, terminalSuccess(result, deleteAt));
        return result;
      }

      const retained = pruneRateWindow(
        ((bucket.data()?.acceptedAt ?? []) as unknown[])
          .filter((value): value is Timestamp => value instanceof Timestamp),
        acceptedAt,
      );
      if (retained.length >= RATE_LIMIT) {
        throw new ChatCommandError(
          "rate_limited",
          "Too many messages.",
          Timestamp.fromMillis(retained[0].toMillis() + RATE_WINDOW_MS),
        );
      }
      retained.push(acceptedAt);
      const participantData = participant.data()!;
      const userData = user.data() ?? {};
      transaction.create(messageRef, {
        outingId: command.outingId,
        crewId: command.crewId,
        clientMessageId: command.clientMessageId,
        authorUserId: command.requestedByUserId,
        authorUsername: participantData.username ?? userData.username ?? "participant",
        authorDisplayName: participantData.displayName ?? userData.displayName ?? "Participant",
        authorAvatarUrl: participantData.avatarUrl ?? userData.avatarUrl ?? null,
        text: command.payload.text,
        acceptedAt,
        expiresAt,
      });
      transaction.set(bucketRef, {
        outingId: command.outingId,
        crewId: command.crewId,
        userId: command.requestedByUserId,
        acceptedAt: retained,
        updatedAt: acceptedAt,
        purgeAfter: Timestamp.fromMillis(acceptedAt.toMillis() + RATE_WINDOW_MS),
      });
      const result = {
        messageId: messageRef.id,
        acceptedAt,
        expiresAt,
        alreadyAccepted: false,
      };
      transaction.update(commandRef, terminalSuccess(result, deleteAt));
      return result;
    });
  }
}

function terminalSuccess(
  result: Record<string, unknown>,
  deleteAt: Timestamp,
): Record<string, unknown> {
  return {
    status: "succeeded",
    result,
    processedAt: FieldValue.serverTimestamp(),
    deleteAt,
    payload: FieldValue.delete(),
    processingEventId: FieldValue.delete(),
  };
}
