import {strict as assert} from "assert";
import {claimDecision} from "../../src/chat/chat_transactions";
import {safeChatError} from "../../src/chat/command_handler";
import {ChatCommandError} from "../../src/chat/command_schema";

describe("chat command handler convergence", () => {
  it("lets a duplicate delivery with the same event retain its claim", () => {
    assert.equal(
      claimDecision({status: "processing", processingEventId: "event-1"}, "event-1"),
      "claim",
    );
  });

  it("does not steal processing ownership from another event", () => {
    assert.equal(
      claimDecision({status: "processing", processingEventId: "event-1"}, "event-2"),
      "owned_by_other",
    );
  });

  it("treats both terminal states and missing commands as no-ops", () => {
    assert.equal(claimDecision({status: "succeeded"}, "event"), "terminal");
    assert.equal(claimDecision({status: "failed"}, "event"), "terminal");
    assert.equal(claimDecision(undefined, "event"), "terminal");
  });

  it("sanitizes unknown failures without exposing their message", () => {
    const safe = safeChatError(new Error("private message contents"));
    assert.equal(safe.code, "internal_error");
    assert.equal(safe.message, "Chat service unavailable.");
    const known = new ChatCommandError("rate_limited", "Too many messages.");
    assert.equal(safeChatError(known), known);
  });
});
