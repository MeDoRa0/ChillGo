import 'package:flutter/material.dart';
import 'package:chillgo/core/presentation/widgets/shimmer_loading.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/cubit/chat_summary/chat_summary_cubit.dart';
import '../../../chat/presentation/widgets/chat_unread_badge.dart';
import '../../../live_meetup/domain/repositories/live_meetup_repository.dart';
import '../../../voting/domain/repositories/agreement_repository.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/entities/outing.dart';
import '../../domain/entities/outing_status.dart';
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
    builder: _buildCard,
  );

  Widget _buildCard(
    BuildContext context,
    AsyncSnapshot<OutingDetail?> snapshot,
  ) {
    final detail = snapshot.data;
    final participants = detail?.participants ?? const <OutingParticipant>[];
    final canOpenChat =
        participants.any(
          (participant) => participant.userId == currentUserId,
        ) &&
        sl.isRegistered<ChatRepository>();
    final canOpenLiveMeetup =
        outing.status == OutingStatus.meeting &&
        participants.any(
          (participant) =>
              participant.userId == currentUserId &&
              participant.attendanceStatus == AttendanceStatus.accepted,
        ) &&
        sl.isRegistered<LiveMeetupRepository>();
    final actionButtonSpace = canOpenChat || canOpenLiveMeetup
        ? SizedBox(width: canOpenChat && canOpenLiveMeetup ? 112 : 48)
        : null;
    return Stack(
      children: [
        _outingHero(context, detail, participants, actionButtonSpace),
        if (canOpenChat || canOpenLiveMeetup)
          Positioned.fill(
            child: _CardActionOverlay(
              outingId: outing.id,
              onChat: canOpenChat
                  ? () =>
                        GoRouter.of(context).push('/outings/${outing.id}/chat')
                  : null,
              onLiveMeetup: canOpenLiveMeetup
                  ? () => GoRouter.of(
                      context,
                    ).push('/outings/${outing.id}/live-meetup')
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _outingHero(
    BuildContext context,
    OutingDetail? detail,
    List<OutingParticipant> participants,
    Widget? actionButtonSpace,
  ) => Hero(
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
          actionButtonSpace: actionButtonSpace,
          trailing: trailing,
        ),
      ),
    ),
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
      pageBuilder: (_, _, _) => OutingReviewCard(
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
    required this.actionButtonSpace,
    this.trailing,
  });
  final Outing outing;
  final List<OutingParticipant> participants;
  final Widget? actionButtonSpace;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dateRailWidth = (constraints.maxWidth * 0.24)
          .clamp(84.0, 112.0)
          .toDouble();
      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: _cardDecoration,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: dateRailWidth,
              child: _DateRail(scheduledAt: outing.scheduledAt),
            ),
            Padding(
              padding: EdgeInsets.only(left: dateRailWidth),
              child: _CardContent(
                outing: outing,
                participants: participants,
                actionButtonSpace: actionButtonSpace,
                trailing: trailing,
              ),
            ),
          ],
        ),
      );
    },
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: ChillGoColors.sunshineSoft,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: ChillGoColors.outline),
    boxShadow: const [
      BoxShadow(color: Color(0x186D3A72), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}

class _DateRail extends StatelessWidget {
  const _DateRail({required this.scheduledAt});

  final DateTime scheduledAt;

  @override
  Widget build(BuildContext context) {
    final localDate = scheduledAt.toLocal();
    return Container(
      key: const Key('outing-date-rail'),
      color: ChillGoColors.coralSoft.withValues(alpha: 0.58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localDate.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _monthLabel(localDate.month),
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: ChillGoColors.coral),
          ),
          Text(
            _timeLabel(localDate),
            maxLines: 1,
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.outing,
    required this.participants,
    required this.actionButtonSpace,
    required this.trailing,
  });

  final Outing outing;
  final List<OutingParticipant> participants;
  final Widget? actionButtonSpace;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HostHeader(
          creator: _creatorParticipant(outing, participants),
          status: outing.status,
          trailing: trailing,
        ),
        const SizedBox(height: 10),
        _OutingTitle(title: outing.title),
        const SizedBox(height: 10),
        _LocationPanel(location: outing.locationText),
        const SizedBox(height: 12),
        _CardFooter(
          participants: participants,
          actionButtonSpace: actionButtonSpace,
        ),
      ],
    ),
  );
}

