import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../../core/presentation/theme/chillgo_colors.dart';
import '../../../../core/presentation/widgets/responsive_content.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/sunshine_background.dart';
import '../../../authentication/presentation/blocs/auth/auth_bloc.dart';
import '../../../authentication/presentation/blocs/auth/auth_state.dart';
import '../../../authentication/presentation/blocs/auth/auth_event.dart';
import '../blocs/profile/profile_cubit.dart';
import '../utils/image_helper.dart';

part '../widgets/profile_screen/profile_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.credentials?.uid != curr.credentials?.uid,
      builder: (context, authState) {
        final uid = authState.credentials?.uid;

        if (uid == null) {
          return const Scaffold(body: ShimmerListPlaceholder(itemCount: 3));
        }

        return BlocProvider(
          create: (_) => sl<ProfileCubit>()..loadProfile(uid),
          child: _ProfileView(uid: uid),
        );
      },
    );
  }
}
