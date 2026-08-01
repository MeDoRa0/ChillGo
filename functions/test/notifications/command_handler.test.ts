import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  NotificationCommandError,
  parseNotificationCommand,
  terminalNotificationCommandFields,
} from "../../src/notifications/command_schema";
import {safeNotificationCommandError} from "../../src/notifications/command_handler";

describe("notification command schema", () => {
  it("accepts a bounded device registration", () => {
    const command = parseNotificationCommand({
      type: "register_device",
      requestedByUserId: "user-1",
      payload: {
        installationId: "installation-0001",
        token: "provider-token-0001",
        platform: "android",
        permissionState: "granted",
      },
      status: "pending",
      createdAt: Timestamp.now(),
    });
    assert.equal(command.type, "register_device");
  });

  it("rejects extra fields and unsupported platforms", () => {
    assert.throws(() => parseNotificationCommand({
      type: "register_device",
      requestedByUserId: "user-1",
      payload: {
        installationId: "installation-0001",
        token: "provider-token-0001",
        platform: "web",
        permissionState: "granted",
      },
      status: "pending",
      createdAt: Timestamp.now(),
    }), NotificationCommandError);
    assert.throws(() => parseNotificationCommand({
      type: "register_device",
      requestedByUserId: "user-1",
      payload: {
        installationId: "installation-0001",
        token: "provider-token-0001",
        platform: "ios",
        permissionState: "granted",
      },
      status: "pending",
      createdAt: Timestamp.now(),
      injected: true,
    }), NotificationCommandError);
  });

  it("scrubs private payloads at terminal state", () => {
    const fields = terminalNotificationCommandFields("succeeded", {read: true});
    assert.ok("payload" in fields);
    assert.ok(!("errorMessage" in fields));
  });

  it("sanitizes unknown errors", () => {
    const safe = safeNotificationCommandError(new Error("private token"));
    assert.equal(safe.code, "internal_error");
    assert.ok(!safe.message.includes("private token"));
  });
});
