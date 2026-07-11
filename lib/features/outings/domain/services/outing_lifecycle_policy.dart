import '../entities/outing_status.dart';

class OutingLifecyclePolicy {
  static const Map<OutingStatus, Set<OutingStatus>> _allowedTransitions = {
    OutingStatus.draft: {OutingStatus.planning, OutingStatus.cancelled},
    OutingStatus.planning: {OutingStatus.confirmed, OutingStatus.cancelled},
    OutingStatus.confirmed: {OutingStatus.meeting, OutingStatus.cancelled},
    OutingStatus.meeting: {OutingStatus.completed},
    OutingStatus.completed: {OutingStatus.archived},
    OutingStatus.archived: {},
    OutingStatus.cancelled: {},
  };

  bool canTransition(OutingStatus from, OutingStatus to) {
    return _allowedTransitions[from]?.contains(to) ?? false;
  }

  List<OutingStatus> allowedNextStatuses(OutingStatus from) {
    return List.unmodifiable(_allowedTransitions[from] ?? const {});
  }
}
