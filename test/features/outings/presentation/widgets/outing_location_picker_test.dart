import 'package:chillgo/features/outings/presentation/widgets/outing_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../live_meetup/live_meetup_test_helpers.dart';

void main() {
  testWidgets('gets the device location from the map action', (tester) async {
    final locationService = FakeDeviceLocationService();

    await tester.pumpWidget(
      MaterialApp(
        home: OutingLocationPicker(
          mapProvider: FakeMapProvider(),
          deviceLocationService: locationService,
          initialQuery: '',
        ),
      ),
    );

    await tester.tap(find.byTooltip('Go to my location'));
    await tester.pump();

    expect(locationService.currentPositionCalls, 1);
    expect(
      tester.widget<GoogleMap>(find.byType(GoogleMap)).myLocationEnabled,
      isTrue,
    );
  });

  testWidgets('explains when device location services are disabled', (
    tester,
  ) async {
    final locationService = FakeDeviceLocationService()..enabled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OutingLocationPicker(
          mapProvider: FakeMapProvider(),
          deviceLocationService: locationService,
          initialQuery: '',
        ),
      ),
    );

    await tester.tap(find.byTooltip('Go to my location'));
    await tester.pump();

    expect(
      find.text('Turn on location services and try again.'),
      findsOneWidget,
    );
    expect(locationService.currentPositionCalls, 0);
  });
}
