import {Timestamp} from "firebase-admin/firestore";

export const chatErrorCodes = [
  "unauthenticated",
  "permission_denied",
  "not_found",
  "invalid_command",
  "invalid_message",
  "invalid_outing_state",
  "outing_deleting",
  "rate_limited",
  "message_identity_conflict",
  "already_processed",
  "internal_error",
] as const;

export type ChatErrorCode = typeof chatErrorCodes[number];

export interface SendMessageCommand {
  type: "send_message";
  outingId: string;
  crewId: string;
  requestedByUserId: string;
  clientMessageId: string;
  payload: {text: string};
  status: "pending";
  createdAt: Timestamp;
}

const COMMAND_KEYS = [
  "type", "outingId", "crewId", "requestedByUserId",
  "clientMessageId", "payload", "status", "createdAt",
].sort();

export function trimUnicodeWhitespace(value: string): string {
  return value.replace(/^\s+|\s+$/gu, "");
}

export function validateMessageText(value: unknown): string {
  if (typeof value !== "string") {
    throw new ChatCommandError("invalid_message", "Enter a text message.");
  }
  const text = trimUnicodeWhitespace(value);
  const scalarLength = Array.from(text).length;
  if (scalarLength < 1 || scalarLength > 2000) {
    throw new ChatCommandError(
      "invalid_message",
      "Messages must contain 1 to 2,000 characters.",
    );
  }
  return text;
}

export function parseChatCommand(raw: unknown): SendMessageCommand {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    throw new ChatCommandError("invalid_command", "Invalid chat command.");
  }
  const value = raw as Record<string, unknown>;
  if (Object.keys(value).sort().join("|") !== COMMAND_KEYS.join("|")) {
    throw new ChatCommandError("invalid_command", "Invalid chat command shape.");
  }
  for (const field of ["outingId", "crewId", "requestedByUserId", "clientMessageId"]) {
    const candidate = value[field];
    if (typeof candidate !== "string" || !candidate.trim()) {
      throw new ChatCommandError("invalid_command", "Invalid chat command identity.");
    }
  }
  if (value.type !== "send_message" || value.status !== "pending" ||
      !(value.createdAt instanceof Timestamp)) {
    throw new ChatCommandError("invalid_command", "Invalid chat command state.");
  }
  if (!value.payload || typeof value.payload !== "object" || Array.isArray(value.payload) ||
      Object.keys(value.payload).join("|") !== "text") {
    throw new ChatCommandError("invalid_command", "Invalid chat payload.");
  }
  const text = validateMessageText((value.payload as Record<string, unknown>).text);
  return {...value, payload: {text}} as SendMessageCommand;
}

export class ChatCommandError extends Error {
  constructor(
    public readonly code: ChatErrorCode,
    message: string,
    public readonly retryAt?: Timestamp,
  ) {
    super(message);
  }
}
