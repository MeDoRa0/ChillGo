import {strict as assert} from "assert";
import {safeLiveMeetupError} from "../../src/live_meetup/command_handler";
import {LiveMeetupCommandError} from "../../src/live_meetup/command_schema";

describe("live meetup command handler", () => {
  it("preserves safe known failures and scrubs unknown messages", () => {
    const known = new LiveMeetupCommandError(
      "session_transferred",
      "Sharing moved to another device.",
    );
    assert.equal(safeLiveMeetupError(known), known);
    const safe = safeLiveMeetupError(new Error("30.123,31.456 secret-token"));
    assert.equal(safe.code, "internal_error");
    assert.equal(safe.message.includes("30.123"), false);
    assert.equal(safe.message.includes("secret-token"), false);
  });
});
