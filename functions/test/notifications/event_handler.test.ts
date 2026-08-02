import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  NOTIFICATION_CATEGORIES,
  parseNotificationEvent,
} from "../../src/notifications/eligibility";
import {
  deterministicNotificationId,
  NOTIFICATION_RETENTION_MS,
} from "../../src/notifications/notification_transactions";

describe("notification events", () => {
  it("supports the crew member joined category", () => {
    assert.equal(NOTIFICATION_CATEGORIES.length, 8);
    assert.ok(NOTIFICATION_CATEGORIES.includes("crew_member_joined"));
    assert.ok(!NOTIFICATION_CATEGORIES.includes("marketing" as never));
  });

  it("parses the minimal trusted event", () => {
    const parsed = parseNotificationEvent({
      sourceEventId: "event-1",
      sourceVersion: "1",
      sourceId: "invitation-1",
      category: "crew_invitation",
      crewId: "crew-1",
      recipientUserId: "user-1",
      createdAt: Timestamp.now(),
    });
    assert.equal(parsed.recipientUserId, "user-1");
  });

  it("derives stable per-recipient identities", () => {
    const first = deterministicNotificationId("event-1", "user-1");
    assert.equal(first, deterministicNotificationId("event-1", "user-1"));
    assert.notEqual(first, deterministicNotificationId("event-1", "user-2"));
    assert.equal(NOTIFICATION_RETENTION_MS, 30 * 24 * 60 * 60 * 1000);
  });
});
