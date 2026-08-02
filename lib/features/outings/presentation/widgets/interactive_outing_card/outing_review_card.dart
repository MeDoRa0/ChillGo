part of '../interactive_outing_card.dart';

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
    final confirmed = await confirmOutingCancellation(context);
    if (!confirmed || !mounted) return;
    await _run(
      () => widget.outingRepository.cancelOuting(
        outingId: widget.outing.id,
        cancelledReason: defaultOutingCancellationReason,
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
