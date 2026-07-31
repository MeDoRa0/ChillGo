import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../../core/presentation/theme/chillgo_colors.dart';
import '../../../../core/presentation/widgets/responsive_content.dart';
import '../../../../core/presentation/widgets/sunshine_background.dart';
import '../../../notifications/domain/entities/outing_review_notification.dart';
import '../../../notifications/domain/repositories/outing_review_notification_repository.dart';
import '../blocs/invitations/invitations_cubit.dart';
import '../../domain/entities/crew_invitation.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvitationsCubit>()..loadInvitations(),
      child: _InvitationsView(notificationRepository: sl()),
    );
  }
}

class _InvitationsView extends StatelessWidget {
  const _InvitationsView({required this.notificationRepository});

  final OutingReviewNotificationRepository notificationRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Notifications'),
      ),
      body: SunshineBackground(
        child: ResponsiveContent(
          maxWidth: 840,
          child: BlocConsumer<InvitationsCubit, InvitationsState>(
            listener: (context, state) {
              if (state is InvitationActionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ChillGoColors.danger,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is InvitationsLoading ||
                  state is InvitationActionInProgress) {
                return const Center(
                  child: CircularProgressIndicator(color: ChillGoColors.coral),
                );
              }

              if (state is InvitationsError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: ChillGoColors.inkMuted),
                  ),
                );
              }

              final invitations = state is InvitationsLoaded
                  ? state.invitations
                  : <CrewInvitation>[];

              return StreamBuilder<List<OutingReviewNotification>>(
                stream: notificationRepository.watchNotifications(),
                builder: (context, notificationSnapshot) {
                  final notifications = notificationSnapshot.data ?? const [];
                  if (invitations.isEmpty && notifications.isEmpty) {
                    return const _EmptyNotifications();
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (notifications.isNotEmpty) ...[
                        const _NotificationSectionTitle('Outing updates'),
                        const SizedBox(height: 10),
                        for (final notification in notifications) ...[
                          _OutingReviewNotificationCard(
                            notification: notification,
                            repository: notificationRepository,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                      if (invitations.isNotEmpty) ...[
                        const _NotificationSectionTitle('Crew invitations'),
                        const SizedBox(height: 10),
                        for (final invitation in invitations) ...[
                          _InvitationCard(invitation: invitation),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: ChillGoColors.sunshineSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: ChillGoColors.coral,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No new notifications',
            style: TextStyle(
              color: ChillGoColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New crew invitations and outings will appear here.',
            style: TextStyle(color: ChillGoColors.inkMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationSectionTitle extends StatelessWidget {
  const _NotificationSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ChillGoColors.ink,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );
}

class _OutingReviewNotificationCard extends StatelessWidget {
  const _OutingReviewNotificationCard({
    required this.notification,
    required this.repository,
  });

  final OutingReviewNotification notification;
  final OutingReviewNotificationRepository repository;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('outing-notification-${notification.id}'),
      onTap: () => _openReview(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ChillGoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? ChillGoColors.outline
                : ChillGoColors.coral,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available, color: ChillGoColors.coral),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${notification.creatorDisplayName} created a new outing',
                    style: const TextStyle(
                      color: ChillGoColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.outingTitle,
                    style: const TextStyle(color: ChillGoColors.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to review',
                    style: TextStyle(
                      color: ChillGoColors.coral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ChillGoColors.inkMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openReview(BuildContext context) async {
    try {
      await repository.markRead(notification.id);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark the notification as read.'),
        ),
      );
      return;
    }
    if (context.mounted) {
      context.push('/outings/${notification.outingId}/review');
    }
  }
}

class _InvitationCard extends StatelessWidget {
  final CrewInvitation invitation;
  const _InvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ChillGoColors.coral.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups,
                  color: ChillGoColors.coral,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.crewName,
                      style: const TextStyle(
                        color: ChillGoColors.ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invited by ${invitation.invitedByDisplayName} (@${invitation.invitedByUsername})',
                      style: TextStyle(
                        color: ChillGoColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context
                      .read<InvitationsCubit>()
                      .rejectInvitation(invitation.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChillGoColors.danger,
                    side: const BorderSide(color: ChillGoColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => context
                      .read<InvitationsCubit>()
                      .acceptInvitation(invitation.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChillGoColors.leaf,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
