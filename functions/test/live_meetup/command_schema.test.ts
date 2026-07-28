import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  LiveMeetupCommandError,
  parseLiveMeetupCommand,
  terminalCommandFields,
} from "../../src/live_meetup/command_schema";
import {
  claimDecision,
  compareOperationTuple,
} from "../../src/live_meetup/live_meetup_transactions";

describe("live meetup command schema", () => {
  const createdAt = Timestamp.fromMillis(1_700_000_000_000);
  const base = {
    outingId: "outing-1",
    crewId: "crew-1",
    requestedByUserId: "alice",
    status: "pending",
    createdAt,
    purgeAt: Timestamp.fromMillis(createdAt.toMillis() + 60 * 60 * 1000),
  };

  it("accepts each exact command envelope", () => {
    const commands = [
      {type: "set_status", payload: {value: "arrived"}},
      {
        type: "start_sharing",
        payload: {
          sessionId: "session",
          sessionToken: "token",
          deviceSessionId: "device",
          transferExisting: false,
        },
      },
      {
        type: "publish_location",
        payload: {
          sessionId: "session",
          sessionToken: "token",
          latitude: 30,
          longitude: 31,
          accuracyMeters: 5,
          sampleAgeMillis: 100,
        },
        purgeAt: Timestamp.fromMillis(createdAt.toMillis() + 2 * 60 * 1000),
      },
      {type: "stop_sharing", payload: {sessionId: "session", sessionToken: "token"}},
      {
        type: "set_meetup_point",
        payload: {latitude: 30, longitude: 31, locationTextSnapshot: "Cafe"},
      },
    ];
    for (const command of commands) {
      assert.equal(parseLiveMeetupCommand({...base, ...command}).type, command.type);
    }
  });

  it("rejects unknown keys, cleanup state, and invalid bounds", () => {
    assert.throws(
      () => parseLiveMeetupCommand({
        ...base,
        type: "set_status",
        payload: {value: "arrived"},
        debug: true,
      }),
      LiveMeetupCommandError,
    );
    assert.throws(
      () => parseLiveMeetupCommand({
        ...base,
        type: "publish_location",
        payload: {
          sessionId: "s",
          sessionToken: "t",
          latitude: 91,
          longitude: 0,
          accuracyMeters: 0,
          sampleAgeMillis: 0,
        },
      }),
      LiveMeetupCommandError,
    );
  });

  it("scrubs payload and shortens terminal purge deadline", () => {
    const fields = terminalCommandFields(createdAt, "succeeded", {
      acceptedAt: createdAt,
    });
    assert.equal(fields.status, "succeeded");
    assert.equal(fields.purgeAt.toMillis(), createdAt.toMillis() + 10 * 60 * 1000);
    assert.ok("payload" in fields);
    assert.equal(JSON.stringify(fields).includes("sessionToken"), false);
  });

  it("orders same-time operations by command id and claims idempotently", () => {
    assert.equal(compareOperationTuple(createdAt, "b", createdAt, "a"), 1);
    assert.equal(
      claimDecision({status: "processing", processingEventId: "event"}, "event"),
      "claim",
    );
    assert.equal(claimDecision({status: "succeeded"}, "event"), "terminal");
  });
});
