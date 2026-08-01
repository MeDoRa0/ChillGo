import 'dart:async';

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

part 'interactive_outing_card/card_surface.dart';
part 'interactive_outing_card/date_rail.dart';
part 'interactive_outing_card/card_content.dart';
part 'interactive_outing_card/host_header.dart';
part 'interactive_outing_card/creator_avatar.dart';
part 'interactive_outing_card/status_pill.dart';
part 'interactive_outing_card/outing_title.dart';
part 'interactive_outing_card/location_panel.dart';
part 'interactive_outing_card/starting_soon_banner.dart';
part 'interactive_outing_card/card_footer.dart';
part 'interactive_outing_card/card_action_overlay.dart';
part 'interactive_outing_card/card_chat_button.dart';
part 'interactive_outing_card/live_meetup_button.dart';
part 'interactive_outing_card/outing_review_card.dart';
part 'interactive_outing_card/plan_change_dialog.dart';
part 'interactive_outing_card/location_proposal_dialog.dart';
part 'interactive_outing_card/action_icon.dart';
part 'interactive_outing_card/accepted_avatars.dart';

class InteractiveOutingCard extends StatefulWidget {
  const InteractiveOutingCard({
    super.key,
    required this.outing,
    required this.outingRepository,
    this.agreementRepository,
    required this.currentUserId,
    this.trailing,
    @visibleForTesting this.now = DateTime.now,
  });

  final Outing outing;
  final OutingRepository outingRepository;
  final AgreementRepository? agreementRepository;
  final String? currentUserId;
  final Widget? trailing;
  final DateTime Function() now;

  @override
  State<InteractiveOutingCard> createState() => _InteractiveOutingCardState();
}

class _InteractiveOutingCardState extends State<InteractiveOutingCard> {
  static const _startingSoonWindow = Duration(hours: 1);

  Timer? _clockTimer;
  late DateTime _now;
  late Stream<OutingDetail?> _detailStream;

  @override
  void initState() {
    super.initState();
    _now = widget.now();
    _detailStream = widget.outingRepository.streamOutingDetail(
      widget.outing.id,
    );
    _scheduleClockRefresh();
  }

  @override
  void didUpdateWidget(covariant InteractiveOutingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.outingRepository, widget.outingRepository) ||
        oldWidget.outing.id != widget.outing.id) {
      _detailStream = widget.outingRepository.streamOutingDetail(
        widget.outing.id,
      );
    }
    if (oldWidget.outing.scheduledAt != widget.outing.scheduledAt ||
        oldWidget.outing.status != widget.outing.status) {
      _now = widget.now();
      _scheduleClockRefresh();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  bool get _isStartingSoon {
    final outing = widget.outing;
    if (outing.status.isHistorical || outing.status == OutingStatus.meeting) {
      return false;
    }
    final windowStart = outing.scheduledAt.subtract(_startingSoonWindow);
    return !_now.isBefore(windowStart) && _now.isBefore(outing.scheduledAt);
  }

  int get _minutesUntilStart {
    final milliseconds = widget.outing.scheduledAt
        .difference(_now)
        .inMilliseconds;
    return (milliseconds / Duration.millisecondsPerMinute)
        .ceil()
        .clamp(1, 60)
        .toInt();
  }

  DateTime? get _nextClockRefresh {
    final outing = widget.outing;
    if (outing.status.isHistorical || outing.status == OutingStatus.meeting) {
      return null;
    }

    final windowStart = outing.scheduledAt.subtract(_startingSoonWindow);
    if (_now.isBefore(windowStart)) {
      return windowStart;
    }
    if (!_now.isBefore(outing.scheduledAt)) return null;

    final minutes = _minutesUntilStart;
    return minutes == 1
        ? outing.scheduledAt
        : outing.scheduledAt.subtract(Duration(minutes: minutes - 1));
  }

  void _scheduleClockRefresh() {
    _clockTimer?.cancel();
    final nextRefresh = _nextClockRefresh;
    if (nextRefresh == null) return;

    final delay =
        nextRefresh.difference(_now) + const Duration(milliseconds: 1);
    _clockTimer = Timer(delay, _refreshClock);
  }

  void _refreshClock() {
    if (!mounted) return;
    setState(() => _now = widget.now());
    _scheduleClockRefresh();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<OutingDetail?>(stream: _detailStream, builder: _buildCard);

  Widget _buildCard(
    BuildContext context,
    AsyncSnapshot<OutingDetail?> snapshot,
  ) {
    final detail = snapshot.data;
    final participants = detail?.participants ?? const <OutingParticipant>[];
    final canOpenChat =
        participants.any(
          (participant) => participant.userId == widget.currentUserId,
        ) &&
        sl.isRegistered<ChatRepository>();
    final canOpenLiveMeetup =
        widget.outing.status == OutingStatus.meeting &&
        participants.any(
          (participant) =>
              participant.userId == widget.currentUserId &&
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
              outingId: widget.outing.id,
              onChat: canOpenChat
                  ? () => GoRouter.of(
                      context,
                    ).push('/outings/${widget.outing.id}/chat')
                  : null,
              onLiveMeetup: canOpenLiveMeetup
                  ? () => GoRouter.of(
                      context,
                    ).push('/outings/${widget.outing.id}/live-meetup')
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
    tag: 'outing-card-${widget.outing.id}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('outing-card-${widget.outing.id}'),
        onTap: detail == null ? null : () => _open(context, participants),
        borderRadius: BorderRadius.circular(20),
        child: _CardSurface(
          outing: widget.outing,
          participants: participants,
          actionButtonSpace: actionButtonSpace,
          trailing: widget.trailing,
          isStartingSoon: _isStartingSoon,
          minutesUntilStart: _minutesUntilStart,
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
        outing: widget.outing,
        participants: participants,
        outingRepository: widget.outingRepository,
        agreementRepository: widget.agreementRepository,
        currentUserId: widget.currentUserId,
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

enum _PlanChange { dateAndTime, location }
