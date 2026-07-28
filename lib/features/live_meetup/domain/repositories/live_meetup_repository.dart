import 'package:equatable/equatable.dart';

import '../entities/device_location_sample.dart';
import '../entities/geo_coordinate.dart';
import '../entities/live_location_session.dart';
import '../entities/live_meetup_snapshot.dart';
import '../entities/live_meetup_status.dart';
import '../entities/meetup_point.dart';

sealed class LiveMeetupFailure extends Equatable implements Exception {
  const LiveMeetupFailure(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}

class LiveMeetupAuthenticationFailure extends LiveMeetupFailure {
  const LiveMeetupAuthenticationFailure()
    : super('Sign in before trying again.');
}

class LiveMeetupAccessDenied extends LiveMeetupFailure {
  const LiveMeetupAccessDenied() : super('Live Meetup is unavailable.');
}

class LiveMeetupOfflineFailure extends LiveMeetupFailure {
  const LiveMeetupOfflineFailure()
    : super('Connection failed. Nothing was queued; retry manually.');
}

class LiveMeetupValidationFailure extends LiveMeetupFailure {
  const LiveMeetupValidationFailure([super.message = 'Invalid meetup update.']);
}

class LiveMeetupTransferRequired extends LiveMeetupFailure {
  const LiveMeetupTransferRequired()
    : super('Confirm transferring sharing from the other device.');
}

class LiveMeetupSessionEnded extends LiveMeetupFailure {
  const LiveMeetupSessionEnded()
    : super('This sharing session is no longer active.');
}

class LiveMeetupServiceFailure extends LiveMeetupFailure {
  const LiveMeetupServiceFailure()
    : super('Live Meetup is temporarily unavailable.');
}

enum LiveMeetupCommandStatus {
  pending,
  processing,
  succeeded,
  superseded,
  failed,
}

class LiveMeetupCommandResult extends Equatable {
  const LiveMeetupCommandResult({
    required this.commandId,
    required this.status,
    this.acceptedAt,
    this.expiresAt,
    this.failure,
  });
  final String commandId;
  final LiveMeetupCommandStatus status;
  final DateTime? acceptedAt;
  final DateTime? expiresAt;
  final LiveMeetupFailure? failure;
  bool get isTerminal =>
      status == LiveMeetupCommandStatus.succeeded ||
      status == LiveMeetupCommandStatus.superseded ||
      status == LiveMeetupCommandStatus.failed;
  @override
  List<Object?> get props => [
    commandId,
    status,
    acceptedAt,
    expiresAt,
    failure,
  ];
}

class MeetupPointPreparation extends Equatable {
  const MeetupPointPreparation({required this.locationText, this.point});
  final String locationText;
  final MeetupPoint? point;
  @override
  List<Object?> get props => [locationText, point];
}

abstract interface class LiveMeetupRepository {
  Stream<LiveMeetupSnapshot> watchMeetup(String outingId);
  Stream<MeetupPointPreparation> watchMeetupPointPreparation(String outingId);
  Future<LiveMeetupCommandResult> setStatus(
    String outingId,
    LiveMeetupStatus status,
  );
  Future<LiveMeetupCommandResult> startSharing(
    String outingId,
    LiveLocationSession session, {
    required bool transferExisting,
  });
  Future<LiveMeetupCommandResult> publishLocation(
    String outingId,
    LiveLocationSession session,
    DeviceLocationSample sample,
  );
  Future<LiveMeetupCommandResult> stopSharing(
    String outingId,
    LiveLocationSession session,
  );
  Future<LiveMeetupCommandResult> setMeetupPoint(
    String outingId,
    GeoCoordinate coordinate,
    String confirmedLocationText,
  );
}
