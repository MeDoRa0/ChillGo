import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/agreement_command.dart';

const _typeValues = <AgreementCommandType, String>{
  AgreementCommandType.openRound: 'open_round',
  AgreementCommandType.createProposal: 'create_proposal',
  AgreementCommandType.previewConfirmation: 'preview_confirmation',
  AgreementCommandType.confirmRound: 'confirm_round',
  AgreementCommandType.reopenRound: 'reopen_round',
  AgreementCommandType.cancelOuting: 'cancel_outing',
  AgreementCommandType.deleteOuting: 'delete_outing',
  AgreementCommandType.expireOuting: 'expire_outing',
};

class AgreementCommandModel extends AgreementCommand {
  const AgreementCommandModel({
    required super.id,
    required super.type,
    required super.status,
    required super.outingId,
    required super.crewId,
    required super.requestedByUserId,
    required super.payload,
    required super.createdAt,
    super.result,
    super.errorCode,
    super.errorMessage,
  });
  factory AgreementCommandModel.fromMap(Map<String, dynamic> m, String id) =>
      AgreementCommandModel(
        id: id,
        type: _typeValues.entries.firstWhere((e) => e.value == m['type']).key,
        status: AgreementCommandStatus.values.firstWhere(
          (e) => e.name == m['status'],
        ),
        outingId: m['outingId'] as String,
        crewId: m['crewId'] as String,
        requestedByUserId: m['requestedByUserId'] as String,
        payload: Map<String, Object?>.from(m['payload'] as Map),
        createdAt: readFirestoreTimestamp(m['createdAt'])!,
        result: m['result'] == null
            ? null
            : Map<String, Object?>.from(m['result'] as Map),
        errorCode: m['errorCode'] as String?,
        errorMessage: m['errorMessage'] as String?,
      );
  Map<String, dynamic> toRequestMap() => {
    'type': _typeValues[type],
    'outingId': outingId,
    'crewId': crewId,
    'requestedByUserId': requestedByUserId,
    'payload': payload,
    'status': 'pending',
    'createdAt': writeFirestoreTimestamp(createdAt),
  };
}
