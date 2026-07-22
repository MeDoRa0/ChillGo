import {Timestamp} from "firebase-admin/firestore";
export interface Proposal {id:string;category:"time"|"location";timeValue?:Timestamp}
export interface Vote {userId:string;category:"time"|"location";proposalId:string}
export interface Tally {totals:Map<string,number>;leaders:string[];participatingVoters:number}
export function tally(category:"time"|"location", proposals:Proposal[],votes:Vote[],eligible:Set<string>,now:Date):Tally {
  const valid=new Set(proposals.filter(p=>p.category===category&&(category!=="time"||!!p.timeValue&&p.timeValue.toDate()>now)).map(p=>p.id));
  const totals=new Map<string,number>();const voters=new Set<string>();
  for(const vote of votes)if(vote.category===category&&eligible.has(vote.userId)&&valid.has(vote.proposalId)){
    totals.set(vote.proposalId,(totals.get(vote.proposalId)??0)+1);voters.add(vote.userId);}
  const high=Math.max(0,...totals.values());return {totals,leaders:[...totals].filter(([,v])=>v===high&&high>0).map(([id])=>id),participatingVoters:voters.size};
}
