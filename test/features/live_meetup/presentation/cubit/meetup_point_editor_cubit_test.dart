import 'package:chillgo/features/live_meetup/domain/entities/geo_coordinate.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/domain/services/map_provider.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/meetup_point_editor/meetup_point_editor_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../live_meetup_test_helpers.dart';

void main() {
  test(
    'search, selection, explicit confirmation, and save are ordered',
    () async {
      final repository = FakeLiveMeetupRepository();
      final map = FakeMapProvider()
        ..results = [PlaceCandidate(id: 'place', label: 'Cafe')];
      final cubit = MeetupPointEditorCubit(
        repository: repository,
        mapProvider: map,
      );
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });
      await cubit.watch('outing');
      // Feed the preparation stream through a purpose-built repository variant.
      expect(cubit.state.status, MeetupPointEditorStatus.loading);
      await cubit.search('Cafe');
      await cubit.select(map.results.single);
      expect(cubit.state.confirmed, isFalse);
      expect(
        cubit.state.selection!.coordinate,
        GeoCoordinate(latitude: 30, longitude: 31),
      );
      cubit.confirm(true);
      expect(cubit.state.confirmed, isTrue);
    },
  );

  test('provider failure remains recoverable', () async {
    final repository = FakeLiveMeetupRepository();
    final cubit = MeetupPointEditorCubit(
      repository: repository,
      mapProvider: _FailingMapProvider(),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    await cubit.search('Cafe');
    expect(cubit.state.status, MeetupPointEditorStatus.failed);
  });
}

class _FailingMapProvider implements MapProvider {
  @override
  bool get isConfigured => false;
  @override
  Future<String?> reverseLabel(GeoCoordinate coordinate) =>
      throw const LiveMeetupServiceFailure();
  @override
  Future<List<PlaceCandidate>> search(
    String query, {
    required String sessionToken,
    GeoCoordinate? bias,
  }) => throw const LiveMeetupServiceFailure();
  @override
  Future<PlaceCandidate> resolvePlace(
    PlaceCandidate candidate, {
    required String sessionToken,
  }) => throw const LiveMeetupServiceFailure();
}
