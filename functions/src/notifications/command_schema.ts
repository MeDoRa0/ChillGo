import {FieldValue, Timestamp} from "firebase-admin/firestore";

export type NotificationCommandType =
  "mark_read" | "open" | "register_device" | "unregister_device";

export interface NotificationCommand {
  type: NotificationCommandType;
  requestedByUserId: string;
  payload: Record<string, unknown>;
  status: "pending";
  createdAt: Timestamp;
}

export type NotificationErrorCode =
  "invalid_command" | "unauthenticated" | "not_found" | "unavailable" |
  "expired" | "permission_denied" | "device_limit" | "internal_error";

export class NotificationCommandError extends Error {
  constructor(
    public readonly code: NotificationErrorCode,
    message: string,
  ) {
    super(message);
  }
}

export function parseNotificationCommand(raw: unknown): NotificationCommand {
  const value = record(raw, "Invalid notification command.");
  exactKeys(value, [
    "type", "requestedByUserId", "payload", "status", "createdAt",
  ]);
  const type = value.type;
  if (!["mark_read", "open", "register_device", "unregister_device"].includes(
    String(type),
  ) || value.status !== "pending" || !(value.createdAt instanceof Timestamp)) {
    throw invalid();
  }
  const requestedByUserId = boundedString(value.requestedByUserId, 1, 128);
  const payload = record(value.payload, "Invalid command payload.");
  if (type === "mark_read" || type === "open") {
    exactKeys(payload, ["notificationId"]);
    boundedString(payload.notificationId, 1, 200);
  } else if (type === "register_device") {
    exactKeys(payload, [
      "installationId", "token", "platform", "permissionState",
    ]);
    boundedString(payload.installationId, 16, 128);
    boundedString(payload.token, 16, 4096);
    if (!["android", "ios"].includes(String(payload.platform)) ||
        payload.permissionState !== "granted") {
      throw invalid();
    }
  } else {
    exactKeys(payload, ["installationId"]);
    boundedString(payload.installationId, 16, 128);
  }
  return {
    type: type as NotificationCommandType,
    requestedByUserId,
    payload,
    status: "pending",
    createdAt: value.createdAt,
  };
}

export function terminalNotificationCommandFields(
  status: "succeeded" | "failed",
  result?: Record<string, unknown>,
  error?: NotificationCommandError,
): Record<string, unknown> {
  const now = Timestamp.now();
  return {
    status,
    processedAt: now,
    purgeAt: Timestamp.fromMillis(now.toMillis() + 10 * 60 * 1000),
    payload: FieldValue.delete(),
    processingEventId: FieldValue.delete(),
    ...(result ? {result} : {result: FieldValue.delete()}),
    ...(error ? {errorCode: error.code} : {errorCode: FieldValue.delete()}),
  };
}

function exactKeys(value: Record<string, unknown>, expected: string[]): void {
  const actual = Object.keys(value).sort();
  const wanted = [...expected].sort();
  if (actual.length !== wanted.length ||
      actual.some((key, index) => key !== wanted[index])) {
    throw invalid();
  }
}

function boundedString(value: unknown, min: number, max: number): string {
  if (typeof value !== "string" || value.length < min || value.length > max) {
    throw invalid();
  }
  return value;
}

function record(value: unknown, message: string): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new NotificationCommandError("invalid_command", message);
  }
  return value as Record<string, unknown>;
}

function invalid(): NotificationCommandError {
  return new NotificationCommandError("invalid_command", "Invalid notification command.");
}
