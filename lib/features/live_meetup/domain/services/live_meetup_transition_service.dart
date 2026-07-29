import 'package:equatable/equatable.dart';

import '../../../outings/domain/entities/outing_status.dart';
import '../repositories/live_meetup_repository.dart';

enum LiveMeetupTransitionStatus { pending, processing, succeeded, failed }

class LiveMeetupTransitionResult extends Equatable {
  const LiveMeetupTransitionResult({
    required this.transitionId,
    required this.status,
    this.failure,
  });

  final String transitionId;
  final LiveMeetupTransitionStatus status;
  final LiveMeetupFailure? failure;

  bool get isTerminal =>
      status == LiveMeetupTransitionStatus.succeeded ||
      status == LiveMeetupTransitionStatus.failed;

  @override
  List<Object?> get props => [transitionId, status, failure];
}

abstract interface class LiveMeetupTransitionService {
  Future<LiveMeetupTransitionResult> endOuting(
    String outingId,
    OutingStatus targetStatus,
  );

  Future<LiveMeetupTransitionResult> declineAttendance(String outingId);

  Future<LiveMeetupTransitionResult> removeParticipant(
    String outingId,
    String userId,
  );

  Future<LiveMeetupTransitionResult> removeMembership(
    String crewId,
    String userId,
  );

  Future<LiveMeetupTransitionResult> deleteCrew(String crewId);
}
