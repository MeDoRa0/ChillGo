import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/chillgo_brand.dart';
import 'package:chillgo/core/presentation/widgets/shimmer_loading.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';

part '../widgets/login_screen/login_brand.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await sl<AuthRepository>().signInWithGoogle();
    } catch (error, stackTrace) {
      debugPrint('[ChillGo] Google sign-in failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().contains('cancelled')
              ? 'Sign in cancelled'
              : 'Failed to sign in with Google';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await sl<AuthRepository>().signInWithApple();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('cancelled')
              ? 'Sign in cancelled'
              : 'Failed to sign in with Apple';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SunshineBackground(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ResponsiveContent(
            maxWidth: 430,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginBrand(),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ChillGoColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ChillGoColors.outline),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x146D3A72),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Continue to ChillGo',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 18),
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ChillGoColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_isLoading)
                            const ShimmerBox(
                              height: 48,
                              borderRadius: 24,
                              semanticLabel: 'Signing in',
                            )
                          else ...[
                            ElevatedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text('Continue with Google'),
                            ),
                            if (defaultTargetPlatform ==
                                TargetPlatform.iOS) ...[
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _handleAppleSignIn,
                                icon: const Icon(Icons.apple, size: 24),
                                label: const Text('Continue with Apple'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: ChillGoColors.ink,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
