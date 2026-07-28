import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  parseLiveMeetupTransition,
  terminalTransitionFields,
  TransitionError,
} from "../../src/live_meetup/transition_schema";

const now = Timestamp.fromMillis(1000);
const purgeAt = Timestamp.fromMillis(1000 + 60 * 60 * 1000);
const common = {
  crewId: "crew",
  requestedByUserId: "user",
  status: "pending",
  createdAt: now,
  purgeAt,
} as const;

describe("live meetup transition schema", () => {
  it("accepts exact type-specific terminal envelopes", () => {
    for (const targetOutingStatus of ["completed", "cancelled", "archived"]) {
      const parsed = parseLiveMeetupTransition({
        ...common,
        type: "end_outing",
        outingId: "outing",
        targetOutingStatus,
      });
      assert.equal(parsed.type, "end_outing");
    }
    assert.equal(parseLiveMeetupTransition({
      ...common,
      type: "remove_participant",
      outingId: "outing",
      targetUserId: "other",
    }).type, "remove_participant");
    assert.equal(parseLiveMeetupTransition({
      ...common,
      type: "remove_membership",
      targetUserId: "other",
    }).type, "remove_membership");
    assert.equal(parseLiveMeetupTransition({
      ...common,
      type: "delete_crew",
    }).type, "delete_crew");
  });

  it("requires self-targeted accepted-to-declined shape", () => {
    const parsed = parseLiveMeetupTransition({
      ...common,
      type: "change_attendance",
      outingId: "outing",
      targetUserId: "user",
      targetAttendanceStatus: "declined",
    });
    assert.equal(parsed.type, "change_attendance");
    for (const forged of [
      {targetUserId: "other", targetAttendanceStatus: "declined"},
      {targetUserId: "user", targetAttendanceStatus: "accepted"},
    ]) {
      assert.throws(() => parseLiveMeetupTransition({
        ...common,
        type: "change_attendance",
        outingId: "outing",
        ...forged,
      }), TransitionError);
    }
  });

  it("rejects unknown fields and invalid pending retention", () => {
    assert.throws(() => parseLiveMeetupTransition({
      ...common,
      type: "delete_crew",
      injected: true,
    }), TransitionError);
    assert.throws(() => parseLiveMeetupTransition({
      ...common,
      type: "delete_crew",
      purgeAt: Timestamp.fromMillis(purgeAt.toMillis() + 120000),
    }), TransitionError);
  });

  it("scrubs targets, cursor, phase, and lease at terminal state", () => {
    const fields = terminalTransitionFields(
      now,
      "failed",
      undefined,
      new TransitionError("permission_denied", "private"),
    );
    assert.equal(fields.status, "failed");
    assert.equal(fields.errorCode, "permission_denied");
    for (const key of [
      "phase", "cursor", "processingEventId", "leaseExpiresAt",
      "targetUserId", "targetOutingStatus", "targetAttendanceStatus",
    ]) assert.ok(key in fields);
    assert.ok(!("errorMessage" in fields));
  });
});
