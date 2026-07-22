import 'dart:async';

import '../../domain/entities/outing.dart';
import '../../domain/entities/outing_participant.dart';
import '../../domain/entities/outing_status.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/repositories/outing_repository.dart';
import '../../domain/services/outing_lifecycle_policy.dart';
import '../datasources/firestore_outings_datasource.dart';

class OutingRepositoryImpl implements OutingRepository {
  final FirestoreOutingsDatasource datasource;
  final String Function() currentUid;
  final OutingLifecyclePolicy lifecyclePolicy;
  final Future<void> Function(String outingId, String reason)? agreementCancel;
  final Future<void> Function(String outingId)? agreementDelete;
  final Future<void> Function(String outingId)? agreementExpiryCleanup;

  OutingRepositoryImpl({
    required this.datasource,
    required this.currentUid,
    OutingLifecyclePolicy? lifecyclePolicy,
    this.agreementCancel,
    this.agreementDelete,
    this.agreementExpiryCleanup,
  }) : lifecyclePolicy = lifecyclePolicy ?? OutingLifecyclePolicy();

  @override
  Stream<List<Outing>> streamCrewOutings(String crewId) {
    if (!_isAuthenticated) return const Stream.empty();
    return datasource.streamCrewOutings(crewId);
  }

  @override
  Stream<OutingDetail?> streamOutingDetail(String outingId) {
    if (!_isAuthenticated) return const Stream.empty();
    return _combineOutingAndParticipants(
      datasource.streamOuting(outingId),
      datasource.streamParticipants(outingId),
    );
  }

