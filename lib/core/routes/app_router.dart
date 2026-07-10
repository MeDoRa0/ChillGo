import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../presentation/pages/not_found_page.dart';
import '../presentation/pages/loading_page.dart';

// Feature Imports
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/profile/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/crews/presentation/screens/crew_details_screen.dart';
import '../../features/crews/presentation/screens/invitations_screen.dart';
import '../../features/outings/presentation/screens/outing_form_screen.dart';
import '../../features/outings/presentation/screens/outings_list_screen.dart';
import '../../features/outings/presentation/screens/outing_details_screen.dart';
import '../di/injection_container.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    debugPrint('[AppRouter] Subscribing to auth status stream');
    _subscription = stream.asBroadcastStream().listen((val) {
      debugPrint('[AppRouter] auth status stream emitted: $val');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

AuthStatus _currentAuthStatus() {
  if (sl.isRegistered<AuthRepository>()) {
    return sl<AuthRepository>().currentStatus;
  }
  return AuthStatus.unauthenticated;
}

Stream<AuthStatus> _authStatusStream() {
  if (sl.isRegistered<AuthRepository>()) {
    return sl<AuthRepository>().status;
  }
  return Stream<AuthStatus>.value(AuthStatus.unauthenticated);
}

FutureOr<String?> guardRedirect(BuildContext context, GoRouterState state) {
  final status = _currentAuthStatus();
  debugPrint(
    '[AppRouter] guardRedirect called; status=$status, path=${state.uri.path}',
  );
  final isLoggingIn = state.uri.path == '/login';
  final isOnboarding = state.uri.path == '/onboarding';
  final isLoading = state.uri.path == '/loading';

  if (status == AuthStatus.unknown) {
    if (isLoggingIn) return null;
    if (isLoading) return '/login';
    return '/login';
  }

  if (status == AuthStatus.unauthenticated) {
    return isLoggingIn ? null : '/login';
  }

  if (status == AuthStatus.authenticatedNoProfile) {
    return isOnboarding ? null : '/onboarding';
  }

  if (status == AuthStatus.authenticatedWithProfile) {
    if (isLoggingIn || isOnboarding || isLoading) {
      return '/';
    }
  }

  return null;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  refreshListenable: GoRouterRefreshStream(_authStatusStream()),
  redirect: guardRedirect,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/loading',
      name: 'loading',
      builder: (context, state) => const LoadingScreen(),
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
      path: '/invitations',
      name: 'invitations',
      builder: (context, state) => const InvitationsScreen(),
    ),
    GoRoute(
      path: '/crews/:crewId',
      name: 'crew-details',
      builder: (context, state) {
        final crewId = state.pathParameters['crewId'] ?? '';
        return CrewDetailsScreen(crewId: crewId);
      },
    ),
    GoRoute(
      path: '/crews/:crewId/outings/new',
      name: 'outing-create',
      builder: (context, state) {
        final crewId = state.pathParameters['crewId'] ?? '';
        return OutingFormScreen(crewId: crewId);
      },
    ),
    GoRoute(
      path: '/crews/:crewId/outings',
      name: 'crew-outings',
      builder: (context, state) {
        final crewId = state.pathParameters['crewId'] ?? '';
        return OutingsListScreen(crewId: crewId);
      },
    ),
    GoRoute(
      path: '/outings/:outingId',
      name: 'outing-details',
      builder: (context, state) {
        final outingId = state.pathParameters['outingId'] ?? '';
        return OutingDetailsScreen(outingId: outingId);
      },
    ),
    GoRoute(
      path: '/outings/:outingId/edit',
      name: 'outing-edit',
      builder: (context, state) {
        final outingId = state.pathParameters['outingId'] ?? '';
        final crewId = state.uri.queryParameters['crewId'] ?? '';
        return OutingFormScreen(crewId: crewId, outingId: outingId);
      },
    ),
  ],
);
