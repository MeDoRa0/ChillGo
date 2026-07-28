import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/live_meetup_repository.dart';
import '../../domain/services/trusted_clock.dart';
import '../models/live_meetup_command_model.dart';
import '../models/live_meetup_status_model.dart';
import '../models/live_location_model.dart';
import '../../domain/entities/live_location.dart';
import '../models/meetup_point_model.dart';
import '../../domain/entities/meetup_point.dart';

class LiveMeetupAccessSnapshot {
  const LiveMeetupAccessSnapshot({
    required this.outing,
    required this.participant,
    required this.isCrewMember,
  });
  final Map<String, dynamic> outing;
  final Map<String, dynamic> participant;
  final bool isCrewMember;
}

class FirestoreLiveMeetupDatasource {
  FirestoreLiveMeetupDatasource({
    required this.firestore,
    required this.currentUid,
    required this.clock,
    this.commandTimeout = const Duration(seconds: 20),
  });

  final FirebaseFirestore firestore;
  final String Function() currentUid;
  final TrustedClock clock;
  final Duration commandTimeout;

  Stream<Map<String, dynamic>> watchOuting(String outingId) =>
      firestore.collection('outings').doc(outingId).snapshots().map((snapshot) {
        if (!snapshot.exists) throw const LiveMeetupAccessDenied();
        return snapshot.data()!;
      });

  Stream<List<Map<String, dynamic>>> watchAcceptedRoster(String outingId) =>
      firestore
          .collection('outing_participants')
          .where('outingId', isEqualTo: outingId)
          .where('attendanceStatus', isEqualTo: 'accepted')
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((document) => {...document.data(), 'id': document.id})
                .toList(growable: false),
          );

  Stream<List<LiveMeetupStatusModel>> watchStatuses(String outingId) =>
      firestore
          .collection('live_meetup_statuses')
          .where('outingId', isEqualTo: outingId)
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) => LiveMeetupStatusModel.fromMap(document.data()),
                )
                .toList(growable: false),
          );

  Stream<List<LiveLocation>> watchLocations(String outingId) => firestore
      .collection('live_locations')
      .where('outingId', isEqualTo: outingId)
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => LiveLocationModel.fromMap(document.data()))
            .toList(growable: false),
      );

  Stream<MeetupPoint?> watchMeetupPoint(String outingId) => firestore
      .collection('meetup_points')
      .doc(outingId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.exists ? MeetupPointModel.fromMap(snapshot.data()!) : null,
      );

  Stream<LiveMeetupAccessSnapshot> watchAccess(String outingId) {
    final uid = currentUid();
    if (uid.isEmpty) {
      return Stream.error(const LiveMeetupAuthenticationFailure());
    }
    late StreamController<LiveMeetupAccessSnapshot> controller;
    StreamSubscription? outingSubscription;
    StreamSubscription? membershipSubscription;
    StreamSubscription? participantSubscription;
    Map<String, dynamic>? outing;
    Map<String, dynamic>? participant;
    bool? isCrewMember;

    void emit() {
      if (outing != null && participant != null && isCrewMember != null) {
        controller.add(
          LiveMeetupAccessSnapshot(
            outing: outing!,
            participant: participant!,
            isCrewMember: isCrewMember!,
          ),
        );
      }
    }

    controller = StreamController<LiveMeetupAccessSnapshot>(
      onListen: () {
        outingSubscription = firestore
            .collection('outings')
            .doc(outingId)
            .snapshots()
            .listen((snapshot) async {
              if (!snapshot.exists) {
                controller.addError(const LiveMeetupAccessDenied());
                return;
              }
              outing = snapshot.data()!;
              final crewId = outing!['crewId'];
              if (crewId is! String) {
                controller.addError(const LiveMeetupAccessDenied());
                return;
              }
              await membershipSubscription?.cancel();
              membershipSubscription = firestore
                  .collection('crew_memberships')
                  .doc('${crewId}_$uid')
                  .snapshots()
                  .listen((snapshot) {
                    isCrewMember =
                        snapshot.exists &&
                        snapshot.data()?['liveMeetupCleanupPending'] != true;
                    emit();
                  }, onError: controller.addError);
            }, onError: controller.addError);
        participantSubscription = firestore
            .collection('outing_participants')
            .doc('${outingId}_$uid')
            .snapshots()
            .listen((snapshot) {
              if (!snapshot.exists) {
                controller.addError(const LiveMeetupAccessDenied());
                return;
              }
              participant = snapshot.data()!;
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await outingSubscription?.cancel();
        await membershipSubscription?.cancel();
        await participantSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<LiveMeetupCommandResult> submit({
    required String outingId,
    required String type,
    required Map<String, Object?> payload,
  }) async {
    final uid = currentUid();
    if (uid.isEmpty) throw const LiveMeetupAuthenticationFailure();
    if (!clock.isEstablished) await clock.establish();
    final ref = firestore.collection('live_meetup_commands').doc();
    final pendingLifetime = type == 'publish_location'
        ? const Duration(minutes: 2)
        : const Duration(hours: 1);
    try {
      await firestore.runTransaction((transaction) async {
        final outing = await transaction.get(
          firestore.collection('outings').doc(outingId),
        );
        final crewId = outing.data()?['crewId'];
        if (!outing.exists || crewId is! String || crewId.isEmpty) {
          throw const LiveMeetupAccessDenied();
        }
        transaction.set(
          ref,
          LiveMeetupCommandModel.pendingMap(
            type: type,
            outingId: outingId,
            crewId: crewId,
            userId: uid,
            payload: payload,
            purgeAt: clock.now.add(pendingLifetime),
          ),
        );
      });
      final result = await ref
          .snapshots()
          .where((snapshot) => snapshot.exists)
          .map(
            (snapshot) =>
                LiveMeetupCommandModel.fromMap(snapshot.data()!, snapshot.id),
          )
          .firstWhere((result) => result.isTerminal)
          .timeout(commandTimeout);
      return result;
    } on LiveMeetupFailure {
      rethrow;
    } on TimeoutException {
      throw const LiveMeetupServiceFailure();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const LiveMeetupAccessDenied();
      }
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        throw const LiveMeetupOfflineFailure();
      }
      throw const LiveMeetupServiceFailure();
    }
  }
}
