import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../../core/presentation/theme/chillgo_colors.dart';
import '../../../../core/presentation/widgets/responsive_content.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/sunshine_background.dart';
import '../blocs/invitations/invitations_cubit.dart';
import '../../domain/entities/crew_invitation.dart';

part '../widgets/invitations_screen/invitations_view.dart';
part '../widgets/invitations_screen/empty_notifications.dart';
part '../widgets/invitations_screen/notification_section_title.dart';
part '../widgets/invitations_screen/invitation_card.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvitationsCubit>()..loadInvitations(),
      child: const _InvitationsView(),
    );
  }
}
