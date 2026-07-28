import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
} from "firebase-admin/firestore";
import {
  LiveMeetupTransition,
  TransitionError,
  TransitionPhase,
} from "./transition_schema";
import {OutingDeletionService} from "../outings/outing_deletion";

export const PRESENCE_COLLECTIONS = [
  "live_meetup_statuses",
  "live_meetup_shares",
  "live_locations",
] as const;
export const PRIVACY_TRANSITION_BATCH_SIZE = 200;

export class PrivacyTransitionCoordinator {
  constructor(private readonly db: Firestore) {}

  async run(
    transitionId: string,
    transition: LiveMeetupTransition,
  ): Promise<Record<string, unknown>> {
    const transitionRef = this.db.collection("live_meetup_transitions").doc(transitionId);
    await this.phase(transitionRef, "authorize");
    const context = await this.authorize(transition);
    await this.phase(transitionRef, "deny_access");
    await this.denyAccess(transition, context);
    await this.phase(transitionRef, "delete_presence");
    await this.deletePresence(transition, context, transitionRef);
    await this.phase(transitionRef, "verify_empty");
    if (await this.hasPresence(transition, context)) {
      throw new Error("Presence verification failed.");
    }
    await this.phase(transitionRef, "finalize");
    await this.finalize(transition, context);
    return {
      type: transition.type,
      ...(hasOutingId(transition) ? {outingId: transition.outingId} : {}),
      crewId: transition.crewId,
    };
  }

  private async phase(
    ref: DocumentReference,
    phase: TransitionPhase,
    cursor?: string,
  ): Promise<void> {
    await ref.update({
      status: "processing",
      phase,
      cursor: cursor ?? FieldValue.delete(),
      leaseExpiresAt: Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
    });
  }

  private async authorize(transition: LiveMeetupTransition): Promise<Context> {
    const crewRef = this.db.collection("crews").doc(transition.crewId);
    const crew = await crewRef.get();
    if (!crew.exists) {
      if (transition.type === "delete_crew") return {crewRef};
      throw new TransitionError("not_found", "Crew not found.");
    }
    const isOwner = crew.data()?.ownerId === transition.requestedByUserId;
    if (transition.type === "delete_crew") {
      if (!isOwner) throw denied();
      return {crewRef};
    }
    if (transition.type === "remove_membership") {
      const membershipRef = this.db.collection("crew_memberships")
        .doc(`${transition.crewId}_${transition.targetUserId}`);
      const membership = await membershipRef.get();
      if (!membership.exists) return {crewRef, membershipRef};
      const self = transition.targetUserId === transition.requestedByUserId;
      if ((!self && !isOwner) || membership.data()?.role === "owner") throw denied();
      return {crewRef, membershipRef};
    }
    const outingRef = this.db.collection("outings").doc(transition.outingId);
    const outing = await outingRef.get();
    if (!outing.exists) throw new TransitionError("not_found", "Outing not found.");
    const outingData = outing.data()!;
    if (outingData.crewId !== transition.crewId) throw denied();
    const isManager = isOwner ||
      outingData.createdByUserId === transition.requestedByUserId;
    if (transition.type === "end_outing") {
      if (!isManager ||
          (outingData.status !== transition.targetOutingStatus &&
           !validTerminalChange(outingData.status, transition.targetOutingStatus))) {
        throw denied();
      }
      return {crewRef, outingRef, outing: outingData};
    }
    const participantRef = this.db.collection("outing_participants")
      .doc(`${transition.outingId}_${transition.targetUserId}`);
    const participant = await participantRef.get();
    if (!participant.exists) {
      if (transition.type === "remove_participant") {
        return {crewRef, outingRef, outing: outingData, participantRef};
      }
      throw new TransitionError("not_found", "Participant not found.");
    }
    if (transition.type === "change_attendance") {
      if (![transition.targetAttendanceStatus, "accepted"].includes(
        participant.data()?.attendanceStatus,
      ) ||
          outingData.status === "meeting" ||
          ["completed", "cancelled", "archived"].includes(outingData.status)) {
        throw new TransitionError("invalid_transition", "Attendance cannot be changed.");
      }
    } else if (!isManager || participant.data()?.isCreatorParticipant === true) {
      throw denied();
    }
    return {crewRef, outingRef, outing: outingData, participantRef};
  }

