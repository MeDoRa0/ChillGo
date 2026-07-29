import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  claimDecision,
  compareOperationTuple,
} from "../../src/live_meetup/live_meetup_transactions";

describe("live meetup transaction ordering", () => {
  it("uses canonical timestamp then command id ordering", () => {
    const first = Timestamp.fromMillis(1000);
    const second = Timestamp.fromMillis(1001);
    assert.ok(compareOperationTuple(second, "a", first, "z") > 0);
    assert.ok(compareOperationTuple(first, "z", first, "a") > 0);
  });

  it("makes duplicate delivery idempotent without stealing claims", () => {
    assert.equal(
      claimDecision({status: "processing", processingEventId: "same"}, "same"),
      "claim",
    );
    assert.equal(
      claimDecision({status: "processing", processingEventId: "first"}, "second"),
      "owned_by_other",
    );
    for (const status of ["succeeded", "superseded", "failed"]) {
      assert.equal(claimDecision({status}, "event"), "terminal");
    }
  });
});
