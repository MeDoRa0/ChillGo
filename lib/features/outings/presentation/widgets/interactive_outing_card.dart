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
part 'interactive_outing_card/card_footer.dart';
part 'interactive_outing_card/card_action_overlay.dart';
part 'interactive_outing_card/card_chat_button.dart';
part 'interactive_outing_card/live_meetup_button.dart';
part 'interactive_outing_card/outing_review_card.dart';
part 'interactive_outing_card/plan_change_dialog.dart';
part 'interactive_outing_card/location_proposal_dialog.dart';
part 'interactive_outing_card/action_icon.dart';
part 'interactive_outing_card/accepted_avatars.dart';

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

enum _PlanChange { dateAndTime, location }
