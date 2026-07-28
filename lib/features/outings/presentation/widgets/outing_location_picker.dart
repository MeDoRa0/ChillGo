import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../live_meetup/domain/entities/geo_coordinate.dart';
import '../../../live_meetup/domain/repositories/live_meetup_repository.dart';
import '../../../live_meetup/domain/services/map_provider.dart';

class OutingLocationPicker extends StatefulWidget {
  const OutingLocationPicker({super.key, required this.mapProvider});

  final MapProvider mapProvider;

  @override
  State<OutingLocationPicker> createState() => _OutingLocationPickerState();
}

class _OutingLocationPickerState extends State<OutingLocationPicker> {
  static const _defaultCenter = LatLng(30.0444, 31.2357);

  final _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  GeoCoordinate? _selection;
  String? _locationLabel;
  bool _isResolving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose location')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search for a place',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: _searchForPlace,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _searchForPlace(),
          ),
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 11,
            ),
            markers: _markers,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _selectCoordinate,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selection == null || _isResolving
                ? null
                : _confirmSelection,
            icon: _isResolving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_locationLabel ?? 'Choose a point on the map'),
          ),
        ),
      ],
    ),
  );

  Future<void> _searchForPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    try {
      final places = await widget.mapProvider.search(query);
      if (!mounted) return;
      if (places.isEmpty) {
        _showMessage('No matching places found.');
        return;
      }
      final place = places.first;
      _searchController.text = place.label;
      _selectCoordinate(
        LatLng(place.coordinate.latitude, place.coordinate.longitude),
      );
      setState(() => _locationLabel = place.label);
    } on LiveMeetupServiceFailure {
      if (mounted) _showMessage('Could not search for that place.');
    }
  }

  void _selectCoordinate(LatLng point) {
    final coordinate = GeoCoordinate(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    setState(() {
      _selection = coordinate;
      _locationLabel = null;
      _markers
        ..clear()
        ..add(
          Marker(markerId: const MarkerId('outing-location'), position: point),
        );
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(point));
  }

  Future<void> _confirmSelection() async {
    final coordinate = _selection!;
    setState(() => _isResolving = true);
    try {
      final label =
          _locationLabel ?? await widget.mapProvider.reverseLabel(coordinate);
      if (!mounted) return;
      if (label == null || label.trim().isEmpty) {
        _showMessage('Could not find an address for this point.');
        return;
      }
      Navigator.of(context).pop(label);
    } on LiveMeetupServiceFailure {
      if (mounted) _showMessage('Could not find an address for this point.');
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