  @override
  Future<String> createOuting({
    required String crewId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    _validateCrewId(crewId);
    _validateTitle(title);
    _validateDescription(description);
    _validateFutureSchedule(scheduledAt);
    _validateLocation(locationText);
    return datasource.createOuting(
      crewId: crewId,
      creatorUserId: _requireCurrentUid(),
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      locationText: locationText,
    );
  }

  @override
  Future<void> updateOutingDetails({
    required String outingId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    final uid = _requireCurrentUid();
    _validateTitle(title);
    _validateDescription(description);
    _validateFutureSchedule(scheduledAt);
    _validateLocation(locationText);
    final outing = await _requireOuting(outingId);
    await _ensureManager(outing, uid);
    if (!outing.status.isEditable) {
      throw Exception('outing-not-editable');
    }
    if (outing.status != OutingStatus.draft &&
        (scheduledAt.toUtc() != outing.scheduledAt.toUtc() ||
            locationText.trim() != outing.locationText)) {
      throw Exception('agreement-controlled-details');
    }
    await datasource.updateOutingDetails(
      outingId: outingId,
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      locationText: locationText,
    );
  }

  @override
  Future<void> cancelOuting({
    required String outingId,
    required String cancelledReason,
  }) async {
    final uid = _requireCurrentUid();
    final reason = cancelledReason.trim();
    if (reason.length < 3 || reason.length > 200) {
      throw Exception(
        'Cancellation reason must be between 3 and 200 characters.',
      );
    }
    final outing = await _requireOuting(outingId);
    await _ensureManager(outing, uid);
    if (!outing.status.isCancellable) {
      throw Exception('outing-not-cancellable');
    }
    if (outing.status != OutingStatus.draft && agreementCancel != null) {
      await agreementCancel!(outingId, reason);
      return;
    }
    await datasource.cancelOuting(
      outingId: outingId,
      cancelledReason: cancelledReason,
    );
  }

  @override
  Future<void> deleteOuting({required String outingId}) async {
    final uid = _requireCurrentUid();
    final outing = await _requireOuting(outingId);
    if (outing.createdByUserId != uid) {
      throw Exception('outing-creator-required');
    }
    final deleteCommand = agreementDelete;
    if (deleteCommand == null) throw Exception('outing-delete-unavailable');
    await deleteCommand(outingId);
  }

  @override
  Future<void> requestExpiryCleanup({required String outingId}) async {
    _requireCurrentUid();
    final cleanupCommand = agreementExpiryCleanup;
    if (cleanupCommand == null) throw Exception('outing-cleanup-unavailable');
    await cleanupCommand(outingId);
  }

  @override
  Future<void> addParticipant({
    required String outingId,
    required String userId,
  }) async {
    final uid = _requireCurrentUid();
    final outing = await _requireOuting(outingId);
    await _ensureManager(outing, uid);
    if (!outing.status.isEditable) throw Exception('outing-not-editable');
    await datasource.addParticipant(
      outingId: outingId,
      userId: userId,
      addedByUserId: uid,
    );
  }

  @override
  Future<void> acceptOuting({required String outingId}) async {
    await respondToOuting(
      outingId: outingId,
      attendanceStatus: AttendanceStatus.accepted,
    );
  }

  @override
  Future<void> respondToOuting({
    required String outingId,
    required AttendanceStatus attendanceStatus,
  }) async {
    if (attendanceStatus == AttendanceStatus.invited) {
      throw Exception('attendance-response-invalid');
    }
    final uid = _requireCurrentUid();
    final outing = await _requireOuting(outingId);
    if (outing.status == OutingStatus.meeting || outing.status.isHistorical) {
      throw Exception('attendance-response-closed');
    }
    await datasource.respondToOuting(
      outingId: outingId,
      userId: uid,
      attendanceStatus: attendanceStatus,
    );
  }

  @override
  Future<void> removeParticipant({
    required String outingId,
    required String userId,
  }) async {
    final uid = _requireCurrentUid();
    final outing = await _requireOuting(outingId);
    await _ensureManager(outing, uid);
    if (outing.status == OutingStatus.completed ||
        outing.status == OutingStatus.cancelled ||
        outing.status == OutingStatus.archived) {
      throw Exception('participant-removal-blocked');
    }
    await datasource.removeParticipant(outingId: outingId, userId: userId);
  }

  @override
  Future<void> changeLifecycleStatus({
    required String outingId,
    required OutingStatus nextStatus,
  }) async {
    final uid = _requireCurrentUid();
    final outing = await _requireOuting(outingId);
    await _ensureManager(outing, uid);
    if (!lifecyclePolicy.canTransition(outing.status, nextStatus)) {
      throw Exception('invalid-lifecycle-transition');
    }
    await datasource.changeLifecycleStatus(
      outingId: outingId,
      nextStatus: nextStatus,
    );
  }

  Future<Outing> _requireOuting(String outingId) async {
    final outing = await datasource.getOuting(outingId);
    if (outing == null) throw Exception('outing-not-found');
    return outing;
  }

  Future<void> _ensureManager(Outing outing, String uid) async {
    if (outing.createdByUserId == uid) return;
    if (await datasource.isCrewOwner(outing.crewId, uid)) return;
    throw Exception('outing-manager-required');
  }

  void _validateCrewId(String crewId) {
    if (crewId.trim().isEmpty) throw Exception('crew-required');
  }

  void _validateTitle(String title) {
    final value = title.trim();
    if (value.length < 3 || value.length > 80) {
      throw Exception('Title must be between 3 and 80 characters.');
    }
  }

  void _validateDescription(String? description) {
    if (description != null && description.trim().length > 500) {
      throw Exception('Description must be 500 characters or fewer.');
    }
  }

  void _validateFutureSchedule(DateTime scheduledAt) {
    if (!scheduledAt.toUtc().isAfter(DateTime.now().toUtc())) {
      throw Exception('Scheduled date and time must be in the future.');
    }
  }

  void _validateLocation(String locationText) {
    final value = locationText.trim();
    if (value.isEmpty || value.length > 120) {
      throw Exception('Location must be between 1 and 120 characters.');
    }
  }

  String _requireCurrentUid() {
    final uid = currentUid();
    if (uid.isEmpty) throw Exception('auth-user-required');
    return uid;
  }

  bool get _isAuthenticated => currentUid().isNotEmpty;

  Stream<OutingDetail?> _combineOutingAndParticipants(
    Stream<Outing?> outingStream,
    Stream<List<OutingParticipant>> participantsStream,
  ) {
    late StreamSubscription<Outing?> outingSubscription;
    late StreamSubscription<List<OutingParticipant>> participantsSubscription;
    final controller = StreamController<OutingDetail?>();
    Outing? latestOuting;
    List<OutingParticipant>? latestParticipants;
    var hasOuting = false;
    var hasParticipants = false;

    void emitIfReady() {
      if (!hasOuting || !hasParticipants || controller.isClosed) return;
      final outing = latestOuting;
      controller.add(
        outing == null
            ? null
            : OutingDetail(
                outing: outing,
                participants: latestParticipants ?? const [],
              ),
      );
    }

    controller.onListen = () {
      outingSubscription = outingStream.listen((outing) {
        latestOuting = outing;
        hasOuting = true;
        emitIfReady();
      }, onError: controller.addError);
      participantsSubscription = participantsStream.listen((participants) {
        latestParticipants = participants;
        hasParticipants = true;
        emitIfReady();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await outingSubscription.cancel();
      await participantsSubscription.cancel();
    };
    return controller.stream;
  }
}
