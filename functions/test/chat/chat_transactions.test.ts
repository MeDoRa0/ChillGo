import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  deterministicMessageId,
  pruneRateWindow,
} from "../../src/chat/chat_transactions";
import {SendMessageCommand} from "../../src/chat/command_schema";

describe("chat acceptance transaction helpers", () => {
  it("uses a deterministic message identity across retry attempts", () => {
    const command = {
      outingId: "outing-1",
      clientMessageId: "client-1",
    } as SendMessageCommand;
    assert.equal(deterministicMessageId(command), "outing-1_client-1");
  });

  it("keeps only timestamps strictly inside the rolling minute", () => {
    const now = Timestamp.fromMillis(120_000);
    const result = pruneRateWindow([
      Timestamp.fromMillis(59_999),
      Timestamp.fromMillis(60_000),
      Timestamp.fromMillis(60_001),
      Timestamp.fromMillis(119_000),
    ], now);
    assert.deepEqual(result.map((value) => value.toMillis()), [60_001, 119_000]);
  });

  it("returns the first retained timestamp as the retry boundary", () => {
    const now = Timestamp.fromMillis(100_000);
    const retained = pruneRateWindow(
      Array.from({length: 30}, (_, index) => Timestamp.fromMillis(40_001 + index)),
      now,
    );
    assert.equal(retained.length, 30);
    assert.equal(retained[0].toMillis() + 60_000, 100_001);
  });
});
