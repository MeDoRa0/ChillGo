import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../live_meetup/domain/entities/geo_coordinate.dart';
import '../../../live_meetup/domain/repositories/live_meetup_repository.dart';
import '../../../live_meetup/domain/services/device_location_service.dart';
import '../../../live_meetup/domain/services/map_provider.dart';

class OutingLocationPicker extends StatefulWidget {
  const OutingLocationPicker({
    super.key,
    required this.mapProvider,
    required this.deviceLocationService,
    required this.initialQuery,
  });

  final MapProvider mapProvider;
  final DeviceLocationService deviceLocationService;
  final String initialQuery;

  @override
  State<OutingLocationPicker> createState() => _OutingLocationPickerState();
}

class _OutingLocationPickerState extends State<OutingLocationPicker> {
  static const _defaultCenter = LatLng(30.0444, 31.2357);

  final _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  LatLng _searchCenter = _defaultCenter;
  Timer? _searchDebounce;
  GeoCoordinate? _selection;
  String? _locationLabel;
  String? _searchSessionToken;
  List<PlaceCandidate> _searchResults = const [];
  int _searchSequence = 0;
  bool _isSearching = false;
  bool _isResolving = false;
  bool _isLocating = false;
  bool _showsDeviceLocation = false;
  static final Random _random = Random.secure();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.trim().length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchForPlace());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
            onChanged: _onSearchQueryChanged,
            onSubmitted: (_) => _searchForPlace(),
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(
              height: 4,
              borderRadius: 2,
              semanticLabel: 'Searching locations',
            ),
          ),
        if (_searchResults.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(place.label),
                  onTap: _isResolving ? null : () => _selectPlace(place),
                );
              },
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultCenter,
                  zoom: 11,
                ),
                markers: _markers,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: _showsDeviceLocation,
                onMapCreated: (controller) => _mapController = controller,
                onCameraMove: (position) => _searchCenter = position.target,
                onTap: _selectCoordinate,
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton.filledTonal(
                  tooltip: 'Go to my location',
                  onPressed: _isLocating ? null : _goToCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selection == null || _isResolving
                ? null
                : _confirmSelection,
            icon: _isResolving
                ? const ShimmerBox(
                    width: 18,
                    height: 18,
                    shape: BoxShape.circle,
                    semanticLabel: 'Resolving location',
                  )
                : const Icon(Icons.check),
            label: Text(_locationLabel ?? 'Choose a point on the map'),
          ),
        ),
      ],
    ),
  );

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      await _locateDevice();
    } on LiveMeetupFailure {
      if (mounted) _showMessage('Could not get your current location.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _locateDevice() async {
    final accessFailure = await _locationAccessFailure();
    if (!mounted) return;
    if (accessFailure != null) {
      _showMessage(accessFailure);
      return;
    }
    final sample = await widget.deviceLocationService.currentPosition();
    if (mounted) await _showDeviceLocation(sample.coordinate);
  }

  Future<String?> _locationAccessFailure() async {
    if (!await widget.deviceLocationService.isServiceEnabled()) {
      return 'Turn on location services and try again.';
    }
    var permission = await widget.deviceLocationService.checkPermission();
    if (permission == DeviceLocationPermission.denied) {
      permission = await widget.deviceLocationService.requestPermission();
    }
    return switch (permission) {
      DeviceLocationPermission.deniedForever =>
        'Enable location permission in system settings.',
      DeviceLocationPermission.denied => 'Location permission was denied.',
      DeviceLocationPermission.whileInUse ||
      DeviceLocationPermission.reducedWhileInUse => null,
    };
  }

  Future<void> _showDeviceLocation(GeoCoordinate coordinate) async {
    setState(() => _showsDeviceLocation = true);
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(coordinate.latitude, coordinate.longitude),
        16,
      ),
    );
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    _searchSequence++;
    if (query.trim().length < 3) {
      _searchSessionToken = null;
      setState(() {
        _isSearching = false;
        _searchResults = const [];
      });
      return;
    }
    setState(() => _searchResults = const []);
    _searchDebounce = Timer(const Duration(milliseconds: 350), _searchForPlace);
  }

  Future<void> _searchForPlace() async {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 3) return;
    final searchSequence = ++_searchSequence;
    setState(() => _isSearching = true);
    try {
      final sessionToken = _searchSessionToken ??= _newSessionToken();
      final places = await widget.mapProvider.search(
        query,
        sessionToken: sessionToken,
        bias: GeoCoordinate(
          latitude: _searchCenter.latitude,
          longitude: _searchCenter.longitude,
        ),
      );
      if (!mounted || searchSequence != _searchSequence) return;
      setState(() {
        _isSearching = false;
        _searchResults = places;
      });
    } on LiveMeetupServiceFailure {
      if (!mounted || searchSequence != _searchSequence) return;
      setState(() => _isSearching = false);
      _showMessage('Could not search for that place.');
    }
  }

  Future<void> _selectPlace(PlaceCandidate place) async {
    final sessionToken = _searchSessionToken;
    if (sessionToken == null) return;
    setState(() => _isResolving = true);
    try {
      final resolvedPlace = await widget.mapProvider.resolvePlace(
        place,
        sessionToken: sessionToken,
      );
      if (!mounted) return;
      final coordinate = resolvedPlace.coordinate;
      if (coordinate == null) {
        _showMessage('Could not find that place.');
        return;
      }
      _searchSessionToken = null;
      _searchController.text = resolvedPlace.label;
      _selectCoordinate(LatLng(coordinate.latitude, coordinate.longitude));
      setState(() {
        _locationLabel = resolvedPlace.label;
        _searchResults = const [];
      });
    } on LiveMeetupServiceFailure {
      if (mounted) _showMessage('Could not search for that place.');
    } finally {
      if (mounted) setState(() => _isResolving = false);
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

  static String _newSessionToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
