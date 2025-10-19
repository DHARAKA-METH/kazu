import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SafeZoneSelector extends StatefulWidget {
  const SafeZoneSelector({super.key});

  @override
  State<SafeZoneSelector> createState() => _SafeZoneSelectorState();
}

class _SafeZoneSelectorState extends State<SafeZoneSelector> {
  GoogleMapController? _mapController;
  LatLng? _safeZoneCenter;
  double _radius = 100; // default radius in meters
  Circle? _safeZone;
  Marker? _selectedMarker;

  // Initial camera position (will be updated to current location)
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  // Get user's current location
  Future<void> _setInitialLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _initialPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16,
      );
      _safeZoneCenter = LatLng(position.latitude, position.longitude);
      _updateCircle();
      _selectedMarker = Marker(
        markerId: const MarkerId('safeZone'),
        position: _safeZoneCenter!,
      );
    });
  }

  // Update safe zone circle
  void _updateCircle() {
    if (_safeZoneCenter == null) return;
    setState(() {
      _safeZone = Circle(
        circleId: const CircleId('safeZone'),
        center: _safeZoneCenter!,
        radius: _radius,
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      );
      _selectedMarker = Marker(
        markerId: const MarkerId('safeZone'),
        position: _safeZoneCenter!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Safe Zone')),
      body: _safeZoneCenter == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: _initialPosition,
                    markers: _selectedMarker != null ? {_selectedMarker!} : {},
                    circles: _safeZone != null ? {_safeZone!} : {},
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (LatLng latLng) {
                      setState(() {
                        _safeZoneCenter = latLng;
                        _updateCircle();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Radius: ${_radius.toInt()} meters',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        min: 50,
                        max: 500,
                        divisions: 9,
                        value: _radius,
                        label: '${_radius.toInt()} m',
                        onChanged: (value) {
                          setState(() {
                            _radius = value;
                            _updateCircle();
                          });
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_safeZoneCenter != null) {
                              Navigator.pop(context, {
                                'latitude': _safeZoneCenter!.latitude,
                                'longitude': _safeZoneCenter!.longitude,
                                'radius': _radius,
                              });
                            }
                          },
                          child: const Text('Save Safe Zone'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
