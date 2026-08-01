import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/features/outings/presentation/widgets/interactive_outing_card.dart';
import 'package:chillgo/features/voting/domain/repositories/agreement_repository.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/core/presentation/widgets/app_back_button.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/shimmer_loading.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';
import 'package:go_router/go_router.dart';

part '../widgets/crew_details_screen/crew_details_content.dart';
part '../widgets/crew_details_screen/invite_member_dialog.dart';
part '../widgets/crew_details_screen/crew_header.dart';
part '../widgets/crew_details_screen/member_count_chip.dart';
part '../widgets/crew_details_screen/create_outing_button.dart';
part '../widgets/crew_details_screen/crew_outings.dart';
part '../widgets/crew_details_screen/outing_card.dart';
part '../widgets/crew_details_screen/accepted_avatars.dart';
part '../widgets/crew_details_screen/members_list.dart';
part '../widgets/crew_details_screen/member_avatar_strip.dart';
part '../widgets/crew_details_screen/member_avatar.dart';
part '../widgets/crew_details_screen/invite_member_control.dart';
part '../widgets/crew_details_screen/centered_message.dart';
part '../widgets/crew_details_screen/inline_message.dart';

class CrewDetailsScreen extends StatelessWidget {
  final String crewId;

  const CrewDetailsScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context) {
    final repository = sl<CrewRepository>();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Crew details'),
      ),
      body: SunshineBackground(
        child: ResponsiveContent(
          maxWidth: 960,
          child: StreamBuilder<Crew?>(
            stream: repository.streamCrew(crewId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const ShimmerListPlaceholder(itemCount: 3);
              }

              if (snapshot.hasError) {
                return _CenteredMessage(message: snapshot.error.toString());
              }

              final crew = snapshot.data;
              if (crew == null) {
                return const _CenteredMessage(message: 'Crew not found.');
              }
              final currentUserId =
                  sl<AuthRepository>().currentCredentials?.uid;
              final canInviteMembers = currentUserId == crew.ownerId;

              return _CrewDetailsContent(
                crew: crew,
                repository: repository,
                canInviteMembers: canInviteMembers,
              );
            },
          ),
        ),
      ),
    );
  }
}
