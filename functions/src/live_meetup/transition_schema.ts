import {FieldValue, Timestamp} from "firebase-admin/firestore";

export type TransitionType =
  "end_outing" |
  "change_attendance" |
  "remove_participant" |
  "remove_membership" |
  "delete_crew";
export type TransitionPhase =
  "authorize" | "deny_access" | "delete_presence" | "verify_empty" | "finalize";
export type TransitionErrorCode =
  "permission_denied" | "not_found" | "invalid_transition" | "internal_error";

interface CommonTransition {
  type: TransitionType;
  crewId: string;
  requestedByUserId: string;
  status: "pending";
  createdAt: Timestamp;
  purgeAt: Timestamp;
}
export interface EndOutingTransition extends CommonTransition {
  type: "end_outing";
  outingId: string;
  targetOutingStatus: "completed" | "cancelled" | "archived";
}
export interface ChangeAttendanceTransition extends CommonTransition {
  type: "change_attendance";
  outingId: string;
  targetUserId: string;
  targetAttendanceStatus: "declined";
}
export interface RemoveParticipantTransition extends CommonTransition {
  type: "remove_participant";
  outingId: string;
  targetUserId: string;
}
export interface RemoveMembershipTransition extends CommonTransition {
  type: "remove_membership";
  targetUserId: string;
}
export interface DeleteCrewTransition extends CommonTransition {
  type: "delete_crew";
}
export type LiveMeetupTransition =
  EndOutingTransition |
  ChangeAttendanceTransition |
  RemoveParticipantTransition |
  RemoveMembershipTransition |
  DeleteCrewTransition;

const COMMON = ["type", "crewId", "requestedByUserId", "status", "createdAt", "purgeAt"];
const PENDING_MS = 60 * 60 * 1000;
const TERMINAL_MS = 10 * 60 * 1000;

export function parseLiveMeetupTransition(raw: unknown): LiveMeetupTransition {
  const value = record(raw);
  const type = value.type;
  const specific = type === "end_outing" ?
    ["outingId", "targetOutingStatus"] :
    type === "change_attendance" ?
      ["outingId", "targetUserId", "targetAttendanceStatus"] :
      type === "remove_participant" ?
        ["outingId", "targetUserId"] :
        type === "remove_membership" ? ["targetUserId"] :
          type === "delete_crew" ? [] : null;
  if (!specific) throw invalid("Invalid transition type.");
  exactKeys(value, [...COMMON, ...specific]);
  for (const key of ["crewId", "requestedByUserId", ...specific.filter((key) =>
    !key.startsWith("targetOuting") && !key.startsWith("targetAttendance"))]) {
    nonEmptyString(value[key], key);
  }
  if (value.status !== "pending" ||
      !(value.createdAt instanceof Timestamp) ||
      !(value.purgeAt instanceof Timestamp) ||
      Math.abs(value.purgeAt.toMillis() - value.createdAt.toMillis() - PENDING_MS) > 60000) {
    throw invalid("Invalid transition lifecycle.");
  }
  if (type === "end_outing" &&
      !["completed", "cancelled", "archived"].includes(String(value.targetOutingStatus))) {
    throw invalid("Invalid terminal outing status.");
  }
  if (type === "change_attendance" &&
      (value.targetUserId !== value.requestedByUserId ||
       value.targetAttendanceStatus !== "declined")) {
    throw invalid("Attendance changes must be self-targeted declines.");
  }
  return value as unknown as LiveMeetupTransition;
}

export function terminalTransitionFields(
  createdAt: Timestamp,
  status: "succeeded" | "failed",
  result?: Record<string, unknown>,
  error?: TransitionError,
): Record<string, unknown> {
  return {
    status,
    ...(result ? {result} : {}),
    ...(error ? {errorCode: error.code} : {}),
    processedAt: FieldValue.serverTimestamp(),
    purgeAt: Timestamp.fromMillis(createdAt.toMillis() + TERMINAL_MS),
    phase: FieldValue.delete(),
    cursor: FieldValue.delete(),
    processingEventId: FieldValue.delete(),
    leaseExpiresAt: FieldValue.delete(),
    targetUserId: FieldValue.delete(),
    targetOutingStatus: FieldValue.delete(),
    targetAttendanceStatus: FieldValue.delete(),
  };
}

function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw invalid("Invalid transition.");
  }
  return value as Record<string, unknown>;
}
function exactKeys(value: Record<string, unknown>, keys: string[]): void {
  if (Object.keys(value).sort().join("|") !== [...keys].sort().join("|")) {
    throw invalid("Invalid transition shape.");
  }
}
function nonEmptyString(value: unknown, field: string): void {
  if (typeof value !== "string" || !value.trim() || value.length > 500) {
    throw invalid(`Invalid ${field}.`);
  }
}
function invalid(message: string): TransitionError {
  return new TransitionError("invalid_transition", message);
}
export class TransitionError extends Error {
  constructor(public readonly code: TransitionErrorCode, message: string) {
    super(message);
  }
}
