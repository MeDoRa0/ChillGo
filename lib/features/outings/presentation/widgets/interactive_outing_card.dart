import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../voting/domain/repositories/agreement_repository.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/entities/outing.dart';
import '../../domain/entities/outing_participant.dart';
import '../../domain/repositories/outing_repository.dart';

class InteractiveOutingCard extends StatelessWidget {
  const InteractiveOutingCard({
    super.key,
    required this.outing,
    required this.outingRepository,
    this.agreementRepository,
    required this.currentUserId,
    this.trailing,
  });

  final Outing outing;
  final OutingRepository outingRepository;
  final AgreementRepository? agreementRepository;
  final String? currentUserId;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => StreamBuilder<OutingDetail?>(
    stream: outingRepository.streamOutingDetail(outing.id),
    builder: (context, snapshot) {
      final detail = snapshot.data;
      final participants = detail?.participants ?? const <OutingParticipant>[];
      return Hero(
        tag: 'outing-card-${outing.id}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('outing-card-${outing.id}'),
            onTap: detail == null ? null : () => _open(context, participants),
            borderRadius: BorderRadius.circular(20),
            child: _CardSurface(
              outing: outing,
              participants: participants,
              trailing: trailing,
            ),
          ),
        ),
      );
    },
  );

  Future<void> _open(
    BuildContext context,
    List<OutingParticipant> participants,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close outing actions',
      barrierColor: const Color(0xFF090812).withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => _FocusedCard(
        outing: outing,
        participants: participants,
        outingRepository: outingRepository,
        agreementRepository: agreementRepository,
        currentUserId: currentUserId,
      ),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.outing,
    required this.participants,
    this.trailing,
  });
  final Outing outing;
  final List<OutingParticipant> participants;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF24213A), Color(0xFF191827)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF50458A)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x337C5CFC),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                outing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ?trailing,
            const Icon(Icons.open_in_full_rounded, color: Color(0xFFB8A7FF)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${outing.locationText}  •  ${_scheduleLabel(outing.scheduledAt)}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 14),
        _AcceptedAvatars(participants: participants),
      ],
    ),
  );
}

class _FocusedCard extends StatefulWidget {
  const _FocusedCard({
    required this.outing,
    required this.participants,
    required this.outingRepository,
    this.agreementRepository,
    required this.currentUserId,
  });
  final Outing outing;
  final List<OutingParticipant> participants;
  final OutingRepository outingRepository;
  final AgreementRepository? agreementRepository;
  final String? currentUserId;

  @override
  State<_FocusedCard> createState() => _FocusedCardState();
}

