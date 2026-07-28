import {Timestamp} from "firebase-admin/firestore";

export const FIXTURE_OUTING_ID = "outing-live";
export const FIXTURE_CREW_ID = "crew-live";

export function attendeeFixtures(count = 100): Record<string, unknown>[] {
  return Array.from({length: count}, (_, index) => {
    const userId = `user-${index.toString().padStart(3, "0")}`;
    return {
      id: `${FIXTURE_OUTING_ID}_${userId}`,
      outingId: FIXTURE_OUTING_ID,
      crewId: FIXTURE_CREW_ID,
      userId,
      attendanceStatus: "accepted",
      displayName: `Attendee ${index}`,
    };
  });
}

export function activeSessionFixture(userId: string): Record<string, unknown> {
  return {
    outingId: FIXTURE_OUTING_ID,
    crewId: FIXTURE_CREW_ID,
    userId,
    sessionId: `session-${userId}`,
    sessionTokenHash: `hash-${userId}`,
    active: true,
    generation: 1,
  };
}

export function trustedCommandTuple(
  acceptedMillis: number,
  commandId: string,
): {acceptedAt: Timestamp; commandId: string} {
  return {acceptedAt: Timestamp.fromMillis(acceptedMillis), commandId};
}

export function transitionCursorFixture(
  collection: string,
  lastId: string,
): string {
  return `${collection}:${FIXTURE_OUTING_ID}:${lastId}`;
}

export function partialCleanupFixture(processed = 40): Record<string, unknown> {
  return {
    status: "processing",
    phase: "delete_presence",
    cursor: transitionCursorFixture(
      "live_meetup_statuses",
      `user-${processed - 1}`,
    ),
    processed,
    remaining: 100 - processed,
  };
}
