import {FieldValue, Timestamp} from "firebase-admin/firestore";

export const liveMeetupErrorCodes = [
  "unauthenticated",
  "permission_denied",
  "not_found",
  "invalid_command",
  "invalid_status",
  "invalid_location",
  "stale_location",
  "invalid_outing_state",
  "attendance_required",
  "outing_deleting",
  "transfer_required",
  "session_transferred",
  "session_stopped",
  "already_processed",
  "internal_error",
] as const;

export type LiveMeetupErrorCode = typeof liveMeetupErrorCodes[number];
export type LiveMeetupCommandType =
  "set_status" |
  "start_sharing" |
  "publish_location" |
  "stop_sharing" |
  "set_meetup_point";

interface CommonCommand {
  type: LiveMeetupCommandType;
  outingId: string;
  crewId: string;
  requestedByUserId: string;
  status: "pending";
  createdAt: Timestamp;
  purgeAt: Timestamp;
}

export interface SetStatusCommand extends CommonCommand {
  type: "set_status";
  payload: {value: "getting_ready" | "on_my_way" | "arrived"};
}
export interface StartSharingCommand extends CommonCommand {
  type: "start_sharing";
  payload: {
    sessionId: string;
    sessionToken: string;
    deviceSessionId: string;
    transferExisting: boolean;
  };
}
export interface PublishLocationCommand extends CommonCommand {
  type: "publish_location";
  payload: {
    sessionId: string;
    sessionToken: string;
    latitude: number;
    longitude: number;
    accuracyMeters: number;
    sampleAgeMillis: number;
  };
}
export interface StopSharingCommand extends CommonCommand {
  type: "stop_sharing";
  payload: {sessionId: string; sessionToken: string};
}
export interface SetMeetupPointCommand extends CommonCommand {
  type: "set_meetup_point";
  payload: {latitude: number; longitude: number; locationTextSnapshot: string};
}
export type LiveMeetupCommand =
  SetStatusCommand |
  StartSharingCommand |
  PublishLocationCommand |
  StopSharingCommand |
  SetMeetupPointCommand;

const COMMON_KEYS = [
  "type", "outingId", "crewId", "requestedByUserId",
  "payload", "status", "createdAt", "purgeAt",
].sort();
const HOUR_MS = 60 * 60 * 1000;
const LOCATION_PENDING_MS = 2 * 60 * 1000;
const TERMINAL_MS = 10 * 60 * 1000;

export function parseLiveMeetupCommand(raw: unknown): LiveMeetupCommand {
  const value = record(raw, "Invalid live meetup command.");
  exactKeys(value, COMMON_KEYS);
  for (const key of ["outingId", "crewId", "requestedByUserId"]) {
    nonEmptyString(value[key], key);
  }
  if (value.status !== "pending" ||
      !(value.createdAt instanceof Timestamp) ||
      !(value.purgeAt instanceof Timestamp)) {
    throw invalid("Invalid command lifecycle.");
  }
  const type = value.type;
  if (!["set_status", "start_sharing", "publish_location", "stop_sharing",
    "set_meetup_point"].includes(String(type))) {
    throw invalid("Invalid command type.");
  }
  const payload = record(value.payload, "Invalid command payload.");
  switch (type as LiveMeetupCommandType) {
  case "set_status":
    exactKeys(payload, ["value"]);
    if (!["getting_ready", "on_my_way", "arrived"].includes(String(payload.value))) {
      throw new LiveMeetupCommandError("invalid_status", "Choose a valid status.");
    }
    break;
  case "start_sharing":
    exactKeys(payload, ["sessionId", "sessionToken", "deviceSessionId", "transferExisting"]);
    nonEmptyString(payload.sessionId, "sessionId");
    nonEmptyString(payload.sessionToken, "sessionToken");
    nonEmptyString(payload.deviceSessionId, "deviceSessionId");
    if (typeof payload.transferExisting !== "boolean") throw invalid("Invalid transfer flag.");
    break;
  case "publish_location":
    exactKeys(payload, [
      "sessionId", "sessionToken", "latitude", "longitude",
      "accuracyMeters", "sampleAgeMillis",
    ]);
    nonEmptyString(payload.sessionId, "sessionId");
    nonEmptyString(payload.sessionToken, "sessionToken");
    boundedNumber(payload.latitude, -90, 90, "latitude");
    boundedNumber(payload.longitude, -180, 180, "longitude");
    boundedNumber(payload.accuracyMeters, 0, 5000, "accuracyMeters");
    boundedNumber(payload.sampleAgeMillis, 0, 30000, "sampleAgeMillis");
    break;
  case "stop_sharing":
    exactKeys(payload, ["sessionId", "sessionToken"]);
    nonEmptyString(payload.sessionId, "sessionId");
    nonEmptyString(payload.sessionToken, "sessionToken");
    break;
  case "set_meetup_point":
    exactKeys(payload, ["latitude", "longitude", "locationTextSnapshot"]);
    boundedNumber(payload.latitude, -90, 90, "latitude");
    boundedNumber(payload.longitude, -180, 180, "longitude");
    nonEmptyString(payload.locationTextSnapshot, "locationTextSnapshot");
    break;
  }
  const pendingMs = type === "publish_location" ? LOCATION_PENDING_MS : HOUR_MS;
  const purgeDrift = Math.abs(
    value.purgeAt.toMillis() - value.createdAt.toMillis() - pendingMs,
  );
  if (purgeDrift > 60 * 1000) {
    throw invalid("Invalid purge deadline.");
  }
  return value as unknown as LiveMeetupCommand;
}

export function terminalCommandFields(
  createdAt: Timestamp,
  status: "succeeded" | "superseded" | "failed",
  result?: Record<string, unknown>,
  error?: LiveMeetupCommandError,
): Record<string, unknown> & {status: string; purgeAt: Timestamp} {
  return {
    status,
    ...(result ? {result} : {}),
    ...(error ? {errorCode: error.code, errorMessage: error.message} : {}),
    processedAt: FieldValue.serverTimestamp(),
    purgeAt: Timestamp.fromMillis(createdAt.toMillis() + TERMINAL_MS),
    payload: FieldValue.delete(),
    processingEventId: FieldValue.delete(),
  };
}

function record(value: unknown, message: string): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw invalid(message);
  return value as Record<string, unknown>;
}
function exactKeys(value: Record<string, unknown>, keys: string[]): void {
  if (Object.keys(value).sort().join("|") !== [...keys].sort().join("|")) {
    throw invalid("Invalid command shape.");
  }
}
function nonEmptyString(value: unknown, field: string): asserts value is string {
  if (typeof value !== "string" || !value.trim() || value.length > 500) {
    throw invalid(`Invalid ${field}.`);
  }
}
function boundedNumber(value: unknown, min: number, max: number, field: string): void {
  if (typeof value !== "number" || !Number.isFinite(value) || value < min || value > max) {
    throw new LiveMeetupCommandError("invalid_location", `Invalid ${field}.`);
  }
}
function invalid(message: string): LiveMeetupCommandError {
  return new LiveMeetupCommandError("invalid_command", message);
}

export class LiveMeetupCommandError extends Error {
  constructor(public readonly code: LiveMeetupErrorCode, message: string) {
    super(message);
  }
}