  private async denyAccess(
    transition: LiveMeetupTransition,
    context: Context,
  ): Promise<void> {
    if (transition.type === "delete_crew") {
      await context.crewRef?.set({
        deletionPending: true,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      const outings = await this.db.collection("outings")
        .where("crewId", "==", transition.crewId).get();
      await this.updateInBatches(
        outings.docs.map((doc) => doc.ref),
        {liveMeetupCleanupPending: true, updatedAt: FieldValue.serverTimestamp()},
      );
      return;
    }
    if (transition.type === "remove_membership") {
      if (context.membershipRef && (await context.membershipRef.get()).exists) {
        await context.membershipRef.update({liveMeetupCleanupPending: true});
      }
      return;
    }
    const target = transition.type === "end_outing" ?
      context.outingRef : context.participantRef;
    if (target && (await target.get()).exists) {
      await target.update({liveMeetupCleanupPending: true});
    }
  }

  private async deletePresence(
    transition: LiveMeetupTransition,
    context: Context,
    transitionRef: DocumentReference,
  ): Promise<void> {
    const outingIds = await this.affectedOutingIds(transition, context);
    for (const outingId of outingIds) {
      for (const collection of PRESENCE_COLLECTIONS) {
        let deleted: number;
        do {
          let query = this.db.collection(collection)
            .where("outingId", "==", outingId)
            .limit(PRIVACY_TRANSITION_BATCH_SIZE);
          if (transition.type === "change_attendance" ||
              transition.type === "remove_participant" ||
              transition.type === "remove_membership") {
            query = query.where("userId", "==", transition.targetUserId);
          }
          const snapshot = await query.get();
          deleted = snapshot.size;
          if (deleted) {
            const batch = this.db.batch();
            for (const doc of snapshot.docs) batch.delete(doc.ref);
            await batch.commit();
            await this.phase(
              transitionRef,
              "delete_presence",
              `${collection}:${outingId}:${snapshot.docs.at(-1)?.id ?? ""}`,
            );
          }
        } while (deleted === PRIVACY_TRANSITION_BATCH_SIZE);
      }
    }
  }

  private async hasPresence(
    transition: LiveMeetupTransition,
    context: Context,
  ): Promise<boolean> {
    for (const outingId of await this.affectedOutingIds(transition, context)) {
      for (const collection of PRESENCE_COLLECTIONS) {
        let query = this.db.collection(collection).where("outingId", "==", outingId).limit(1);
        if (transition.type === "change_attendance" ||
            transition.type === "remove_participant" ||
            transition.type === "remove_membership") {
          query = query.where("userId", "==", transition.targetUserId);
        }
        if (!(await query.get()).empty) return true;
      }
    }
    return false;
  }

  private async affectedOutingIds(
    transition: LiveMeetupTransition,
    context: Context,
  ): Promise<string[]> {
    if (hasOutingId(transition)) return [transition.outingId];
    if (transition.type === "delete_crew" || transition.type === "remove_membership") {
      const outings = await this.db.collection("outings")
        .where("crewId", "==", transition.crewId).get();
      return outings.docs.map((doc) => doc.id);
    }
    return context.outingRef ? [context.outingRef.id] : [];
  }

  private async finalize(
    transition: LiveMeetupTransition,
    context: Context,
  ): Promise<void> {
    if (transition.type === "end_outing") {
      await context.outingRef?.update({
        status: transition.targetOutingStatus,
        liveMeetupCleanupPending: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
        ...(transition.targetOutingStatus === "archived" ?
          {archivedAt: FieldValue.serverTimestamp()} : {}),
      });
      return;
    }
    if (transition.type === "change_attendance") {
      await context.participantRef?.update({
        attendanceStatus: "declined",
        respondedAt: FieldValue.serverTimestamp(),
        liveMeetupCleanupPending: FieldValue.delete(),
      });
      return;
    }
    if (transition.type === "remove_participant") {
      await context.participantRef?.delete();
      return;
    }
    if (transition.type === "remove_membership") {
      const participants = await this.db.collection("outing_participants")
        .where("crewId", "==", transition.crewId)
        .where("userId", "==", transition.targetUserId).get();
      await this.deleteReferences(participants.docs.map((doc) => doc.ref));
      await context.membershipRef?.delete();
      return;
    }
    const outings = await this.db.collection("outings")
      .where("crewId", "==", transition.crewId).get();
    const deletion = new OutingDeletionService(this.db);
    for (const outing of outings.docs) {
      await deletion.deleteAlreadyPending(outing.id);
    }
    const participants = await this.db.collection("outing_participants")
      .where("crewId", "==", transition.crewId).get();
    const memberships = await this.db.collection("crew_memberships")
      .where("crewId", "==", transition.crewId).get();
    const invitations = await this.db.collection("crew_invitations")
      .where("crewId", "==", transition.crewId).get();
    await this.deleteReferences([
      ...participants.docs.map((doc) => doc.ref),
      ...invitations.docs.map((doc) => doc.ref),
      ...memberships.docs.map((doc) => doc.ref),
      context.crewRef!,
    ]);
  }

  private async updateInBatches(
    refs: DocumentReference[],
    data: DocumentData,
  ): Promise<void> {
    for (let start = 0; start < refs.length; start += PRIVACY_TRANSITION_BATCH_SIZE) {
      const batch = this.db.batch();
      for (const ref of refs.slice(start, start + PRIVACY_TRANSITION_BATCH_SIZE)) {
        batch.update(ref, data);
      }
      await batch.commit();
    }
  }

  private async deleteReferences(refs: DocumentReference[]): Promise<void> {
    for (let start = 0; start < refs.length; start += PRIVACY_TRANSITION_BATCH_SIZE) {
      const batch = this.db.batch();
      for (const ref of refs.slice(start, start + PRIVACY_TRANSITION_BATCH_SIZE)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}

interface Context {
  crewRef?: DocumentReference;
  outingRef?: DocumentReference;
  participantRef?: DocumentReference;
  membershipRef?: DocumentReference;
  outing?: DocumentData;
}

function hasOutingId(
  transition: LiveMeetupTransition,
): transition is Extract<LiveMeetupTransition, {outingId: string}> {
  return "outingId" in transition;
}
function denied(): TransitionError {
  return new TransitionError("permission_denied", "Access denied.");
}
export function validTerminalChange(current: unknown, target: string): boolean {
  return (target === "completed" && current === "meeting") ||
    (target === "cancelled" && ["draft", "planning", "confirmed"].includes(String(current))) ||
    (target === "archived" && current === "completed");
}
