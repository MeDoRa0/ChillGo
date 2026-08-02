import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/features/outings/presentation/cubit/outing_form/outing_form_cubit.dart';
import 'package:chillgo/features/outings/presentation/screens/outing_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../outing_repository_fake.dart';

void main() {
  tearDown(() async {
    if (sl.isRegistered<OutingRepository>()) {
      await sl.unregister<OutingRepository>();
    }
  });

  testWidgets('returns to crew details after creating an outing', (
    tester,
  ) async {
    sl.registerSingleton<OutingRepository>(FakeOutingRepository());
    final router = GoRouter(
      initialLocation: '/crews/crew-1/outings/new',
      routes: [
        GoRoute(
          path: '/crews/:crewId/outings/new',
          builder: (context, state) =>
              OutingFormScreen(crewId: state.pathParameters['crewId']!),
        ),
        GoRoute(
          path: '/crews/:crewId',
          builder: (context, state) =>
              const Scaffold(body: Text('Crew details')),
        ),
        GoRoute(
          path: '/crews/:crewId/outings',
          builder: (context, state) => const Scaffold(body: Text('Outings')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Make a plan'), findsOneWidget);
    expect(find.text('Where are we going?'), findsOneWidget);
    expect(find.text('Choose on map'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('When?'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);

    final formCubit = BlocProvider.of<OutingFormCubit>(
      tester.element(find.text('Share with crew')),
    );
    await formCubit.createOuting(
      crewId: 'crew-1',
      title: 'Friday cafe',
      scheduledAt: DateTime(2030),
      locationText: 'Downtown cafe',
    );
    await tester.pumpAndSettle();

    expect(find.text('Crew details'), findsOneWidget);
  });

  testWidgets('confirms cancellation without asking for a reason', (
    tester,
  ) async {
    final outing = FakeOutingRepository.sampleOuting();
    final repository = FakeOutingRepository(
      detail: OutingDetail(outing: outing, participants: const []),
    );
    sl.registerSingleton<OutingRepository>(repository);
    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(
          path: '/edit',
          builder: (_, _) =>
              const OutingFormScreen(crewId: 'crew-1', outingId: 'outing-1'),
        ),
        GoRoute(
          path: '/crews/:crewId/outings',
          builder: (_, _) => const Scaffold(body: Text('Outings')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final cancelButton = find.byKey(const Key('cancel-outing-button'));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure you want to cancel this outing?'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Cancel outing'));
    await tester.pumpAndSettle();

    expect(repository.cancelledOutingId, outing.id);
    expect(repository.cancelledReason, defaultOutingCancellationReason);
    expect(find.text('Outings'), findsOneWidget);
  });
}
