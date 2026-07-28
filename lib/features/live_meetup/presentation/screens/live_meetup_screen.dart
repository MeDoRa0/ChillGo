import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/live_meetup/live_meetup_cubit.dart';
import '../widgets/attendee_status_summary.dart';
import '../widgets/status_selector.dart';
import '../cubit/location_sharing/location_sharing_cubit.dart';
import '../widgets/location_sharing_control.dart';
import '../../domain/services/map_provider.dart';
import '../../domain/services/trusted_clock.dart';
import '../cubit/meetup_point_editor/meetup_point_editor_cubit.dart';
import '../widgets/meetup_point_editor.dart';
import '../widgets/meetup_map.dart';
import '../widgets/meetup_text_alternative.dart';
import '../../domain/entities/live_meetup_snapshot.dart';

class LiveMeetupScreen extends StatelessWidget {
  const LiveMeetupScreen({super.key, required this.outingId});
  final String outingId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Live Meetup'),
    ),
    body: BlocListener<LiveMeetupCubit, LiveMeetupState>(
      listenWhen: (previous, current) =>
          previous.status != LiveMeetupViewStatus.accessLost &&
          current.status == LiveMeetupViewStatus.accessLost,
      listener: (context, state) {
        context.read<LocationSharingCubit>().accessLost();
        context.read<MeetupPointEditorCubit>().accessLost();
      },
      child: BlocBuilder<LiveMeetupCubit, LiveMeetupState>(
        builder: (context, state) {
          if (state.status == LiveMeetupViewStatus.initial ||
              state.status == LiveMeetupViewStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LiveMeetupViewStatus.accessLost) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Live Meetup is no longer available.'),
              ),
            );
          }
          if (state.snapshot == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.failure?.message ?? 'Live Meetup failed to load.'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () =>
                        context.read<LiveMeetupCubit>().watch(outingId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final snapshot = state.snapshot!;
          final uid = sl.isRegistered<AuthRepository>()
              ? sl<AuthRepository>().currentCredentials?.uid
              : null;
          final current = snapshot.attendees
              .where((attendee) => attendee.userId == uid)
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                snapshot.locationText,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StatusSelector(
                selected: current?.status,
                mutationState: state.statusMutation,
                onSelected: context.read<LiveMeetupCubit>().setStatus,
              ),
              const SizedBox(height: 16),
              BlocBuilder<LocationSharingCubit, LocationSharingState>(
                builder: (context, sharingState) => LocationSharingControl(
                  outingId: outingId,
                  state: sharingState,
                  onStart: () =>
                      context.read<LocationSharingCubit>().start(outingId),
                  onTransfer: context
                      .read<LocationSharingCubit>()
                      .confirmTransfer,
                  onStop: context.read<LocationSharingCubit>().stop,
                ),
              ),
              if (state.failure != null) ...[
                const SizedBox(height: 8),
                Text(state.failure!.message),
              ],
              const SizedBox(height: 24),
              BlocBuilder<MeetupPointEditorCubit, MeetupPointEditorState>(
                builder: (context, editorState) => MeetupPointEditor(
                  state: editorState,
                  onSearch: context.read<MeetupPointEditorCubit>().search,
                  onSelect: context.read<MeetupPointEditorCubit>().select,
                  onConfirm: context.read<MeetupPointEditorCubit>().confirm,
                  onSave: context.read<MeetupPointEditorCubit>().save,
                ),
              ),
              const SizedBox(height: 16),
              _MapSurface(snapshot: snapshot),
              const SizedBox(height: 8),
              MeetupTextAlternative(
                snapshot: snapshot,
                trustedNow: sl.isRegistered<TrustedClock>()
                    ? sl<TrustedClock>().now
                    : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              ),
              const SizedBox(height: 24),
              AttendeeStatusSummary(attendees: snapshot.attendees),
            ],
          );
        },
      ),
    ),
  );
}

class _MapSurface extends StatelessWidget {
  const _MapSurface({required this.snapshot});
  final LiveMeetupSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<MapProvider>() || !sl<MapProvider>().isConfigured) {
      return _unavailableMap();
    }
    return MeetupMap(snapshot: snapshot);
  }

  Widget _unavailableMap() => const SizedBox(
    height: 96,
    child: Center(
      child: Text('Google Maps is unavailable. Location details remain below.'),
    ),
  );
}
