import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/pages/details_page.dart';
import '../presentation/pages/not_found_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => HomeScreen(
        // Only expose the crash CTA in debug builds.
        onTriggerCrash: kDebugMode
            ? () {
                throw StateError('Simulated diagnostics crash');
              }
            : null,
      ),
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
