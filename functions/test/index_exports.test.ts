import {strict as assert} from "node:assert";
import * as deployedFunctions from "../src/index";

describe("deployed function exports", () => {
  it("includes both required minutely cleanup schedules", () => {
    assert.equal(typeof deployedFunctions.chatCleanupScheduled, "function");
    assert.equal(typeof deployedFunctions.liveMeetupCleanupScheduled, "function");
  });
});
