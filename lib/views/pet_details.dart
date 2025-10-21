import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kazu/constants/app_colors.dart';
import 'package:kazu/views/components/app_footer.dart';
import 'package:kazu/views/home_page.dart';
import 'package:kazu/views/safe_zone_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class PetDetails extends StatefulWidget {
  final String name;
  final String deviceId;
  final String imagePath;

  const PetDetails({
    super.key,
    required this.name,
    required this.deviceId,
    required this.imagePath,
  });

  @override
  State<PetDetails> createState() => _PetDetailsState();
}

class _PetDetailsState extends State<PetDetails> {
  int _selectedIndex = 2;
  String age = '06';
  GoogleMapController? _mapController;
  bool isPetInSafeZone = false;
  bool isDeviceConnected = true;
  String _batteryLife = '64%';
  double _distanceFromSafeZone = 10.0;

  // Pet location
  final LatLng _petCurrentLocation = const LatLng(6.8440, 80.0029);
  Marker? _petMarker;

  // Safe zone
  LatLng? _safeZoneLocation;
  double? _safeZoneRadius;
  Circle? _safeZoneCircle;

  @override
  void initState() {
    super.initState();
    _setCustomMarker();
  }

  // Set custom marker for pet
  Future<void> _setCustomMarker() async {
    final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      'assets/images/pet_marker.png',
    );

    setState(() {
      _petMarker = Marker(
        markerId: const MarkerId('PetCurrentLocation'),
        position: _petCurrentLocation,
        infoWindow: const InfoWindow(title: '🐶 Pet Location'),
        icon: customIcon,
      );
    });
  }

  // Footer navigation
  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // Open location in Google Maps app
  Future<void> openInGoogleMaps(double lat, double lng) async {
    final Uri googleMapUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open Google Maps')));
    }
  }

  // Update Safe Zone Circle
  void _updateSafeZoneCircle() {
    if (_safeZoneLocation != null && _safeZoneRadius != null) {
      setState(() {
        _safeZoneCircle = Circle(
          circleId: const CircleId('safeZone'),
          center: _safeZoneLocation!,
          radius: _safeZoneRadius!,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '🐾 Pet Details',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            // Map
            SizedBox(
              height: 400,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _petCurrentLocation,
                  zoom: 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _petMarker != null ? {_petMarker!} : {},
                circles: _safeZoneCircle != null ? {_safeZoneCircle!} : {},
                myLocationButtonEnabled: false,
                compassEnabled: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🐾 Pet Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    widget.imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),

                // 🐶 Pet Info
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet name & status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPetInSafeZone
                                ? 'In Safe Zone 🏠'
                                : 'Have ${_distanceFromSafeZone} km From Safe Zone ⚠️',
                            style: TextStyle(
                               color: isPetInSafeZone ? Colors.green : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Device status row (connection + battery)
                      Row(
                        children: [
                          // 🔌 Connection status
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/online.png',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDeviceConnected
                                    ? 'Connected'
                                    : 'Disconnected',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 20),

                          // 🔋 Battery status
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/battery.png',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _batteryLife,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buttons
            Wrap(
  spacing: 10, // horizontal space between buttons
  runSpacing: 10, // vertical space between rows when wrapping
  alignment: WrapAlignment.center, // center the buttons
  children: [
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.btnBack,
      ),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SafeZoneSelector(),
          ),
        );
        if (result != null) {
          setState(() {
            _safeZoneLocation = LatLng(
              result['latitude'],
              result['longitude'],
            );
            _safeZoneRadius = result['radius'];
            _updateSafeZoneCircle();
          });
        }
      },
      child: const Text(
        'Update Safe Zone',
        style: TextStyle(color: AppColors.btnTextPrimary),
      ),
    ),
    ElevatedButton(
      onPressed: () {
        openInGoogleMaps(
          _petCurrentLocation.latitude,
          _petCurrentLocation.longitude,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.btnBack,
      ),
      child: const Text(
        'Get Direction',
        style: TextStyle(color: AppColors.btnTextPrimary),
      ),
    ),
    ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.btnBack,
      ),
      child: const Text(
        'Turn On Buzzer',
        style: TextStyle(color: AppColors.btnTextPrimary),
      ),
    ),
  ],
),

          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: AppFooter(
          currentIndex: _selectedIndex,
          onTabTapped: _onTabTapped,
        ),
      ),
    );
  }
}
