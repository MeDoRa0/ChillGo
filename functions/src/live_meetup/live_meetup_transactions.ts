import {createHash} from "crypto";
import {
  FieldValue,
  Firestore,
  GeoPoint,
  Timestamp,
} from "firebase-admin/firestore";
import {
  LiveMeetupCommand,
  LiveMeetupCommandError,
  PublishLocationCommand,
  SetMeetupPointCommand,
  SetStatusCommand,
  StartSharingCommand,
  StopSharingCommand,
  terminalCommandFields,
} from "./command_schema";

const LOCATION_LIFETIME_MS = 2 * 60 * 1000;

export function compareOperationTuple(
  leftAt: Timestamp,
  leftId: string,
  rightAt: Timestamp,
  rightId: string,
): number {
  const byTime = leftAt.toMillis() - rightAt.toMillis();
  return byTime || leftId.localeCompare(rightId);
}

export function claimDecision(
  data: FirebaseFirestore.DocumentData | undefined,
  eventId: string,
): "claim" | "terminal" | "owned_by_other" {
  if (!data || ["succeeded", "superseded", "failed"].includes(data.status)) {
    return "terminal";
  }
  if (data.status === "processing" && data.processingEventId !== eventId) {
    return "owned_by_other";
  }
  return "claim";
}

export class LiveMeetupTransactions {
  constructor(
    private readonly db: Firestore,
    private readonly processingNow: () => Timestamp = Timestamp.now,
  ) {}

