import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/attendee_meetup_state.dart';
import '../../domain/entities/geo_coordinate.dart';
import '../../domain/entities/live_meetup_snapshot.dart';

class MeetupMap extends StatefulWidget {
  const MeetupMap({super.key, required this.snapshot});

  final LiveMeetupSnapshot snapshot;

  @override
  State<MeetupMap> createState() => _MeetupMapState();
}

class _MeetupMapState extends State<MeetupMap> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final destination = widget.snapshot.meetupPoint?.coordinate;
    final sharers = widget.snapshot.attendees
        .where((attendee) => attendee.location != null)
        .toList(growable: false);
    final center =
        destination ??
        (sharers.isNotEmpty ? sharers.first.location!.coordinate : null);
    if (center == null) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No map points are available yet.')),
      );
    }
    return Semantics(
      label: 'Shared meetup map',
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _latLng(center),
                zoom: 14,
              ),
              markers: _markers(destination, sharers),
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) => _controller = controller,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Column(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Zoom in',
                    onPressed: () =>
                        _controller?.animateCamera(CameraUpdate.zoomIn()),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Zoom out',
                    onPressed: () =>
                        _controller?.animateCamera(CameraUpdate.zoomOut()),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Recenter map',
                    onPressed: () => _recenter(center),
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _markers(
    GeoCoordinate? destination,
    List<AttendeeMeetupState> sharers,
  ) => {
    if (destination != null)
      Marker(
        markerId: const MarkerId('meetup-destination'),
        position: _latLng(destination),
        infoWindow: const InfoWindow(title: 'Meetup destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
    for (final attendee in sharers)
      Marker(
        markerId: MarkerId('attendee-${attendee.userId}'),
        position: _latLng(attendee.location!.coordinate),
        infoWindow: InfoWindow(
          title: attendee.displayName,
          snippet:
              '${attendee.status?.label ?? 'Not Updated'} · '
              '${attendee.location!.accuracyMeters.round()} m accuracy',
        ),
      ),
  };

  LatLng _latLng(GeoCoordinate coordinate) =>
      LatLng(coordinate.latitude, coordinate.longitude);

  void _recenter(GeoCoordinate center) {
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _latLng(center), zoom: 14),
      ),
    );
  }
}
