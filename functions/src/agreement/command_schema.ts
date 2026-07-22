import {Timestamp} from "firebase-admin/firestore";

export const commandTypes = ["open_round","create_proposal","preview_confirmation","confirm_round","reopen_round","cancel_outing","delete_outing","expire_outing"] as const;
export type CommandType = typeof commandTypes[number];
export type CommandStatus = "pending"|"processing"|"succeeded"|"failed";
export const errorCodes = ["unauthenticated","permission_denied","not_found","invalid_command","invalid_outing_state",
  "attendance_response_required","proposal_limit_reached","expired_time_proposal","insufficient_votes","tie_selection_required",
  "invalid_tie_selection","confirmation_state_changed","already_processed","internal_error"] as const;
export type ErrorCode = typeof errorCodes[number];
export interface Command {type:CommandType;outingId:string;crewId:string;requestedByUserId:string;
  payload:Record<string,unknown>;status:CommandStatus;createdAt:Timestamp}
const keys:Record<CommandType,readonly string[]>={open_round:[],create_proposal:["category","timeValue","locationText"],
  preview_confirmation:[],confirm_round:["selectedTimeProposalId","selectedLocationProposalId"],reopen_round:["reason"],cancel_outing:["reason"],delete_outing:[],expire_outing:[]};
export function parseCommand(raw:unknown):Command {
  if(!raw||typeof raw!=="object")throw new CommandError("invalid_command","Invalid command.");
  const value=raw as Record<string,unknown>; if(!commandTypes.includes(value.type as CommandType)||value.status!=="pending")
    throw new CommandError("invalid_command","Invalid command.");
  for(const field of ["outingId","crewId","requestedByUserId"])if(typeof value[field]!=="string"||!(value[field] as string).trim())
    throw new CommandError("invalid_command","Invalid command.");
  const payload=value.payload;if(!payload||typeof payload!=="object"||Array.isArray(payload))throw new CommandError("invalid_command","Invalid payload.");
  if(Object.keys(payload).some(k=>!keys[value.type as CommandType].includes(k)))throw new CommandError("invalid_command","Unknown payload field.");
  const type=value.type as CommandType;const p=payload as Record<string,unknown>;
  if((type==="open_round"||type==="preview_confirmation"||type==="delete_outing"||type==="expire_outing")&&Object.keys(p).length!==0)throw new CommandError("invalid_command","Payload must be empty.");
  if(type==="create_proposal"&&!((p.category==="time"&&p.timeValue instanceof Timestamp&&!('locationText' in p))||(p.category==="location"&&typeof p.locationText==="string"&&!('timeValue' in p))))throw new CommandError("invalid_command","Invalid proposal payload.");
  if((type==="reopen_round"||type==="cancel_outing")&&(typeof p.reason!=="string"||p.reason.trim().length<3||p.reason.trim().length>200))throw new CommandError("invalid_command","Invalid reason.");
  if(type==="confirm_round"&&Object.values(p).some(v=>typeof v!=="string"||!v))throw new CommandError("invalid_command","Invalid tie selection.");
  return value as unknown as Command;
}
export class CommandError extends Error {constructor(public readonly code:ErrorCode,message:string){super(message);}}