  async process(
    commandId: string,
    eventId: string,
    command: LiveMeetupCommand,
  ): Promise<Record<string, unknown> | null> {
    const commandRef = this.db.collection("live_meetup_commands").doc(commandId);
    const claimed = await this.db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(commandRef);
      if (claimDecision(snapshot.data(), eventId) !== "claim") return false;
      transaction.update(commandRef, {
        status: "processing",
        processingEventId: eventId,
      });
      return true;
    });
    if (!claimed) return null;

    switch (command.type) {
    case "set_status":
      return this.setStatus(commandRef, commandId, command);
    case "start_sharing":
      return this.startSharing(commandRef, commandId, command);
    case "publish_location":
      return this.publishLocation(commandRef, commandId, command);
    case "stop_sharing":
      return this.stopSharing(commandRef, commandId, command);
    case "set_meetup_point":
      return this.setMeetupPoint(commandRef, commandId, command);
    }
  }

  private async setStatus(
    commandRef: FirebaseFirestore.DocumentReference,
    commandId: string,
    command: SetStatusCommand,
  ): Promise<Record<string, unknown>> {
    const statusRef = this.db.collection("live_meetup_statuses")
      .doc(`${command.outingId}_${command.requestedByUserId}`);
    return this.db.runTransaction(async (transaction) => {
      const [access, existing] = await Promise.all([
        this.readParticipantAccess(transaction, command),
        transaction.get(statusRef),
      ]);
      assertParticipantAccess(access, command);
      if (isStoredTupleNewer(existing.data(), command.createdAt, commandId)) {
        const result = {acceptedAt: command.createdAt, superseded: true};
        transaction.update(
          commandRef,
          terminalCommandFields(command.createdAt, "superseded", result),
        );
        return result;
      }
      transaction.set(statusRef, {
        outingId: command.outingId,
        crewId: command.crewId,
        userId: command.requestedByUserId,
        value: command.payload.value,
        acceptedAt: command.createdAt,
        acceptedCommandId: commandId,
      });
      const result = {acceptedAt: command.createdAt, superseded: false};
      transaction.update(
        commandRef,
        terminalCommandFields(command.createdAt, "succeeded", result),
      );
      return result;
    });
  }

  private async startSharing(
    commandRef: FirebaseFirestore.DocumentReference,
    commandId: string,
    command: StartSharingCommand,
  ): Promise<Record<string, unknown>> {
    const shareRef = this.db.collection("live_meetup_shares")
      .doc(`${command.outingId}_${command.requestedByUserId}`);
    const locationRef = this.db.collection("live_locations").doc(shareRef.id);
    return this.db.runTransaction(async (transaction) => {
      const [access, share] = await Promise.all([
        this.readParticipantAccess(transaction, command),
        transaction.get(shareRef),
      ]);
      assertParticipantAccess(access, command);
      const data = share.data();
      if (isControlTupleNewer(data, command.createdAt, commandId)) {
        const result = {acceptedAt: command.createdAt, superseded: true};
        transaction.update(
          commandRef,
          terminalCommandFields(command.createdAt, "superseded", result),
        );
        return result;
      }
      const tokenHash = hash(command.payload.sessionToken);
      if (data?.active === true &&
          (data.sessionId !== command.payload.sessionId ||
            data.sessionTokenHash !== tokenHash) &&
          !command.payload.transferExisting) {
        throw new LiveMeetupCommandError(
          "transfer_required",
          "Confirm transferring sharing from the other device.",
        );
      }
      transaction.set(shareRef, {
        outingId: command.outingId,
        crewId: command.crewId,
        userId: command.requestedByUserId,
        active: true,
        sessionId: command.payload.sessionId,
        sessionTokenHash: tokenHash,
        deviceSessionHash: hash(command.payload.deviceSessionId),
        startedAt: command.createdAt,
        stoppedAt: null,
        lastControlAt: command.createdAt,
        lastControlCommandId: commandId,
      });
      transaction.delete(locationRef);
      const result = {acceptedAt: command.createdAt, transferred: data?.active === true};
      transaction.update(
        commandRef,
        terminalCommandFields(command.createdAt, "succeeded", result),
      );
      return result;
    });
  }

  private async publishLocation(
    commandRef: FirebaseFirestore.DocumentReference,
    commandId: string,
    command: PublishLocationCommand,
  ): Promise<Record<string, unknown>> {
    if (command.createdAt.toMillis() + LOCATION_LIFETIME_MS <=
        this.processingNow().toMillis()) {
      throw new LiveMeetupCommandError("stale_location", "Location sample expired.");
    }
    const id = `${command.outingId}_${command.requestedByUserId}`;
    const shareRef = this.db.collection("live_meetup_shares").doc(id);
    const locationRef = this.db.collection("live_locations").doc(id);
    return this.db.runTransaction(async (transaction) => {
      const [access, share, existing] = await Promise.all([
        this.readParticipantAccess(transaction, command),
        transaction.get(shareRef),
        transaction.get(locationRef),
      ]);
      assertParticipantAccess(access, command);
      const shareData = share.data();
      if (!share.exists || shareData?.active !== true) {
        throw new LiveMeetupCommandError("session_stopped", "Sharing has stopped.");
      }
      if (shareData?.sessionId !== command.payload.sessionId ||
          shareData?.sessionTokenHash !== hash(command.payload.sessionToken)) {
        throw new LiveMeetupCommandError(
          "session_transferred",
          "Sharing moved to another device.",
        );
      }
      if (isStoredTupleNewer(existing.data(), command.createdAt, commandId)) {
        const result = {acceptedAt: command.createdAt, superseded: true};
        transaction.update(
          commandRef,
          terminalCommandFields(command.createdAt, "superseded", result),
        );
        return result;
      }
      const expiresAt = Timestamp.fromMillis(
        command.createdAt.toMillis() + LOCATION_LIFETIME_MS,
      );
      transaction.set(locationRef, {
        outingId: command.outingId,
        crewId: command.crewId,
        userId: command.requestedByUserId,
        point: new GeoPoint(command.payload.latitude, command.payload.longitude),
        accuracyMeters: command.payload.accuracyMeters,
        acceptedAt: command.createdAt,
        acceptedCommandId: commandId,
        expiresAt,
      });
      const result = {acceptedAt: command.createdAt, expiresAt, superseded: false};
      transaction.update(
        commandRef,
        terminalCommandFields(command.createdAt, "succeeded", result),
      );
      return result;
    });
  }

  private async stopSharing(
    commandRef: FirebaseFirestore.DocumentReference,
    commandId: string,
    command: StopSharingCommand,
  ): Promise<Record<string, unknown>> {
    const id = `${command.outingId}_${command.requestedByUserId}`;
    const shareRef = this.db.collection("live_meetup_shares").doc(id);
    const locationRef = this.db.collection("live_locations").doc(id);
    return this.db.runTransaction(async (transaction) => {
      const [access, share] = await Promise.all([
        this.readParticipantAccess(transaction, command),
        transaction.get(shareRef),
      ]);
      assertParticipantAccess(access, command);
      const data = share.data();
      if (data?.active !== true) {
        transaction.delete(locationRef);
        const result = {acceptedAt: command.createdAt, idempotent: true};
        transaction.update(
          commandRef,
          terminalCommandFields(command.createdAt, "succeeded", result),
        );
        return result;
      }
      if (data.sessionId !== command.payload.sessionId ||
          data.sessionTokenHash !== hash(command.payload.sessionToken)) {
        throw new LiveMeetupCommandError(
          "session_transferred",
          "Sharing moved to another device.",
        );
      }
      transaction.update(shareRef, {
        active: false,
        sessionId: FieldValue.delete(),
        sessionTokenHash: FieldValue.delete(),
        deviceSessionHash: FieldValue.delete(),
        stoppedAt: command.createdAt,
        lastControlAt: command.createdAt,
        lastControlCommandId: commandId,
      });
      transaction.delete(locationRef);
      const result = {acceptedAt: command.createdAt, idempotent: false};
      transaction.update(
        commandRef,
        terminalCommandFields(command.createdAt, "succeeded", result),
      );
      return result;
    });
  }

  private async setMeetupPoint(
    commandRef: FirebaseFirestore.DocumentReference,
    commandId: string,
    command: SetMeetupPointCommand,
  ): Promise<Record<string, unknown>> {
    const pointRef = this.db.collection("meetup_points").doc(command.outingId);
    return this.db.runTransaction(async (transaction) => {
      const [access, existing] = await Promise.all([
        this.readOrganizerAccess(transaction, command),
        transaction.get(pointRef),
      ]);
      const {outing, membership} = access;
      if (!outing.exists || !membership.exists) {
        throw new LiveMeetupCommandError("permission_denied", "Point unavailable.");
      }
      const data = outing.data()!;
      if (data.crewId !== command.crewId ||
          !["confirmed", "meeting"].includes(data.status) ||
          data.deletionPending === true ||
          data.liveMeetupCleanupPending === true) {
        throw new LiveMeetupCommandError("invalid_outing_state", "Point unavailable.");
      }
      const isOrganizer = data.createdByUserId === command.requestedByUserId ||
        membership.data()?.role === "owner";
      if (!isOrganizer) {
        throw new LiveMeetupCommandError("permission_denied", "Point unavailable.");
      }
      if (data.locationText !== command.payload.locationTextSnapshot ||
          !command.payload.locationTextSnapshot.trim()) {
        throw new LiveMeetupCommandError(
          "invalid_command",
          "The outing location changed. Select the point again.",
        );
      }
      if (isStoredTupleNewer(existing.data(), command.createdAt, commandId)) {
        const result = {acceptedAt: command.createdAt, superseded: true};
        transaction.update(
          commandRef,
          terminalCommandFields(command.createdAt, "superseded", result),
        );
        return result;
      }
      transaction.set(pointRef, {
        outingId: command.outingId,
        crewId: command.crewId,
        point: new GeoPoint(command.payload.latitude, command.payload.longitude),
        locationTextSnapshot: command.payload.locationTextSnapshot,
        setByUserId: command.requestedByUserId,
        acceptedAt: command.createdAt,
        acceptedCommandId: commandId,
      });
      const result = {acceptedAt: command.createdAt, superseded: false};
      transaction.update(
        commandRef,
        terminalCommandFields(command.createdAt, "succeeded", result),
      );
      return result;
    });
  }

  private async readParticipantAccess(
    transaction: FirebaseFirestore.Transaction,
    command: LiveMeetupCommand,
  ) {
    const outingRef = this.db.collection("outings").doc(command.outingId);
    const crewRef = this.db.collection("crews").doc(command.crewId);
    const membershipRef = this.db.collection("crew_memberships")
      .doc(`${command.crewId}_${command.requestedByUserId}`);
    const participantRef = this.db.collection("outing_participants")
      .doc(`${command.outingId}_${command.requestedByUserId}`);
    const [outing, crew, membership, participant] = await Promise.all([
      transaction.get(outingRef),
      transaction.get(crewRef),
      transaction.get(membershipRef),
      transaction.get(participantRef),
    ]);
    return {outing, crew, membership, participant};
  }

  private async readOrganizerAccess(
    transaction: FirebaseFirestore.Transaction,
    command: SetMeetupPointCommand,
  ) {
    const outing = await transaction.get(
      this.db.collection("outings").doc(command.outingId),
    );
    const membership = await transaction.get(
      this.db.collection("crew_memberships")
        .doc(`${command.crewId}_${command.requestedByUserId}`),
    );
    return {outing, membership};
  }
}

