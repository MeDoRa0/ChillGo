import '../domain/entities/notification.dart';

String? notificationRoute(NotificationTarget target) => switch (target.type) {
  NotificationTargetType.invitations => '/invitations',
  NotificationTargetType.agreement when target.outingId != null =>
    '/outings/${target.outingId}/agreement',
  NotificationTargetType.liveMeetup when target.outingId != null =>
    '/outings/${target.outingId}/live-meetup',
  _ => null,
};
