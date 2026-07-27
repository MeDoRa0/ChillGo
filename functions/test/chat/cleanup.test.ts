import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  CHAT_CLEANUP_BATCH_SIZE,
  CHAT_CLEANUP_MAX_BATCHES,
  cleanupTargets,
  safeErrorCode,
} from "../../src/chat/cleanup";

describe("chat cleanup plan", () => {
  it("covers every ephemeral record class with bounded work", () => {
    const targets = cleanupTargets(Timestamp.fromMillis(1_000_000));
    assert.deepEqual(
      new Set(targets.map((target) => target.collection)),
      new Set(["chat_messages", "chat_commands", "chat_read_states", "chat_rate_limits", "chat_time_probes"]),
    );
    assert.ok(CHAT_CLEANUP_BATCH_SIZE < 500);
    assert.ok(CHAT_CLEANUP_MAX_BATCHES <= 5);
  });

  it("uses 24-hour abandoned command and 10-minute stale probe cutoffs", () => {
    const now = Timestamp.fromMillis(100_000_000);
    const targets = cleanupTargets(now);
    const abandoned = targets.find((target) => target.collection === "chat_commands" && target.field === "createdAt")!;
    const probe = targets.find((target) => target.collection === "chat_time_probes")!;
    assert.equal(now.toMillis() - abandoned.cutoff.toMillis(), 24 * 60 * 60 * 1000);
    assert.equal(now.toMillis() - probe.cutoff.toMillis(), 10 * 60 * 1000);
  });

  it("sanitizes cleanup failures to codes without text", () => {
    assert.equal(safeErrorCode({code: "permission-denied", message: "private text"}), "permission-denied");
    assert.equal(safeErrorCode(new Error("private text")), "unknown");
  });
});
