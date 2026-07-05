import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:chillgo/core/di/injection_container.dart';
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
            debugPrint('[OnboardingScreen] uid is null, showing spinner');
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider(
          create: (_) => sl<OnboardingCubit>(),
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0F1A), Color(0xFF1E1B4B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<OnboardingCubit>();
                  final isLoading = state is OnboardingLoading;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Center(
                              child: Icon(
                                Icons.account_circle_outlined,
                                size: 80,
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Create Profile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set up your username and display name to join Crews.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Username Field
                            TextFormField(
                              controller: _usernameController,
                              enabled: !isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                prefixText: '@ ',
                                prefixStyle: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: const Color(
                                  0xFF1E293B,
                                ).withValues(alpha: 0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: _validateUsername,
                            ),
                            const SizedBox(height: 20),

                            // Display Name Field
                            TextFormField(
                              controller: _displayNameController,
                              enabled: !isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                filled: true,
                                fillColor: const Color(
                                  0xFF1E293B,
                                ).withValues(alpha: 0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: _validateDisplayName,
                            ),
                            const SizedBox(height: 32),

                            // Submit Button
                            if (isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6366F1),
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => _submitForm(uid, cubit),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Complete Onboarding'),
                              ),
                          ],
                        ),
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
}
