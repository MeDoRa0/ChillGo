import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/notifications/domain/entities/outing_review_notification.dart';
import 'package:chillgo/features/notifications/domain/repositories/outing_review_notification_repository.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/crews/presentation/widgets/crew_card.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/shimmer_loading.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';
import 'sign_out_icon_button.dart';
import 'user_identity_summary.dart';

part 'home_mobile_layout/invitation_notification_button.dart';
part 'home_mobile_layout/notification_bell.dart';
part 'home_mobile_layout/create_crew_dialog.dart';
part 'home_mobile_layout/editorial_intro.dart';

class HomeMobileLayout extends StatelessWidget {
  final String? displayName;
  final String? username;
  final OutingReviewNotificationRepository? outingNotificationRepository;

  const HomeMobileLayout({
    super.key,
    this.displayName,
    this.username,
    this.outingNotificationRepository,
  });

  @override
  Widget build(BuildContext context) {
    final crewRepository = context.read<CrewsListCubit>().crewRepository;

    return Scaffold(
      body: SunshineBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: ChillGoColors.sunshineSoft.withValues(
                alpha: 0.96,
              ),
              foregroundColor: ChillGoColors.ink,
              toolbarHeight: 76,
              floating: false,
              pinned: true,
              titleSpacing: 20,
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ChillGo',
                    style: TextStyle(
                      color: ChillGoColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: ChillGoColors.coral,
                    size: 20,
                  ),
                ],
              ),
              actions: [
                _InvitationNotificationButton(
                  repository: crewRepository,
                  outingNotificationRepository: outingNotificationRepository,
                ),
                const SignOutIconButton(),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: ResponsiveContent(
                includeSafeArea: false,
                maxWidth: 1080,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EditorialIntro(
                        displayName: displayName,
                        username: username,
                      ),
                      const SizedBox(height: 34),
                      _buildYourCrewsSection(context),
                      const SizedBox(height: 56),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourCrewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Crews',
                style: TextStyle(
                  color: ChillGoColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCreateCrewDialog(context),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Create Crew'),
              style: FilledButton.styleFrom(
                backgroundColor: ChillGoColors.coral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        BlocConsumer<CrewsListCubit, CrewsListState>(
          listener: (context, state) {
            if (state is CrewCreateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: ChillGoColors.danger,
                ),
              );
            }
            if (state is CrewCreated &&
                state.failedInviteUsernames.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _inviteFailureMessage(state.failedInviteUsernames),
                  ),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CrewsListLoading) {
              return const ShimmerListSectionPlaceholder(
                itemCount: 2,
                padding: EdgeInsets.zero,
              );
            }

            final crews = switch (state) {
              CrewsListLoaded(:final crews) => crews,
              CrewCreating(:final crews) => crews,
              CrewCreated(:final crews) => crews,
              _ => <Crew>[],
            };

            if (crews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ChillGoColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ChillGoColors.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ChillGoColors.skySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: ChillGoColors.sky,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No crews yet',
                            style: TextStyle(
                              color: ChillGoColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a crew to start coordinating with friends.',
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
              );
            }

            return ResponsiveGrid(
              children: [
                for (final crew in crews)
                  CrewCard(
                    crew: crew,
                    onTap: () => context.push('/crews/${crew.id}'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showCreateCrewDialog(BuildContext context) async {
    final cubit = context.read<CrewsListCubit>();

    await showDialog<void>(
      context: context,
      builder: (_) =>
          _CreateCrewDialog(cubit: cubit, currentUsername: username),
    );
  }

  String _inviteFailureMessage(List<String> failedInviteUsernames) {
    final failedLabels = failedInviteUsernames.map((username) => '@$username');
    return 'Crew created, but invites failed for ${failedLabels.join(', ')}.';
  }
}
