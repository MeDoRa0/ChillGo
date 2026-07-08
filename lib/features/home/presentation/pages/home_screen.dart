import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_state.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import '../widgets/home_mobile_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.credentials?.displayName !=
              current.credentials?.displayName ||
          previous.credentials?.username != current.credentials?.username,
      builder: (context, authState) {
        final credentials = authState.credentials;

        return BlocProvider<CrewsListCubit>(
          create: (_) => sl<CrewsListCubit>()..loadCrews(),
          child: HomeMobileLayout(
            displayName: credentials?.displayName,
            username: credentials?.username,
          ),
        );
      },
    );
  }
}
