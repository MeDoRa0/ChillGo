part of '../../screens/live_meetup_screen.dart';

class _MapSurface extends StatelessWidget {
  const _MapSurface({required this.snapshot});
  final LiveMeetupSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<MapProvider>() || !sl<MapProvider>().isConfigured) {
      return _unavailableMap();
    }
    return MeetupMap(snapshot: snapshot);
  }

  Widget _unavailableMap() => const SizedBox(
    height: 96,
    child: Center(
      child: Text('Google Maps is unavailable. Location details remain below.'),
    ),
  );
}
