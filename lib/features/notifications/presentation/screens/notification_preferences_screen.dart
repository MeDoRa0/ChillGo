import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/device_alert.dart';
import '../cubit/notification_preferences/notification_preferences_cubit.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification preferences')),
      body:
          BlocConsumer<
            NotificationPreferencesCubit,
            NotificationPreferencesState
          >(
            listenWhen: (previous, current) =>
                previous.message != current.message && current.message != null,
            listener: (context, state) => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!))),
            builder: (context, state) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              final cubit = context.read<NotificationPreferencesCubit>();
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DeviceAlertsCard(
                    capability: state.capability,
                    onEnable: cubit.requestDeviceAlerts,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Optional alerts',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Voting updates'),
                    subtitle: const Text('New time or place proposals.'),
                    value: state.preferences.votingUpdatesEnabled,
                    onChanged: state.saving ? null : cubit.setVotingUpdates,
                  ),
                  SwitchListTile(
                    title: const Text('Outing changes'),
                    subtitle: const Text(
                      'Changes to the agreed outing details.',
                    ),
                    value: state.preferences.outingChangesEnabled,
                    onChanged: state.saving ? null : cubit.setOutingChanges,
                  ),
                  SwitchListTile(
                    title: const Text('Arrival alerts'),
                    subtitle: const Text('When an accepted attendee arrives.'),
                    value: state.preferences.arrivalAlertsEnabled,
                    onChanged: state.saving ? null : cubit.setArrivalAlerts,
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Required coordination alerts'),
                    subtitle: Text(
                      'Invitations and agreement confirmations stay enabled because '
                      'they require or materially affect participant action.',
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _DeviceAlertsCard extends StatelessWidget {
  const _DeviceAlertsCard({required this.capability, required this.onEnable});

  final DeviceAlertCapability capability;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (capability) {
      DeviceAlertCapability.supported => (
        'Device alerts are enabled',
        'ChillGo can alert you while the app is in the background.',
      ),
      DeviceAlertCapability.notDetermined => (
        'Enable device alerts',
        'Permission is requested only when you choose to enable alerts.',
      ),
      DeviceAlertCapability.denied => (
        'Device alerts are blocked',
        'Enable notifications for ChillGo in system settings. The in-app '
            'notification center still works.',
      ),
      DeviceAlertCapability.unsupported => (
        'Device alerts are unavailable',
        'This platform uses the in-app notification center.',
      ),
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text(title),
        subtitle: Text(body),
        trailing: capability == DeviceAlertCapability.notDetermined
            ? FilledButton(onPressed: onEnable, child: const Text('Enable'))
            : null,
      ),
    );
  }
}
