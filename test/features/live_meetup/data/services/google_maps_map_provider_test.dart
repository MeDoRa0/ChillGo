import 'package:chillgo/features/live_meetup/data/services/google_maps_map_provider.dart';
import 'package:chillgo/features/live_meetup/domain/entities/geo_coordinate.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('searches through the callable proxy and maps its candidates', () async {
    final calls = <String>[];
    final provider = GoogleMapsMapProvider.forTesting(
      call: (name, payload) async {
        calls.add('$name:${payload['query']}');
        return {
          'results': [
            {
              'id': 'place.1',
              'label': 'Cafe, Cairo',
              'latitude': 30,
              'longitude': 31,
            },
          ],
        };
      },
    );

    final results = await provider.search('Cafe');

    expect(provider.isConfigured, isTrue);
    expect(calls, ['searchMapPlace:Cafe']);
    expect(results.single.label, 'Cafe, Cairo');
    expect(
      results.single.coordinate,
      GeoCoordinate(latitude: 30, longitude: 31),
    );
  });

  test('resolves a selected pin through the callable proxy', () async {
    final provider = GoogleMapsMapProvider.forTesting(
      call: (name, payload) async {
        expect(name, 'reverseGeocode');
        expect(payload, {'latitude': 30.0, 'longitude': 31.0});
        return {'label': 'Cairo, Egypt'};
      },
    );

    expect(
      await provider.reverseLabel(GeoCoordinate(latitude: 30, longitude: 31)),
      'Cairo, Egypt',
    );
  });

  test('rejects malformed callable responses', () async {
    final provider = GoogleMapsMapProvider.forTesting(
      call: (_, _) async => {'results': 'not-a-list'},
    );

    await expectLater(
      provider.search('Cafe'),
      throwsA(isA<LiveMeetupServiceFailure>()),
    );
  });
}
