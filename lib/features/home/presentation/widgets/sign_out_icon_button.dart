import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/theme/chillgo_colors.dart';
import '../../../authentication/presentation/blocs/auth/auth_bloc.dart';
import '../../../authentication/presentation/blocs/auth/auth_event.dart';

class SignOutIconButton extends StatelessWidget {
  const SignOutIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      onPressed: () {
        context.read<AuthBloc>().add(AuthLogoutRequested());
      },
      icon: const Icon(Icons.logout),
      color: ChillGoColors.ink,
    );
  }
}
