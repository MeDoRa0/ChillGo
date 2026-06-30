import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/pages/details_page.dart';
import '../presentation/pages/not_found_page.dart';

// Feature Imports
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/profile/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../di/injection_container.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  refreshListenable: GoRouterRefreshStream(sl<AuthRepository>().status),
  redirect: (context, state) {
    final status = sl<AuthRepository>().currentStatus;
    final isLoggingIn = state.uri.path == '/login';
    final isOnboarding = state.uri.path == '/onboarding';

    if (status == AuthStatus.unauthenticated) {
      return isLoggingIn ? null : '/login';
    }

    if (status == AuthStatus.authenticatedNoProfile) {
      return isOnboarding ? null : '/onboarding';
    }

    if (status == AuthStatus.authenticatedWithProfile) {
      if (isLoggingIn || isOnboarding) {
        return '/';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => HomeScreen(
        onTriggerCrash: kDebugMode
            ? () {
                throw StateError('Simulated diagnostics crash');
              }
            : null,
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/details',
      name: 'details',
      builder: (context, state) {
        final param = state.uri.queryParameters['param'];
        return DetailsPage(parameter: param);
      },
    ),
  ],
);
