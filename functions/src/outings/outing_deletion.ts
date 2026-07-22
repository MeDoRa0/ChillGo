import {Firestore,FieldValue,Timestamp} from "firebase-admin/firestore";
import {CommandError} from "../agreement/command_schema";

export const OUTING_OWNED_COLLECTIONS=[
 "outing_participants",
 "agreement_rounds",
 "agreement_proposals",
 "agreement_votes",
 "agreement_results",
 "chat_messages",
 "chat_read_states",
 "chat_rate_limits",
];
export const OUTING_DELETION_SWEEP_PASSES=2;
const CLEANUP_DELAY_MILLIS=12*60*60*1000;

export class OutingDeletionService {
 constructor(private readonly db:Firestore){}

 async deleteCreatorOwned(outingId:string,crewId:string,creatorId:string,commandId:string):Promise<boolean>{
  const outingRef=this.db.collection("outings").doc(outingId);
  const alreadyAbsent=await this.db.runTransaction(async transaction=>{
   const snapshot=await transaction.get(outingRef);
   if(!snapshot.exists)return true;
   const outing=snapshot.data()!;
   if(outing.crewId!==crewId||outing.createdByUserId!==creatorId)throw new CommandError("permission_denied","Outing creator required.");
   transaction.update(outingRef,{deletionPending:true,updatedAt:FieldValue.serverTimestamp()});
   return false;
  });
  if(!alreadyAbsent)await this.deleteOutingRecords(outingId,commandId);
  return alreadyAbsent;
 }

 async deleteIfCleanupEligible(outingId:string,observedAt:Timestamp,commandId:string):Promise<boolean>{
  const outingRef=this.db.collection("outings").doc(outingId);
  const shouldDelete=await this.db.runTransaction(async transaction=>{
   const snapshot=await transaction.get(outingRef);
   if(!snapshot.exists)return false;
   const scheduledAt=snapshot.data()?.scheduledAt;
   if(!(scheduledAt instanceof Timestamp)||scheduledAt.toMillis()+CLEANUP_DELAY_MILLIS>observedAt.toMillis())return false;
   transaction.update(outingRef,{deletionPending:true,updatedAt:FieldValue.serverTimestamp()});
   return true;
  });
  if(shouldDelete)await this.deleteOutingRecords(outingId,commandId);
  return shouldDelete;
 }

 private async deleteOutingRecords(outingId:string,commandId?:string):Promise<void>{
  await this.terminateAgreementCommands(outingId,commandId);
  await this.terminateChatCommands(outingId);
  await this.deleteOwnedRecords(outingId);
  await this.db.collection("outings").doc(outingId).delete();
  await this.terminateChatCommands(outingId);
  await this.deleteOwnedRecords(outingId);
 }

 private async deleteOwnedRecords(outingId:string):Promise<void>{
  const snapshots=await Promise.all(OUTING_OWNED_COLLECTIONS.map(name=>this.db.collection(name).where("outingId","==",outingId).get()));
  const writer=this.db.bulkWriter();
  for(const snapshot of snapshots)for(const doc of snapshot.docs)writer.delete(doc.ref);
  await writer.close();
 }

 private async terminateAgreementCommands(outingId:string,commandId?:string):Promise<void>{
  const snapshot=await this.db.collection("agreement_commands").where("outingId","==",outingId).get();
  const writer=this.db.bulkWriter();
  for(const doc of snapshot.docs){
   if(doc.id===commandId||(commandId&&doc.data().type==="delete_outing"))continue;
   if(["pending","processing"].includes(doc.data().status))writer.update(doc.ref,{status:"failed",errorCode:"not_found",errorMessage:"Outing was removed.",processedAt:FieldValue.serverTimestamp()});
   else writer.delete(doc.ref);
  }
  await writer.close();
 }

 private async terminateChatCommands(outingId:string):Promise<void>{
  const snapshot=await this.db.collection("chat_commands").where("outingId","==",outingId).get();
  const writer=this.db.bulkWriter();
  for(const doc of snapshot.docs){
   if(["pending","processing"].includes(doc.data().status))writer.update(doc.ref,{status:"failed",errorCode:"not_found",errorMessage:"Chat is unavailable.",payload:FieldValue.delete(),processedAt:FieldValue.serverTimestamp(),deleteAt:Timestamp.now()});
   else writer.delete(doc.ref);
  }
  await writer.close();
 }
}
