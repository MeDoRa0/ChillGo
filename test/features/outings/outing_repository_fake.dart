import 'dart:async';

import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';

class FakeOutingRepository implements OutingRepository {
  final String createdOutingId;
  final List<Outing> outings;
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

  FakeOutingRepository({
    this.createdOutingId = 'outing-id',
    this.outings = const [],
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

  static OutingParticipant sampleParticipant() {
    return OutingParticipant(
      id: 'outing-1_user-1',
      outingId: 'outing-1',
      crewId: 'crew-1',
      userId: 'user-1',
      username: 'bob',
      displayName: 'Bob',
      addedByUserId: 'user-1',
      addedAt: DateTime.utc(2026, 1, 1),
      isCreatorParticipant: true,
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
