import {strict as assert} from "assert";import {Timestamp} from "firebase-admin/firestore";import {CommandError,parseCommand,terminalAgreementCommandFields} from "../../src/agreement/command_schema";
describe("agreement command schema",()=>{const base={outingId:"o",crewId:"c",requestedByUserId:"u",status:"pending",createdAt:Timestamp.now()};
it("accepts exact open round payload",()=>assert.equal(parseCommand({...base,type:"open_round",payload:{}}).type,"open_round"));
it("rejects unknown payload fields",()=>assert.throws(()=>parseCommand({...base,type:"open_round",payload:{leak:true}}),CommandError));
it("accepts proposal and reopen allowlists",()=>{assert.equal(parseCommand({...base,type:"create_proposal",payload:{category:"location",locationText:"Cafe"}}).type,"create_proposal");assert.equal(parseCommand({...base,type:"reopen_round",payload:{reason:"Changed plans"}}).type,"reopen_round");});
it("accepts only an empty delete outing payload",()=>{
  assert.equal(parseCommand({...base,type:"delete_outing",payload:{}}).type,"delete_outing");
  assert.throws(()=>parseCommand({...base,type:"delete_outing",payload:{reason:"unused"}}),CommandError);
});
it("accepts only an empty expire outing payload",()=>{
  assert.equal(parseCommand({...base,type:"expire_outing",payload:{}}).type,"expire_outing");
  assert.throws(()=>parseCommand({...base,type:"expire_outing",payload:{hours:12}}),CommandError);
});
it("adds a 24 hour purge deadline and scrubs command-only fields",()=>{
  const fields=terminalAgreementCommandFields("succeeded",{roundId:"r"});
  const processedAt=fields.processedAt as Timestamp;
  const purgeAt=fields.purgeAt as Timestamp;
  assert.equal(fields.status,"succeeded");
  assert.equal((fields.result as Record<string,unknown>).roundId,"r");
  assert.ok(Math.abs(purgeAt.toMillis()-processedAt.toMillis()-24*60*60*1000)<1000);
  assert.ok(fields.payload);
  assert.ok(fields.processingEventId);
});
});
