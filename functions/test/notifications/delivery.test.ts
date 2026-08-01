import {strict as assert} from "assert";
import {
  genericAlertMessage,
  invalidTokenCode,
} from "../../src/notifications/delivery";

describe("notification delivery", () => {
  it("removes only permanently invalid provider targets", () => {
    assert.equal(
      invalidTokenCode("messaging/registration-token-not-registered"),
      true,
    );
    assert.equal(invalidTokenCode("messaging/invalid-registration-token"), true);
    assert.equal(invalidTokenCode("messaging/internal-error"), false);
    assert.equal(invalidTokenCode(undefined), false);
  });

  it("uses generic provider copy and an opaque navigation payload", () => {
    const message = genericAlertMessage(
      ["provider-token"],
      "notification-1",
      "outing_changed",
    );
    assert.deepEqual(Object.keys(message.data ?? {}).sort(), [
      "category", "notificationId", "schemaVersion",
    ]);
    assert.equal(message.notification?.title, "ChillGo update");
    assert.ok(!JSON.stringify(message).includes("outing-1"));
    assert.ok(!JSON.stringify(message).includes("crew-1"));
    assert.ok(!JSON.stringify(message).includes("location"));
  });
});
