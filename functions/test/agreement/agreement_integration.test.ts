import {strict as assert} from "assert";
import {initializeApp,getApps} from "firebase-admin/app";
import {getFirestore,Timestamp} from "firebase-admin/firestore";
import {AgreementTransactions} from "../../src/agreement/agreement_transactions";
const enabled=!!process.env.FIRESTORE_EMULATOR_HOST;
(enabled?describe:describe.skip)("agreement emulator integration",function(){
 this.timeout(15000);before(()=>{if(!getApps().length)initializeApp({projectId:process.env.GCLOUD_PROJECT??"chillgo-test"});});
 async function waitForTerminal(id:string){const ref=getFirestore().collection("agreement_commands").doc(id);for(let i=0;i<200;i++){const data=(await ref.get()).data();if(data?.status==="succeeded"||data?.status==="failed")return data;await new Promise(resolve=>setTimeout(resolve,50));}throw new Error(`Command ${id} did not finish.`);}
 afterEach(async()=>{const db=getFirestore();for(const name of ["agreement_commands","agreement_rounds","agreement_proposals","agreement_votes","agreement_results","outing_participants","crew_memberships","outings","crews"]){const s=await db.collection(name).get();await Promise.all(s.docs.map(d=>d.ref.delete()));}});
 it("processes a command document through the Functions trigger and exposes terminal state",async()=>{const db=getFirestore();await db.collection("crews").doc("c2").set({ownerId:"u"});await db.collection("outings").doc("o2").set({crewId:"c2",createdByUserId:"u",status:"draft",scheduledAt:Timestamp.fromDate(new Date("2030-01-01")),locationText:"Cafe",agreementRoundSequence:0});const ref=db.collection("agreement_commands").doc("triggered");const started=Date.now();await ref.set({type:"open_round",outingId:"o2",crewId:"c2",requestedByUserId:"u",payload:{},status:"pending",createdAt:Timestamp.now()});let data:FirebaseFirestore.DocumentData|undefined;for(let i=0;i<200;i++){data=(await ref.get()).data();if(data?.status==="succeeded"||data?.status==="failed")break;await new Promise(r=>setTimeout(r,50));}assert.equal(data?.status,"succeeded");assert.equal(data?.result?.roundId,"o2_1");assert.ok(Date.now()-started<15000);});
 it("opens a seeded round and duplicate delivery is terminal",async()=>{const db=getFirestore();await db.collection("crews").doc("c").set({ownerId:"u"});await db.collection("outings").doc("o").set({crewId:"c",createdByUserId:"u",status:"draft",scheduledAt:Timestamp.fromDate(new Date("2030-01-01")),locationText:"Cafe",agreementRoundSequence:0});const command={type:"open_round" as const,outingId:"o",crewId:"c",requestedByUserId:"u",payload:{},status:"pending" as const,createdAt:Timestamp.now()};await db.collection("agreement_commands").doc("cmd").set(command);const tx=new AgreementTransactions(db);const result=await tx.process("cmd","event-1",command);assert.equal(result.roundId,"o_1");assert.equal((await db.collection("agreement_proposals").where("roundId","==","o_1").get()).size,2);await assert.rejects(()=>tx.process("cmd","event-2",command));});
 it("deletes creator-owned outings and correlated data in every status",async()=>{
  const db=getFirestore();
  for(const status of ["draft","planning","confirmed","meeting","completed","archived","cancelled"]){
   const outingId=`delete-${status}`;const commandId=`command-${status}`;const createdAt=Timestamp.now();
   await db.collection("crews").doc("delete-crew").set({ownerId:"owner"});
   await db.collection("outings").doc(outingId).set({crewId:"delete-crew",createdByUserId:"creator",status,scheduledAt:Timestamp.fromDate(new Date("2030-01-01")),locationText:"Cafe",agreementRoundSequence:1});
   for(const collection of ["outing_participants","agreement_rounds","agreement_proposals","agreement_votes","agreement_results"]){
    await db.collection(collection).doc(`${outingId}-${collection}`).set({outingId,crewId:"delete-crew"});
   }
   const command={type:"delete_outing" as const,outingId,crewId:"delete-crew",requestedByUserId:"creator",payload:{},status:"pending" as const,createdAt};
   await db.collection("agreement_commands").doc(commandId).set(command);
   const result=await waitForTerminal(commandId);
   assert.equal(result.status,"succeeded",JSON.stringify(result));assert.equal(result.result.alreadyAbsent,false);
   assert.equal((await db.collection("outings").doc(outingId).get()).exists,false);
   for(const collection of ["outing_participants","agreement_rounds","agreement_proposals","agreement_votes","agreement_results"]){
    assert.equal((await db.collection(collection).where("outingId","==",outingId).get()).empty,true);
   }
  }
 });
 it("treats an overlapping authorized delete as an idempotent success",async()=>{
  const db=getFirestore();await db.collection("crews").doc("c").set({ownerId:"owner"});
  await db.collection("outings").doc("o").set({crewId:"c",createdByUserId:"creator",status:"planning"});
  const command={type:"delete_outing" as const,outingId:"o",crewId:"c",requestedByUserId:"creator",payload:{},status:"pending" as const,createdAt:Timestamp.now()};
  await db.collection("agreement_commands").doc("delete-1").set(command);await db.collection("agreement_commands").doc("delete-2").set(command);
  const [first,second]=await Promise.all([waitForTerminal("delete-1"),waitForTerminal("delete-2")]);
  assert.equal(first.status,"succeeded",JSON.stringify(first));assert.equal(second.status,"succeeded",JSON.stringify(second));
  assert.equal([first.result.alreadyAbsent,second.result.alreadyAbsent].filter(Boolean).length,1);
 });
 it("accepts cleanup signals only after twelve elapsed hours",async()=>{
  const db=getFirestore(),now=Date.now();
  await db.collection("crews").doc("cleanup-crew").set({ownerId:"creator"});
  await db.collection("crew_memberships").doc("cleanup-crew_member").set({crewId:"cleanup-crew",userId:"member",role:"member"});
  await db.collection("outings").doc("eligible").set({crewId:"cleanup-crew",createdByUserId:"creator",status:"draft",scheduledAt:Timestamp.fromMillis(now-12*60*60*1000)});
  await db.collection("outings").doc("recent").set({crewId:"cleanup-crew",createdByUserId:"creator",status:"draft",scheduledAt:Timestamp.fromMillis(now-11*60*60*1000)});
  for(const collection of ["outing_participants","agreement_rounds","agreement_proposals","agreement_votes","agreement_results"]){
   await db.collection(collection).doc(`eligible-${collection}`).set({outingId:"eligible",crewId:"cleanup-crew"});
  }
  const command=(outingId:string)=>({type:"expire_outing" as const,outingId,crewId:"cleanup-crew",requestedByUserId:"member",payload:{},status:"pending" as const,createdAt:Timestamp.now()});
  await db.collection("agreement_commands").doc("expire-eligible").set(command("eligible"));
  await db.collection("agreement_commands").doc("expire-recent").set(command("recent"));
  const eligible=await waitForTerminal("expire-eligible"),recent=await waitForTerminal("expire-recent");
  assert.equal(eligible.status,"succeeded",JSON.stringify(eligible));
  assert.equal(recent.status,"failed",JSON.stringify(recent));assert.equal(recent.errorCode,"invalid_outing_state");
  assert.equal((await db.collection("outings").doc("eligible").get()).exists,false);
  assert.equal((await db.collection("outings").doc("recent").get()).exists,true);
  for(const collection of ["outing_participants","agreement_rounds","agreement_proposals","agreement_votes","agreement_results"]){
   assert.equal((await db.collection(collection).where("outingId","==","eligible").get()).empty,true);
  }
 });
});
