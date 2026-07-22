enum AgreementCommandType {
  openRound,
  createProposal,
  previewConfirmation,
  confirmRound,
  reopenRound,
  cancelOuting,
  deleteOuting,
  expireOuting,
}

enum AgreementCommandStatus { pending, processing, succeeded, failed }

class AgreementCommand {
  const AgreementCommand({
    required this.id,
    required this.type,
    required this.status,
    required this.outingId,
    required this.crewId,
    required this.requestedByUserId,
    required this.payload,
    required this.createdAt,
    this.result,
    this.errorCode,
    this.errorMessage,
  });
  final String id, outingId, crewId, requestedByUserId;
  final AgreementCommandType type;
  final AgreementCommandStatus status;
  final Map<String, Object?> payload;
  final Map<String, Object?>? result;
  final String? errorCode, errorMessage;
  final DateTime createdAt;
  bool get isTerminal =>
      status == AgreementCommandStatus.succeeded ||
      status == AgreementCommandStatus.failed;
}

sealed class AgreementFailure implements Exception {
  const AgreementFailure(this.message);
  final String message;
}

class AgreementAccessDenied extends AgreementFailure {
  const AgreementAccessDenied(super.message);
}

class AgreementStateConflict extends AgreementFailure {
  const AgreementStateConflict(super.message);
}

class AgreementValidationFailure extends AgreementFailure {
  const AgreementValidationFailure(super.message);
}

class AgreementProposalLimitReached extends AgreementFailure {
  const AgreementProposalLimitReached(super.message);
}

class AgreementConfirmationChanged extends AgreementFailure {
  const AgreementConfirmationChanged(super.message);
}

class AgreementNetworkFailure extends AgreementFailure {
  const AgreementNetworkFailure(super.message);
}

class AgreementServiceFailure extends AgreementFailure {
  const AgreementServiceFailure(super.message);
}
