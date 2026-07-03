import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chillgo/core/presentation/widgets/responsive_layout.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_state.dart';
import '../widgets/home_desktop_layout.dart';
import '../widgets/home_mobile_layout.dart';
import '../widgets/home_tablet_layout.dart';

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

        return ResponsiveLayout(
          mobileBody: HomeMobileLayout(
            displayName: credentials?.displayName,
            username: credentials?.username,
          ),
          tabletBody: HomeTabletLayout(
            displayName: credentials?.displayName,
            username: credentials?.username,
          ),
          desktopBody: HomeDesktopLayout(
            displayName: credentials?.displayName,
            username: credentials?.username,
          ),
        );
      },
    );
  }
}
