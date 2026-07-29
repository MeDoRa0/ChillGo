import 'package:chillgo/features/live_meetup/data/services/google_maps_map_provider.dart';
import 'package:chillgo/features/live_meetup/domain/entities/geo_coordinate.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/domain/services/map_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'searches through the callable proxy and maps place predictions',
    () async {
      final calls = <String>[];
      final provider = GoogleMapsMapProvider.forTesting(
        call: (name, payload) async {
          calls.add(
            '$name:${payload['query']}:${payload['sessionToken']}:'
            '${payload['biasLatitude']}:${payload['biasLongitude']}',
          );
          return {
            'results': [
              {'id': 'place.1', 'label': 'Cafe, Cairo'},
            ],
          };
        },
      );

      final results = await provider.search(
        'Cafe',
        sessionToken: '550e8400-e29b-41d4-a716-446655440000',
        bias: GeoCoordinate(latitude: 30.0444, longitude: 31.2357),
      );

      expect(provider.isConfigured, isTrue);
      expect(calls, [
        'searchMapPlace:Cafe:550e8400-e29b-41d4-a716-446655440000:'
            '30.0444:31.2357',
      ]);
      expect(results.single.label, 'Cafe, Cairo');
      expect(results.single.coordinate, isNull);
    },
  );

  test('resolves only the selected place through the callable proxy', () async {
    final provider = GoogleMapsMapProvider.forTesting(
      call: (name, payload) async {
        expect(name, 'resolveMapPlace');
        expect(payload, {
          'placeId': 'places/ChIJ123',
          'sessionToken': '550e8400-e29b-41d4-a716-446655440000',
        });
        return {'latitude': 30, 'longitude': 31};
      },
    );
    const candidate = PlaceCandidate(id: 'places/ChIJ123', label: 'Cafe');

    final resolved = await provider.resolvePlace(
      candidate,
      sessionToken: '550e8400-e29b-41d4-a716-446655440000',
    );

    expect(resolved.coordinate, GeoCoordinate(latitude: 30, longitude: 31));
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
      provider.search(
        'Cafe',
        sessionToken: '550e8400-e29b-41d4-a716-446655440000',
      ),
      throwsA(isA<LiveMeetupServiceFailure>()),
    );
  });
}
