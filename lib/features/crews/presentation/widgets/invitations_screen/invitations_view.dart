part of '../../screens/invitations_screen.dart';

class _InvitationsView extends StatelessWidget {
  const _InvitationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Notifications'),
      ),
      body: SunshineBackground(
        child: ResponsiveContent(
          maxWidth: 840,
          child: BlocConsumer<InvitationsCubit, InvitationsState>(
            listener: (context, state) {
              if (state is InvitationActionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ChillGoColors.danger,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is InvitationsLoading ||
                  state is InvitationActionInProgress) {
                return const ShimmerListPlaceholder(itemCount: 3);
              }

              if (state is InvitationsError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: ChillGoColors.inkMuted),
                  ),
                );
              }

              final invitations = state is InvitationsLoaded
                  ? state.invitations
                  : <CrewInvitation>[];

              if (invitations.isEmpty) return const _EmptyNotifications();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _NotificationSectionTitle('Crew invitations'),
                  const SizedBox(height: 10),
                  for (final invitation in invitations) ...[
                    _InvitationCard(invitation: invitation),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