class _FocusedCardState extends State<_FocusedCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Hero(
          tag: 'outing-card-${widget.outing.id}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF302856), Color(0xFF181725)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF8A71FF), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x667C5CFC), blurRadius: 40),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Text(
                    widget.outing.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.outing.locationText}\n${_scheduleLabel(widget.outing.scheduledAt)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  _AcceptedAvatars(participants: widget.participants),
                  const SizedBox(height: 28),
                  IgnorePointer(
                    ignoring: _busy,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _busy ? 0.45 : 1,
                      child: _isCreator
                          ? _creatorActions()
                          : _participantActions(),
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(color: Color(0xFFB8A7FF)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  bool get _isCreator => widget.currentUserId == widget.outing.createdByUserId;

  AttendanceStatus get _attendanceStatus {
    for (final participant in widget.participants) {
      if (participant.userId == widget.currentUserId) {
        return participant.attendanceStatus;
      }
    }
    return AttendanceStatus.invited;
  }

  Widget _creatorActions() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Expanded(
        child: _ActionIcon(
          label: 'Cancel outing',
          caption: 'Cancel outing',
          icon: Icons.event_busy_rounded,
          color: const Color(0xFFFF6685),
          onPressed: widget.outing.status.isCancellable ? _cancelOuting : null,
        ),
      ),
      Expanded(
        child: _ActionIcon(
          label: 'Change date and location',
          caption: 'Change date and location',
          icon: Icons.edit_calendar_rounded,
          color: const Color(0xFFFFC857),
          onPressed: widget.outing.status.isEditable
              ? _changeDateAndLocation
              : null,
        ),
      ),
    ],
  );

  Widget _participantActions() => switch (_attendanceStatus) {
    AttendanceStatus.accepted => _acceptedParticipantActions(),
    AttendanceStatus.declined => _declinedParticipantActions(),
    AttendanceStatus.invited => _invitedParticipantActions(),
  };

  Widget _acceptedParticipantActions() => Row(
    children: [
      Expanded(child: _declineAction()),
      Expanded(child: _changeDateAndLocationAction()),
    ],
  );

  Widget _declinedParticipantActions() => Row(
    children: [
      Expanded(child: _acceptAction()),
      Expanded(child: _changeDateAndLocationAction()),
    ],
  );

  Widget _invitedParticipantActions() => Row(
    children: [
      Expanded(child: _acceptAction()),
      Expanded(child: _declineAction()),
    ],
  );

  Widget _acceptAction() => _ActionIcon(
    label: 'Accept outing',
    caption: 'Accept outing',
    icon: Icons.check_rounded,
    color: const Color(0xFF48E0A4),
    onPressed: () => _respond(AttendanceStatus.accepted),
  );

  Widget _declineAction() => _ActionIcon(
    label: 'Decline outing',
    caption: 'Decline outing',
    icon: Icons.close_rounded,
    color: const Color(0xFFFF6685),
    onPressed: () => _respond(AttendanceStatus.declined),
  );

  Widget _changeDateAndLocationAction() => _ActionIcon(
    label: 'Change date and location',
    caption: 'Change date and location',
    icon: Icons.edit_calendar_rounded,
    color: const Color(0xFFFFC857),
    onPressed: _proposePlanChange,
  );

  Future<void> _respond(AttendanceStatus status) => _run(
    () => widget.outingRepository.respondToOuting(
      outingId: widget.outing.id,
      attendanceStatus: status,
    ),
  );

  Future<void> _proposePlanChange() async {
    if (widget.agreementRepository == null) {
      _showError('Plan changes are unavailable right now.');
      return;
    }
    final change = await showDialog<_PlanChange>(
      context: context,
      builder: (_) => const _PlanChangeDialog(),
    );
    if (!mounted || change == null) return;
    if (change == _PlanChange.dateAndTime) {
      await _suggestTime();
    } else {
      await _suggestLocation();
    }
  }

  Future<void> _suggestTime() async {
    final repository = widget.agreementRepository;
    if (repository == null) {
      _showError('Time suggestions are unavailable right now.');
      return;
    }
    final now = DateTime.now();
    final initial = widget.outing.scheduledAt.toLocal();
    final defaultLastDate = now.add(const Duration(days: 730));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: now,
      lastDate: initial.isAfter(defaultLastDate) ? initial : defaultLastDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    await _run(
      () => repository.createTimeProposal(
        widget.outing.id,
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      ),
    );
  }

  Future<void> _suggestLocation() async {
    final proposedLocation = await showDialog<String>(
      context: context,
      builder: (_) => const _LocationProposalDialog(),
    );
    if (proposedLocation == null || proposedLocation.isEmpty || !mounted) {
      return;
    }
    await _run(
      () => widget.agreementRepository!.createLocationProposal(
        widget.outing.id,
        proposedLocation,
      ),
    );
  }

  Future<void> _cancelOuting() async {
    final reason = await _requestCancellationReason();
    if (reason == null || reason.isEmpty || !mounted) return;
    await _run(
      () => widget.outingRepository.cancelOuting(
        outingId: widget.outing.id,
        cancelledReason: reason,
      ),
    );
  }

  Future<String?> _requestCancellationReason() async {
    var cancellationReason = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel outing?'),
        content: TextField(
          autofocus: true,
          maxLines: 3,
          onChanged: (reason) => cancellationReason = reason.trim(),
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep outing'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(cancellationReason),
            child: const Text('Cancel outing'),
          ),
        ],
      ),
    );
  }

  void _changeDateAndLocation() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(
      '/outings/${widget.outing.id}/edit?crewId=${Uri.encodeComponent(widget.outing.crewId)}',
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlanChangeDialog extends StatelessWidget {
  const _PlanChangeDialog();

  @override
  Widget build(BuildContext context) => SimpleDialog(
    title: const Text('What would you like to change?'),
    children: [
      SimpleDialogOption(
        onPressed: () => Navigator.of(context).pop(_PlanChange.dateAndTime),
        child: const Text('Date and time'),
      ),
      SimpleDialogOption(
        onPressed: () => Navigator.of(context).pop(_PlanChange.location),
        child: const Text('Location'),
      ),
    ],
  );
}

class _LocationProposalDialog extends StatefulWidget {
  const _LocationProposalDialog();

  @override
  State<_LocationProposalDialog> createState() =>
      _LocationProposalDialogState();
}

class _LocationProposalDialogState extends State<_LocationProposalDialog> {
  String _location = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Suggest a new location'),
    content: TextField(
      autofocus: true,
      maxLength: 120,
      onChanged: (text) => _location = text.trim(),
      decoration: const InputDecoration(labelText: 'Location'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Back'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_location),
        child: const Text('Suggest location'),
      ),
    ],
  );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    child: Tooltip(
      message: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkResponse(
            onTap: onPressed,
            radius: 40,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.7)),
              ),
              child: Icon(icon, size: 38, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _AcceptedAvatars extends StatelessWidget {
  const _AcceptedAvatars({required this.participants});
  final List<OutingParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final accepted = participants
        .where(
          (participant) =>
              participant.attendanceStatus == AttendanceStatus.accepted,
        )
        .take(5)
        .toList();
    if (accepted.isEmpty) {
      return const Text(
        'No one’s locked in yet ✨',
        style: TextStyle(color: Colors.white54),
      );
    }
    return SizedBox(
      height: 38,
      child: Stack(
        children: [
          for (var index = 0; index < accepted.length; index++)
            Positioned(
              left: index * 25,
              child: CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFB8A7FF),
                backgroundImage: accepted[index].avatarUrl?.isNotEmpty == true
                    ? NetworkImage(accepted[index].avatarUrl!)
                    : null,
                child: accepted[index].avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        accepted[index].displayName.characters.first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF161324),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

String _scheduleLabel(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.month}/${local.day} • $hour:${local.minute.toString().padLeft(2, '0')} $period';
}

enum _PlanChange { dateAndTime, location }