class _HostHeader extends StatelessWidget {
  const _HostHeader({
    required this.creator,
    required this.status,
    required this.trailing,
  });

  final OutingParticipant? creator;
  final OutingStatus status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _CreatorAvatar(creator: creator),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          creator == null ? 'Crew outing' : '${creator!.displayName}’s outing',
          key: const Key('outing-host'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ChillGoColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      ?trailing,
      const SizedBox(width: 8),
      _StatusPill(status: status),
    ],
  );
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.creator});

  final OutingParticipant? creator;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 17,
    backgroundColor: ChillGoColors.coralSoft,
    backgroundImage: creator?.avatarUrl?.isNotEmpty == true
        ? NetworkImage(creator!.avatarUrl!)
        : null,
    child: creator == null
        ? const Icon(Icons.group_outlined, size: 18, color: ChillGoColors.ink)
        : creator!.avatarUrl?.isNotEmpty == true
        ? null
        : Text(
            creator!.displayName.characters.first.toUpperCase(),
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OutingStatus status;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('outing-status'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: ChillGoColors.coral,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      _statusLabel(status),
      style: const TextStyle(
        color: ChillGoColors.surface,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    ),
  );
}

class _OutingTitle extends StatelessWidget {
  const _OutingTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: ChillGoColors.ink,
      fontSize: 20,
      height: 1.12,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _LocationPanel extends StatelessWidget {
  const _LocationPanel({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('outing-location-panel'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: ChillGoColors.surface.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ChillGoColors.outline),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 23,
          color: ChillGoColors.coral,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.participants,
    required this.actionButtonSpace,
  });

  final List<OutingParticipant> participants;
  final Widget? actionButtonSpace;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Expanded(child: _AcceptedAvatars(participants: participants)),
        ?actionButtonSpace,
      ],
    ),
  );
}

class _CardActionOverlay extends StatelessWidget {
  const _CardActionOverlay({
    required this.outingId,
    required this.onChat,
    required this.onLiveMeetup,
  });

  final String outingId;
  final VoidCallback? onChat;
  final VoidCallback? onLiveMeetup;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (onChat != null)
        Positioned(
          right: onLiveMeetup == null ? 14 : 70,
          bottom: 12,
          child: _CardChatButton(outingId: outingId, onPressed: onChat!),
        ),
      if (onLiveMeetup != null)
        Positioned(
          right: 14,
          bottom: 12,
          child: _LiveMeetupButton(onPressed: onLiveMeetup!),
        ),
    ],
  );
}

class _CardChatButton extends StatelessWidget {
  const _CardChatButton({required this.outingId, required this.onPressed});

  final String outingId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ChatSummaryCubit>()..watch(outingId),
    child: BlocBuilder<ChatSummaryCubit, ChatSummaryState>(
      builder: (context, state) {
        final summary = state is ChatSummaryReady ? state.summary : null;
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ChillGoColors.sunshineSoft,
            shape: BoxShape.circle,
            border: Border.all(color: ChillGoColors.plum, width: 1.5),
          ),
          child: IconButton(
            key: const Key('outing-chat-entry'),
            tooltip: 'Outing chat',
            onPressed: onPressed,
            icon: ChatUnreadBadge(count: summary?.unreadCount ?? 0),
            color: ChillGoColors.plum,
            iconSize: 21,
          ),
        );
      },
    ),
  );
}

