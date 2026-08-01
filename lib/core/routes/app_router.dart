import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../presentation/pages/not_found_page.dart';
import '../presentation/pages/loading_page.dart';

// Feature Imports
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/profile/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/welcome/domain/repositories/welcome_onboarding_repository.dart';
import '../../features/welcome/presentation/screens/welcome_onboarding_screen.dart';
import '../../features/crews/presentation/screens/crew_details_screen.dart';
import '../../features/crews/presentation/screens/invitations_screen.dart';
import '../../features/outings/presentation/screens/outing_form_screen.dart';
import '../../features/outings/presentation/screens/outing_review_screen.dart';
import '../../features/outings/presentation/screens/outings_list_screen.dart';
import '../../features/voting/presentation/screens/agreement_screen.dart';
import '../../features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart';
import '../../features/chat/presentation/screens/outing_chat_screen.dart';
import '../../features/live_meetup/presentation/cubit/live_meetup/live_meetup_cubit.dart';
import '../../features/live_meetup/presentation/screens/live_meetup_screen.dart';
import '../../features/live_meetup/presentation/cubit/location_sharing/location_sharing_cubit.dart';
import '../../features/live_meetup/presentation/cubit/meetup_point_editor/meetup_point_editor_cubit.dart';
import '../di/injection_container.dart';

class AppRouterRefreshNotifier extends ChangeNotifier {
  AppRouterRefreshNotifier(Iterable<Stream<dynamic>> streams) {
    for (final stream in streams) {
      _subscriptions.add(
        stream.listen((event) {
          debugPrint('[AppRouter] refresh event: $event');
          notifyListeners();
        }),
      );
    }
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
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

bool _isWelcomeOnboardingComplete() {
  if (!sl.isRegistered<WelcomeOnboardingRepository>()) return true;
  return sl<WelcomeOnboardingRepository>().isComplete;
}

Stream<bool> _welcomeCompletionStream() {
  if (!sl.isRegistered<WelcomeOnboardingRepository>()) {
    return const Stream<bool>.empty();
  }
  return sl<WelcomeOnboardingRepository>().completionChanges;
}

FutureOr<String?> guardRedirect(BuildContext context, GoRouterState state) {
  final status = _currentAuthStatus();
  final welcomeComplete = _isWelcomeOnboardingComplete();
  debugPrint(
    '[AppRouter] guardRedirect called; status=$status, '
    'welcomeComplete=$welcomeComplete, path=${state.uri.path}',
  );
  final isLoggingIn = state.uri.path == '/login';
  final isProfileOnboarding = state.uri.path == '/onboarding';
  final isLoading = state.uri.path == '/loading';
  final isWelcome = state.uri.path == '/welcome';

  if (!welcomeComplete) {
    return isWelcome ? null : '/welcome';
  }

  if (status == AuthStatus.unknown) {
    return isLoading ? null : '/loading';
  }

  if (status == AuthStatus.unauthenticated) {
    return isLoggingIn ? null : '/login';
  }

  if (status == AuthStatus.authenticatedNoProfile) {
    return isProfileOnboarding ? null : '/onboarding';
  }

  if (status == AuthStatus.authenticatedWithProfile) {
    if (isLoggingIn || isProfileOnboarding || isLoading || isWelcome) {
      return '/';
    }
  }

  return null;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  refreshListenable: AppRouterRefreshNotifier([
    _authStatusStream(),
    _welcomeCompletionStream(),
  ]),
  redirect: guardRedirect,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => WelcomeOnboardingScreen(
        welcomeRepository: sl<WelcomeOnboardingRepository>(),
      ),
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
      path: '/outings/:outingId/review',
      name: 'outing-review',
      builder: (context, state) =>
          OutingReviewScreen(outingId: state.pathParameters['outingId'] ?? ''),
    ),
    GoRoute(
      path: '/outings/:outingId/agreement',
      name: 'outing-agreement',
      builder: (context, state) =>
          AgreementScreen(outingId: state.pathParameters['outingId'] ?? ''),
    ),
    GoRoute(
      path: '/outings/:outingId/chat',
      name: 'outing-chat',
      builder: (context, state) {
        final outingId = state.pathParameters['outingId'] ?? '';
        return BlocProvider(
          create: (_) => sl<OutingChatCubit>()..watch(outingId),
          child: OutingChatScreen(outingId: outingId),
        );
      },
    ),
    GoRoute(
      path: '/outings/:outingId/live-meetup',
      name: 'live-meetup',
      builder: (context, state) {
        final outingId = state.pathParameters['outingId'] ?? '';
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<LiveMeetupCubit>()..watch(outingId)),
            BlocProvider(create: (_) => sl<LocationSharingCubit>()),
            BlocProvider(
              create: (_) => sl<MeetupPointEditorCubit>()..watch(outingId),
            ),
          ],
          child: LiveMeetupScreen(outingId: outingId),
        );
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
