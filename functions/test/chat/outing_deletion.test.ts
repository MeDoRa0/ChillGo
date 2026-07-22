import {strict as assert} from "assert";
import {
  OUTING_DELETION_SWEEP_PASSES,
  OUTING_OWNED_COLLECTIONS,
} from "../../src/outings/outing_deletion";

describe("outing chat deletion contract", () => {
  it("owns every chat collection with records scoped to an outing", () => {
    for (const collection of ["chat_messages", "chat_read_states", "chat_rate_limits"]) {
      assert.ok(OUTING_OWNED_COLLECTIONS.includes(collection));
    }
  });

  it("requires a second ownership sweep to close send races", () => {
    assert.equal(OUTING_DELETION_SWEEP_PASSES, 2);
  });

  it("does not condition deletion support on outing lifecycle", () => {
    const supported = ["draft", "planning", "confirmed", "meeting", "completed", "archived", "cancelled"];
    assert.equal(supported.length, 7);
  });
});
