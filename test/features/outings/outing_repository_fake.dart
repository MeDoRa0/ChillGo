import 'dart:async';

import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';

class FakeOutingRepository implements OutingRepository {
  final String createdOutingId;
  final List<Outing> outings;
  final Stream<List<Outing>>? crewOutingsStream;
  final OutingDetail? detail;
  final Object? error;
  OutingStatus? changedStatus;
  String? streamedCrewId;
  String? streamedOutingId;
  String? addedParticipantOutingId;
  String? addedParticipantUserId;
  String? removedParticipantOutingId;
  String? removedParticipantUserId;
  String? cancelledOutingId;
  String? cancelledReason;
  String? deletedOutingId;
  final List<String> expiryCleanupOutingIds = [];
  String? changedStatusOutingId;
  String? createdCrewId;
  String? createdTitle;
  String? createdDescription;
  DateTime? createdScheduledAt;
  String? createdLocationText;
  String? updatedOutingId;
  String? updatedTitle;
  String? updatedDescription;
  DateTime? updatedScheduledAt;
  String? updatedLocationText;
  String? acceptedOutingId;
  AttendanceStatus? attendanceStatus;

  FakeOutingRepository({
    this.createdOutingId = 'outing-id',
    this.outings = const [],
    this.crewOutingsStream,
    this.detail,
    this.error,
  });

  static Outing sampleOuting({
    String id = 'outing-1',
    String title = 'Friday Cafe',
    OutingStatus status = OutingStatus.draft,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return Outing(
      id: id,
      crewId: 'crew-1',
      title: title,
      scheduledAt: DateTime.utc(2030, 1, 1),
      locationText: 'City Center Cafe',
      status: status,
      createdByUserId: 'user-1',
      createdAt: now,
      updatedAt: now,
    );
  }

  static OutingParticipant sampleParticipant({
    String userId = 'user-1',
    bool isCreatorParticipant = true,
    AttendanceStatus? attendanceStatus,
  }) {
    return OutingParticipant(
      id: 'outing-1_$userId',
      outingId: 'outing-1',
      crewId: 'crew-1',
      userId: userId,
      username: 'bob',
      displayName: 'Bob',
      addedByUserId: 'user-1',
      addedAt: DateTime.utc(2026, 1, 1),
      isCreatorParticipant: isCreatorParticipant,
      attendanceStatus: attendanceStatus,
    );
  }

  static OutingDetail sampleDetail() {
    return OutingDetail(
      outing: sampleOuting(),
      participants: [sampleParticipant()],
    );
  }

  @override
  Future<void> addParticipant({
    required String outingId,
    required String userId,
  }) async {
    _throwIfNeeded();
    addedParticipantOutingId = outingId;
    addedParticipantUserId = userId;
  }

  @override
  Future<void> acceptOuting({required String outingId}) async {
    _throwIfNeeded();
    acceptedOutingId = outingId;
  }

  @override
  Future<void> respondToOuting({
    required String outingId,
    required AttendanceStatus attendanceStatus,
  }) async {
    _throwIfNeeded();
    acceptedOutingId = outingId;
    this.attendanceStatus = attendanceStatus;
  }

  @override
  Future<void> cancelOuting({
    required String outingId,
    required String cancelledReason,
  }) async {
    _throwIfNeeded();
    cancelledOutingId = outingId;
    this.cancelledReason = cancelledReason;
  }

  @override
  Future<void> deleteOuting({required String outingId}) async {
    _throwIfNeeded();
    deletedOutingId = outingId;
  }

  @override
  Future<void> requestExpiryCleanup({required String outingId}) async {
    _throwIfNeeded();
    expiryCleanupOutingIds.add(outingId);
  }

  @override
  Future<void> changeLifecycleStatus({
    required String outingId,
    required OutingStatus nextStatus,
  }) async {
    _throwIfNeeded();
    changedStatusOutingId = outingId;
    changedStatus = nextStatus;
  }

  @override
  Future<String> createOuting({
    required String crewId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    _throwIfNeeded();
    createdCrewId = crewId;
    createdTitle = title;
    createdDescription = description;
    createdScheduledAt = scheduledAt;
    createdLocationText = locationText;
    return createdOutingId;
  }

  @override
  Future<void> removeParticipant({
    required String outingId,
    required String userId,
  }) async {
    _throwIfNeeded();
    removedParticipantOutingId = outingId;
    removedParticipantUserId = userId;
  }

  @override
  Stream<List<Outing>> streamCrewOutings(String crewId) {
    streamedCrewId = crewId;
    final value = error;
    if (value != null) return Stream<List<Outing>>.error(value);
    if (crewOutingsStream != null) return crewOutingsStream!;
    return Stream.value(outings);
  }

  @override
  Stream<OutingDetail?> streamOutingDetail(String outingId) {
    streamedOutingId = outingId;
    final value = error;
    if (value != null) return Stream<OutingDetail?>.error(value);
    return Stream.value(detail);
  }

  @override
  Future<void> updateOutingDetails({
    required String outingId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    _throwIfNeeded();
    updatedOutingId = outingId;
    updatedTitle = title;
    updatedDescription = description;
    updatedScheduledAt = scheduledAt;
    updatedLocationText = locationText;
  }

  void _throwIfNeeded() {
    final value = error;
    if (value != null) throw value;
  }
}