class _LiveMeetupButton extends StatelessWidget {
  const _LiveMeetupButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: const BoxDecoration(
      color: ChillGoColors.coral,
      shape: BoxShape.circle,
    ),
    child: IconButton(
      key: const Key('live-meetup-entry'),
      tooltip: 'Live Meetup',
      onPressed: onPressed,
      icon: const Icon(Icons.near_me_rounded),
      color: ChillGoColors.surface,
      iconSize: 21,
    ),
  );
}

class OutingReviewCard extends StatefulWidget {
  const OutingReviewCard({
    super.key,
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
  State<OutingReviewCard> createState() => _OutingReviewCardState();
}

class _OutingReviewCardState extends State<OutingReviewCard> {
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
                color: ChillGoColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: ChillGoColors.outline, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x336D3A72), blurRadius: 40),
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
                        color: ChillGoColors.inkMuted,
                      ),
                    ),
                  ),
                  Text(
                    widget.outing.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ChillGoColors.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.outing.locationText}\n${_scheduleLabel(widget.outing.scheduledAt)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ChillGoColors.inkMuted,
                      height: 1.5,
                    ),
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
                    const ShimmerBox(
                      height: 4,
                      borderRadius: 2,
                      semanticLabel: 'Updating outing',
                    ),
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
          color: ChillGoColors.coral,
          onPressed: widget.outing.status.isCancellable ? _cancelOuting : null,
        ),
      ),
      Expanded(
        child: _ActionIcon(
          label: 'Change date and location',
          caption: 'Change date and location',
          icon: Icons.edit_calendar_rounded,
          color: ChillGoColors.sunshine,
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
    color: ChillGoColors.leaf,
    onPressed: () => _respond(AttendanceStatus.accepted),
  );

  Widget _declineAction() => _ActionIcon(
    label: 'Decline outing',
    caption: 'Decline outing',
    icon: Icons.close_rounded,
    color: ChillGoColors.coral,
    onPressed: () => _respond(AttendanceStatus.declined),
  );

  Widget _changeDateAndLocationAction() => _ActionIcon(
    label: 'Change date and location',
    caption: 'Change date and location',
    icon: Icons.edit_calendar_rounded,
    color: ChillGoColors.sunshine,
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
            style: const TextStyle(color: ChillGoColors.inkMuted, fontSize: 11),
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
        .take(3)
        .toList();
    if (accepted.isEmpty) {
      return const Text(
        'No one’s locked in yet ✨',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: ChillGoColors.inkMuted),
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
                backgroundColor: ChillGoColors.coralSoft,
                backgroundImage: accepted[index].avatarUrl?.isNotEmpty == true
                    ? NetworkImage(accepted[index].avatarUrl!)
                    : null,
                child: accepted[index].avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        accepted[index].displayName.characters.first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: ChillGoColors.ink,
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

OutingParticipant? _creatorParticipant(
  Outing outing,
  List<OutingParticipant> participants,
) {
  for (final participant in participants) {
    if (participant.isCreatorParticipant ||
        participant.userId == outing.createdByUserId) {
      return participant;
    }
  }
  return null;
}

String _monthLabel(int month) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][month - 1];

String _statusLabel(OutingStatus status) => switch (status) {
  OutingStatus.draft => 'DRAFT',
  OutingStatus.planning => 'PLANNING',
  OutingStatus.confirmed => 'UPCOMING',
  OutingStatus.meeting => 'LIVE',
  OutingStatus.completed => 'COMPLETED',
  OutingStatus.archived => 'ARCHIVED',
  OutingStatus.cancelled => 'CANCELLED',
};

String _timeLabel(DateTime localDate) {
  final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
  final period = localDate.hour < 12 ? 'AM' : 'PM';
  return '$hour:${localDate.minute.toString().padLeft(2, '0')} $period';
}

String _scheduleLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day} • ${_timeLabel(local)}';
}

enum _PlanChange { dateAndTime, location }