function assertParticipantAccess(
  access: Awaited<ReturnType<LiveMeetupTransactions["readParticipantAccess"]>>,
  command: LiveMeetupCommand,
): void {
  const {outing, crew, membership, participant} = access;
  if (!outing.exists || !crew.exists) {
    throw new LiveMeetupCommandError("not_found", "Live Meetup is unavailable.");
  }
  const outingData = outing.data()!;
  if (outingData.crewId !== command.crewId ||
      outingData.status !== "meeting" ||
      outingData.deletionPending === true ||
      outingData.liveMeetupCleanupPending === true ||
      crew.data()?.deletionPending === true) {
    throw new LiveMeetupCommandError("invalid_outing_state", "Live Meetup is unavailable.");
  }
  if (!membership.exists || membership.data()?.liveMeetupCleanupPending === true) {
    throw new LiveMeetupCommandError("permission_denied", "Live Meetup is unavailable.");
  }
  if (!participant.exists ||
      participant.data()?.attendanceStatus !== "accepted" ||
      participant.data()?.liveMeetupCleanupPending === true) {
    throw new LiveMeetupCommandError("attendance_required", "Live Meetup is unavailable.");
  }
}

function isStoredTupleNewer(
  data: FirebaseFirestore.DocumentData | undefined,
  createdAt: Timestamp,
  commandId: string,
): boolean {
  return data?.acceptedAt instanceof Timestamp &&
    typeof data.acceptedCommandId === "string" &&
    compareOperationTuple(
      data.acceptedAt,
      data.acceptedCommandId,
      createdAt,
      commandId,
    ) >= 0;
}

function isControlTupleNewer(
  data: FirebaseFirestore.DocumentData | undefined,
  createdAt: Timestamp,
  commandId: string,
): boolean {
  return data?.lastControlAt instanceof Timestamp &&
    typeof data.lastControlCommandId === "string" &&
    compareOperationTuple(
      data.lastControlAt,
      data.lastControlCommandId,
      createdAt,
      commandId,
    ) >= 0;
}

function hash(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}
