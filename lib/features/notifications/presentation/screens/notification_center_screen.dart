import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/notification.dart';
import '../cubit/notification_center/notification_center_cubit.dart';
import '../notification_navigation.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Notification preferences',
            onPressed: () => context.push('/notifications/preferences'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: BlocConsumer<NotificationCenterCubit, NotificationCenterState>(
        listenWhen: (previous, current) =>
            previous.message != current.message &&
            current.message != null &&
            current.status != NotificationCenterStatus.failure,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message!))),
        builder: (context, state) => switch (state.status) {
          NotificationCenterStatus.initial ||
          NotificationCenterStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          NotificationCenterStatus.failure => _CenterMessage(
            icon: Icons.notifications_off_outlined,
            message: state.message ?? 'Notifications are unavailable.',
            actionLabel: 'Try again',
            onAction: context.read<NotificationCenterCubit>().watch,
          ),
          NotificationCenterStatus.loaded when state.items.isEmpty =>
            const _CenterMessage(
              icon: Icons.notifications_none,
              message: 'No notifications yet.',
            ),
          NotificationCenterStatus.loaded => RefreshIndicator(
            onRefresh: context.read<NotificationCenterCubit>().watch,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount:
                  state.items.length + (state.nextCursor != null ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: state.loadingMore
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: context
                                  .read<NotificationCenterCubit>()
                                  .loadMore,
                              child: const Text('Load older notifications'),
                            ),
                    ),
                  );
                }
                return _NotificationTile(notification: state.items[index]);
              },
            ),
          ),
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${notification.isRead ? 'Read' : 'Unread'} notification. '
          '${notification.display.title}. ${notification.display.body}',
      button: true,
      child: ListTile(
        key: ValueKey('notification-${notification.id}'),
        leading: Icon(
          _icon(notification.category),
          color: notification.isRead
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          notification.display.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
        subtitle: Text(notification.display.body),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, size: 10, semanticLabel: 'Unread'),
        onTap: () => _open(context),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await context.read<NotificationCenterCubit>().open(
      notification.id,
    );
    if (!context.mounted) return;
    if (!result.isOpened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_unavailableMessage(result.unavailableReason))),
      );
      return;
    }
    final route = notificationRoute(result.target!);
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This notification is unavailable.')),
      );
      return;
    }
    context.push(route);
  }

  IconData _icon(NotificationCategory category) => switch (category) {
    NotificationCategory.crewInvitation ||
    NotificationCategory.outingInvitation => Icons.mail_outline,
    NotificationCategory.votingUpdate => Icons.how_to_vote_outlined,
    NotificationCategory.agreementConfirmed ||
    NotificationCategory.agreementReopened => Icons.event_available_outlined,
    NotificationCategory.outingChanged => Icons.edit_calendar_outlined,
    NotificationCategory.attendeeArrived => Icons.person_pin_circle_outlined,
  };

  String _unavailableMessage(NotificationUnavailableReason? reason) =>
      switch (reason) {
        NotificationUnavailableReason.signInRequired =>
          'Sign in to open this notification.',
        NotificationUnavailableReason.expired =>
          'This notification has expired.',
        NotificationUnavailableReason.unavailable =>
          'This notification is no longer available.',
        _ => 'This notification could not be opened right now.',
      };
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
