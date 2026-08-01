import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/shimmer_loading.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_state.dart';

import '../blocs/onboarding/onboarding_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final clean = value.trim();
    if (clean.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    if (clean.length < 3 || clean.length > 20) {
      return 'Must be between 3 and 20 characters';
    }
    final regExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regExp.hasMatch(clean)) {
      return 'Only letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    if (value.trim().length > 50) {
      return 'Must be under 50 characters';
    }
    return null;
  }

  void _submitForm(String uid, OnboardingCubit cubit) {
    if (_formKey.currentState!.validate()) {
      cubit.submitOnboarding(
        uid: uid,
        username: _usernameController.text.trim().toLowerCase(),
        displayName: _displayNameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final uid = authState.credentials?.uid;
        if (kDebugMode) {
          debugPrint(
            '[OnboardingScreen] authState=${authState.status}, uid=$uid',
          );
        }

        if (uid == null) {
          if (kDebugMode) {
            debugPrint('[OnboardingScreen] uid is null, showing loader');
          }
          return const Scaffold(body: ShimmerListPlaceholder(itemCount: 3));
        }

        return BlocProvider(
          create: (_) => sl<OnboardingCubit>(),
          child: Scaffold(
            body: SunshineBackground(
              child: BlocConsumer<OnboardingCubit, OnboardingState>(
                listener: (context, state) {
                  if (state is OnboardingSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile setup complete!')),
                    );
                  }
                  if (state is OnboardingFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: ChillGoColors.danger,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<OnboardingCubit>();
                  final isLoading = state is OnboardingLoading;

                  return ResponsiveContent(
                    maxWidth: 580,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: _buildProfileForm(uid, cubit, isLoading),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileForm(String uid, OnboardingCubit cubit, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.face_rounded,
              size: 72,
              color: ChillGoColors.coral,
            ),
            const SizedBox(height: 20),
            const Text(
              'Make it yours',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: ChillGoColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how your crew will recognize you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: ChillGoColors.inkMuted),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _usernameController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@ ',
                prefixStyle: TextStyle(
                  color: ChillGoColors.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _displayNameController,
              enabled: !isLoading,
              decoration: const InputDecoration(labelText: 'Display name'),
              validator: _validateDisplayName,
            ),
            const SizedBox(height: 28),
            if (isLoading)
              const ShimmerBox(
                height: 48,
                borderRadius: 24,
                semanticLabel: 'Creating profile',
              )
            else
              FilledButton(
                onPressed: () => _submitForm(uid, cubit),
                child: const Text('Complete profile'),
              ),
          ],
        ),
      ),
    );
  }
}
