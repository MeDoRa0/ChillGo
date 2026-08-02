import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_state.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/notifications/domain/repositories/notification_repository.dart';
import 'package:chillgo/features/profile/presentation/blocs/profile/profile_cubit.dart';
import '../widgets/home_mobile_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.credentials?.uid != current.credentials?.uid ||
          previous.credentials?.displayName !=
              current.credentials?.displayName ||
          previous.credentials?.username != current.credentials?.username ||
          previous.credentials?.photoUrl != current.credentials?.photoUrl,
      builder: (context, authState) {
        final credentials = authState.credentials;
        final uid = credentials?.uid;

        return MultiBlocProvider(
          providers: [
            BlocProvider<CrewsListCubit>(
              create: (_) => sl<CrewsListCubit>()..loadCrews(),
            ),
            if (uid != null)
              BlocProvider<ProfileCubit>(
                create: (_) => sl<ProfileCubit>()..loadProfile(uid),
              ),
          ],
          child: uid == null
              ? _HomeContent(credentials: credentials)
              : BlocConsumer<ProfileCubit, ProfileState>(
                  listener: (context, profileState) {
                    if (profileState is ProfileFailure) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(profileState.error)),
                        );
                    }
                  },
                  builder: (context, profileState) {
                    final profile = profileState is ProfileLoaded
                        ? profileState.profile
                        : null;
                    return _HomeContent(
                      credentials: credentials,
                      displayName: profile?.displayName,
                      username: profile?.username,
                      avatarUrl: profile?.avatarUrl,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final UserCredentials? credentials;
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  const _HomeContent({
    required this.credentials,
    this.displayName,
    this.username,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return HomeMobileLayout(
      displayName: displayName ?? credentials?.displayName,
      username: username ?? credentials?.username,
      avatarUrl: avatarUrl ?? credentials?.photoUrl,
      notificationRepository: sl<NotificationRepository>(),
    );
  }
}
