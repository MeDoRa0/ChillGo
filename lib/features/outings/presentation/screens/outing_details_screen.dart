import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../crews/domain/entities/crew_membership.dart';
import '../../../crews/domain/repositories/crew_repository.dart';
import '../../domain/entities/outing.dart';
import '../../domain/entities/outing_participant.dart';
import '../../domain/repositories/outing_repository.dart';
import '../../domain/services/outing_lifecycle_policy.dart';
import '../cubit/outing_detail/outing_detail_cubit.dart';

class OutingDetailsScreen extends StatelessWidget {
  final String outingId;

  const OutingDetailsScreen({super.key, required this.outingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OutingDetailCubit(outingRepository: sl<OutingRepository>())
            ..load(outingId),
      child: BlocConsumer<OutingDetailCubit, OutingDetailState>(
        listener: (context, state) {
          if (state is OutingDetailLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionMessage!)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Outing details',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                if (state is OutingDetailLoaded &&
                    state.detail.outing.status.isEditable)
                  IconButton(
                    tooltip: 'Edit outing',
                    onPressed: () => context.go(
                      '/outings/$outingId/edit?crewId=${state.detail.outing.crewId}',
                    ),
                    icon: const Icon(Icons.edit),
                  ),
              ],
            ),
            body: _Body(state: state),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OutingDetailState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is OutingDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is OutingDetailError) {
      return _Message((state as OutingDetailError).message);
    }
    if (state is! OutingDetailLoaded) {
      return const _Message('Loading outing.');
    }
    final detail = (state as OutingDetailLoaded).detail;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(outing: detail.outing),
        const SizedBox(height: 16),
        if (detail.outing.cancelledReason?.isNotEmpty == true)
          _InfoPanel(
            title: 'Cancellation reason',
            body: detail.outing.cancelledReason!,
          ),
        const SizedBox(height: 16),
        _Participants(
          outing: detail.outing,
          participants: detail.participants,
        ),
        const SizedBox(height: 16),
        _LifecycleControls(outing: detail.outing),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Outing outing;

  const _Header({required this.outing});

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: outing.title,
      body:
          '${outing.locationText}\n${outing.scheduledAt.toLocal()}\nStatus: ${outing.status.value}'
          '${outing.description?.trim().isNotEmpty == true ? '\n${outing.description}' : ''}',
    );
  }
}

class _Participants extends StatelessWidget {
  final Outing outing;
  final List<OutingParticipant> participants;

  const _Participants({required this.outing, required this.participants});

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: 'Participants',
      body: participants.isEmpty
          ? 'No participants yet.'
          : participants.map((p) => p.displayName).join('\n'),
      child: outing.status.isEditable
          ? StreamBuilder<List<CrewMembership>>(
              stream: sl<CrewRepository>().streamMembers(outing.crewId),
              initialData: const <CrewMembership>[],
              builder: (context, snapshot) {
                final addedIds = participants.map((p) => p.userId).toSet();
                final choices = (snapshot.data ?? const <CrewMembership>[])
                    .where((member) => !addedIds.contains(member.userId))
                    .toList();
                return Wrap(
                  spacing: 8,
                  children: [
                    for (final member in choices)
                      ActionChip(
                        label: Text('Add ${member.displayName}'),
                        onPressed: () => context
                            .read<OutingDetailCubit>()
                            .addParticipant(member.userId),
                      ),
                    for (final participant in participants)
                      ActionChip(
                        label: Text('Remove ${participant.displayName}'),
                        onPressed: () => context
                            .read<OutingDetailCubit>()
                            .removeParticipant(participant.userId),
                      ),
                  ],
                );
              },
            )
          : null,
    );
  }
}

class _LifecycleControls extends StatelessWidget {
  final Outing outing;

  const _LifecycleControls({required this.outing});

  @override
  Widget build(BuildContext context) {
    final nextStatuses = OutingLifecyclePolicy().allowedNextStatuses(
      outing.status,
    );
    if (nextStatuses.isEmpty) {
      return const _InfoPanel(
        title: 'Lifecycle',
        body: 'No further status changes.',
      );
    }
    return _InfoPanel(
      title: 'Lifecycle',
      body: 'Current status: ${outing.status.value}',
      child: Wrap(
        spacing: 8,
        children: [
          for (final status in nextStatuses)
            ActionChip(
              label: Text(status.value),
              onPressed: () =>
                  context.read<OutingDetailCubit>().changeStatus(status),
            ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String body;
  final Widget? child;

  const _InfoPanel({required this.title, required this.body, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Colors.white70)),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String message;

  const _Message(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
