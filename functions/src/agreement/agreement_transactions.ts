import {Firestore,FieldValue,Timestamp} from "firebase-admin/firestore";
import {Command,CommandError} from "./command_schema";
import {Proposal,Vote,tally} from "./agreement_tally";
import {OutingDeletionService} from "../outings/outing_deletion";
export class AgreementTransactions {
 constructor(private readonly db:Firestore){}
 async process(id:string,eventId:string,command:Command):Promise<Record<string,unknown>>{
  const ref=this.db.collection("agreement_commands").doc(id);
  const claimed=await this.db.runTransaction(async tx=>{const s=await tx.get(ref);const d=s.data();if(!d||["succeeded","failed"].includes(d.status))return false;
    if(d.status==="processing"&&d.processingEventId!==eventId)return false;tx.update(ref,{status:"processing",processingEventId:eventId});return true;});
  if(!claimed)throw new CommandError("already_processed","Command already processed.");
  const result=await this.execute(command,id);await ref.update({status:"succeeded",result,processedAt:FieldValue.serverTimestamp()});return result;
 }
 private async execute(c:Command,commandId:string):Promise<Record<string,unknown>>{
  const outingRef=this.db.collection("outings").doc(c.outingId);const outingSnap=await outingRef.get();if(!outingSnap.exists){if(c.type==="delete_outing"||c.type==="expire_outing")return {outingId:c.outingId,alreadyAbsent:true};throw new CommandError("not_found","Outing not found.");}
  const outing=outingSnap.data()!;if(outing.crewId!==c.crewId)throw new CommandError("permission_denied","Access denied.");await this.authorize(c,outing);
  if(c.type==="open_round")return this.openRound(c,outing);
  if(c.type==="create_proposal")return this.createProposal(c,outing);
  if(c.type==="preview_confirmation")return this.preview(c,outing);
  if(c.type==="confirm_round")return this.confirm(c,outing);
  if(c.type==="reopen_round")return this.reopen(c,outing);
  if(c.type==="cancel_outing")return this.cancel(c,outing);
  if(c.type==="expire_outing")return this.expireOuting(c,commandId);
  return this.deleteOuting(c,commandId);
 }
 private async authorize(c:Command,o:FirebaseFirestore.DocumentData){const crew=await this.db.collection("crews").doc(c.crewId).get();
  const organizer=o.createdByUserId===c.requestedByUserId||crew.data()?.ownerId===c.requestedByUserId;
  if(c.type==="delete_outing"&&o.createdByUserId!==c.requestedByUserId)throw new CommandError("permission_denied","Outing creator required.");
  if(c.type==="expire_outing"){const membership=await this.db.collection("crew_memberships").doc(`${c.crewId}_${c.requestedByUserId}`).get();
    if(!membership.exists)throw new CommandError("permission_denied","Crew membership required.");}
  if(["open_round","preview_confirmation","confirm_round","reopen_round","cancel_outing"].includes(c.type)&&!organizer)throw new CommandError("permission_denied","Organizer required.");
  if(c.type==="create_proposal"){const p=await this.db.collection("outing_participants").doc(`${c.outingId}_${c.requestedByUserId}`).get();const attendance=p.data()?.attendanceStatus;
    if(!["accepted","declined"].includes(attendance))throw new CommandError("attendance_response_required","Accept or decline before proposing a change.");}}
 private async openRound(c:Command,o:FirebaseFirestore.DocumentData){if(o.status!=="draft")throw new CommandError("invalid_outing_state","Draft required.");return this.newRound(c,o,undefined);}
 private async newRound(c:Command,o:FirebaseFirestore.DocumentData,reason:string|undefined){const sequence=(o.agreementRoundSequence??0)+1;const roundId=`${c.outingId}_${sequence}`;const now=Timestamp.now();
  const round=this.db.collection("agreement_rounds").doc(roundId);const time=this.db.collection("agreement_proposals").doc();const location=this.db.collection("agreement_proposals").doc();const batch=this.db.batch();
  const common={roundId,outingId:c.outingId,crewId:c.crewId,authorUserId:c.requestedByUserId,authorDisplayName:"Organizer",createdAt:now,isSeed:true};
  batch.set(time,{...common,category:"time",timeValue:o.scheduledAt,normalizedKey:o.scheduledAt.toMillis().toString()});batch.set(location,{...common,category:"location",locationText:o.locationText,normalizedKey:normalize(o.locationText)});
  batch.set(round,{outingId:c.outingId,crewId:c.crewId,sequence,status:"open",openedByUserId:c.requestedByUserId,openedAt:now,seedTimeProposalId:time.id,seedLocationProposalId:location.id,...reason?{reopenReason:reason}:{}});
  batch.update(this.db.collection("outings").doc(c.outingId),{status:"planning",agreementRoundSequence:sequence,activeAgreementRoundId:roundId,updatedAt:now});await batch.commit();return {roundId};}
 private async createProposal(c:Command,o:FirebaseFirestore.DocumentData){if(o.status!=="planning"||!o.activeAgreementRoundId)throw new CommandError("invalid_outing_state","Planning required.");const category=c.payload.category;if(category!=="time"&&category!=="location")throw new CommandError("invalid_command","Invalid category.");
  const value=category==="time"?c.payload.timeValue:c.payload.locationText;const key=category==="time"?(value as Timestamp)?.toMillis().toString():normalize(String(value??""));if(!key)throw new CommandError("invalid_command","Invalid proposal.");if(category==="time"&&(!(value instanceof Timestamp)||value.toDate()<=new Date()))throw new CommandError("expired_time_proposal","Time must be future.");
  const q=await this.db.collection("agreement_proposals").where("roundId","==",o.activeAgreementRoundId).where("category","==",category).get();const reused=q.docs.find(d=>d.data().normalizedKey===key);if(reused)return {proposalId:reused.id,reused:true};if(q.size>=50)throw new CommandError("proposal_limit_reached","Proposal limit reached.");const ref=this.db.collection("agreement_proposals").doc();
  const participant=await this.db.collection("outing_participants").doc(`${c.outingId}_${c.requestedByUserId}`).get();
  const proposal={roundId:o.activeAgreementRoundId,outingId:c.outingId,crewId:c.crewId,category,authorUserId:c.requestedByUserId,authorDisplayName:participant.data()?.displayName??"Participant",normalizedKey:key,createdAt:FieldValue.serverTimestamp(),isSeed:false,...category==="time"?{timeValue:value}:{locationText:String(value).trim()}};
  await this.db.runTransaction(async transaction=>{const latestOuting=await transaction.get(this.db.collection("outings").doc(c.outingId));if(!latestOuting.exists||latestOuting.data()?.deletionPending===true)throw new CommandError("not_found","Outing was removed.");if(latestOuting.data()?.status!=="planning"||latestOuting.data()?.activeAgreementRoundId!==o.activeAgreementRoundId)throw new CommandError("invalid_outing_state","Planning changed.");transaction.set(ref,proposal);});return {proposalId:ref.id,reused:false};}
 private async tallies(o:FirebaseFirestore.DocumentData,c:Command){const round=o.activeAgreementRoundId;const [ps,vs,parts,members]=await Promise.all([this.db.collection("agreement_proposals").where("roundId","==",round).get(),this.db.collection("agreement_votes").where("roundId","==",round).get(),this.db.collection("outing_participants").where("outingId","==",c.outingId).get(),this.db.collection("crew_memberships").where("crewId","==",c.crewId).get()]);
  const memberIds=new Set(members.docs.map(d=>d.data().userId as string));const eligible=new Set(parts.docs.filter(d=>d.data().attendanceStatus==="accepted"&&memberIds.has(d.data().userId)).map(d=>d.data().userId as string));const proposals=ps.docs.map(d=>({id:d.id,...d.data()} as Proposal));const votes=vs.docs.map(d=>d.data() as Vote);return {eligible,time:tally("time",proposals,votes,eligible,new Date()),location:tally("location",proposals,votes,eligible,new Date()),proposals};}
 private async preview(c:Command,o:FirebaseFirestore.DocumentData){if(o.status!=="planning")throw new CommandError("invalid_outing_state","Planning required.");const t=await this.tallies(o,c);if(!t.time.leaders.length||!t.location.leaders.length)throw new CommandError("insufficient_votes","Both categories need votes.");return {timeChoiceRequired:t.time.leaders.length>1,timeTiedProposalIds:t.time.leaders.length>1?t.time.leaders:[],locationChoiceRequired:t.location.leaders.length>1,locationTiedProposalIds:t.location.leaders.length>1?t.location.leaders:[]};}
 private async confirm(c:Command,o:FirebaseFirestore.DocumentData){const t=await this.tallies(o,c);if(!t.time.leaders.length||!t.location.leaders.length)throw new CommandError("insufficient_votes","Both categories need votes.");const choose=(leaders:string[],key:string)=>{if(leaders.length===1)return leaders[0];const v=c.payload[key];if(typeof v!=="string"||!leaders.includes(v))throw new CommandError("confirmation_state_changed","Request a new preview.");return v;};const ti=choose(t.time.leaders,"selectedTimeProposalId"),li=choose(t.location.leaders,"selectedLocationProposalId");const tp=t.proposals.find(p=>p.id===ti)!,lp=t.proposals.find(p=>p.id===li)!;const now=Timestamp.now(),batch=this.db.batch();
  for(const [category,data,selected] of [["time",t.time,ti],["location",t.location,li]] as const)for(const [proposalId,voteCount] of data.totals)batch.set(this.db.collection("agreement_results").doc(`${o.activeAgreementRoundId}_${category}_${proposalId}`),{roundId:o.activeAgreementRoundId,outingId:c.outingId,crewId:c.crewId,category,proposalId,voteCount,isLeader:data.leaders.includes(proposalId),isSelected:proposalId===selected,eligibleParticipantCount:t.eligible.size,participatingVoterCount:data.participatingVoters,createdAt:now});
  batch.update(this.db.collection("agreement_rounds").doc(o.activeAgreementRoundId),{status:"confirmed",confirmedByUserId:c.requestedByUserId,confirmedAt:now,closedAt:now,selectedTimeProposalId:ti,selectedLocationProposalId:li,eligibleVoterCount:t.eligible.size,timeVoteCount:t.time.participatingVoters,locationVoteCount:t.location.participatingVoters});batch.update(this.db.collection("outings").doc(c.outingId),{status:"confirmed",scheduledAt:tp.timeValue,locationText:(lp as any).locationText,confirmedAgreementRoundId:o.activeAgreementRoundId,activeAgreementRoundId:null,updatedAt:now});await batch.commit();return {roundId:o.activeAgreementRoundId,selectedTimeProposalId:ti,selectedLocationProposalId:li};}
 private async reopen(c:Command,o:FirebaseFirestore.DocumentData){const reason=String(c.payload.reason??"").trim();if(o.status!=="confirmed"||reason.length<3||reason.length>200||!o.confirmedAgreementRoundId)throw new CommandError("invalid_outing_state","Cannot reopen.");
  const sequence=(o.agreementRoundSequence??0)+1,roundId=`${c.outingId}_${sequence}`,now=Timestamp.now();const round=this.db.collection("agreement_rounds").doc(roundId),time=this.db.collection("agreement_proposals").doc(),location=this.db.collection("agreement_proposals").doc(),batch=this.db.batch();const common={roundId,outingId:c.outingId,crewId:c.crewId,authorUserId:c.requestedByUserId,authorDisplayName:"Organizer",createdAt:now,isSeed:true};
  batch.set(time,{...common,category:"time",timeValue:o.scheduledAt,normalizedKey:o.scheduledAt.toMillis().toString()});batch.set(location,{...common,category:"location",locationText:o.locationText,normalizedKey:normalize(o.locationText)});batch.set(round,{outingId:c.outingId,crewId:c.crewId,sequence,status:"open",openedByUserId:c.requestedByUserId,openedAt:now,reopenReason:reason,seedTimeProposalId:time.id,seedLocationProposalId:location.id});batch.update(this.db.collection("agreement_rounds").doc(o.confirmedAgreementRoundId),{status:"superseded",supersededByRoundId:roundId,closedAt:now});batch.update(this.db.collection("outings").doc(c.outingId),{status:"planning",agreementRoundSequence:sequence,activeAgreementRoundId:roundId,updatedAt:now});await batch.commit();return {roundId};}
 private async cancel(c:Command,o:FirebaseFirestore.DocumentData){const reason=String(c.payload.reason??"").trim();if(!["draft","planning","confirmed"].includes(o.status)||reason.length<3||reason.length>200)throw new CommandError("invalid_outing_state","Cannot cancel.");const batch=this.db.batch(),now=Timestamp.now();batch.update(this.db.collection("outings").doc(c.outingId),{status:"cancelled",cancelledReason:reason,cancelledAt:now,updatedAt:now});if(o.activeAgreementRoundId)batch.update(this.db.collection("agreement_rounds").doc(o.activeAgreementRoundId),{status:"cancelled",closedAt:now});await batch.commit();return {outingId:c.outingId};}
 private async deleteOuting(c:Command,commandId:string){
  const alreadyAbsent=await new OutingDeletionService(this.db).deleteCreatorOwned(c.outingId,c.crewId,c.requestedByUserId,commandId);
  return {outingId:c.outingId,alreadyAbsent};
 }
 private async expireOuting(c:Command,commandId:string){
  const deleted=await new OutingDeletionService(this.db).deleteIfCleanupEligible(c.outingId,Timestamp.now(),commandId);
  if(!deleted)throw new CommandError("invalid_outing_state","Outing cleanup requires 12 elapsed hours.");
  return {outingId:c.outingId,alreadyAbsent:false};
 }
}
const normalize=(value:string)=>value.trim().replace(/\s+/g," ").toLocaleLowerCase("en-US");
