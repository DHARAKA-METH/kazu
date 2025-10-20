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
  final LatLng _petCurrentLocation = const LatLng(6.8440, 80.0029);
  late Marker _petMarker;
  LatLng? _safeZoneLocation;
  double? _safeZoneRadius;

  // Footer navigation bar
  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    if (index != _selectedIndex) {
      // Navigate to profile page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // switch to the google maps app
  Future<void> openInGoogleMaps(double lat, double lng) async {
    final Uri googleMapUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  @override
  void initState() {
    super.initState();
    _petMarker = Marker(
      markerId: const MarkerId('PetCurrentLocation'),
      position: _petCurrentLocation,
      infoWindow: const InfoWindow(title: '🐶 Pet Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '🐾  Pet Details ...',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    widget.imagePath,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$age years old',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 🗺️ Map section -------------------------
            // SizedBox(
            //   height: 300,
            //   width: double.infinity,
            //   child: GoogleMap(
            //     initialCameraPosition: CameraPosition(
            //       target: _petCurrentLocation,
            //       zoom: 15,
            //     ),
            //     onMapCreated: (controller) => _mapController = controller,
            //     markers: {_petMarker},
            //     myLocationButtonEnabled: false,
            //     compassEnabled: true,
            //   ),
            // ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnBack,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SafeZoneSelector()),
                      );
                      if (result != null) {
                        setState(() {
                          _safeZoneLocation = LatLng(
                            result['latitude'],
                            result['longitude'],
                          );
                          _safeZoneRadius = result['radius'];
                        });
                      }
                    },
                    child: const Text(
                      'Update Safe Zone',
                      style: TextStyle(color: AppColors.btnTextPrimary),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  child: ElevatedButton(
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
                ),
              ],
            ),
            SizedBox(height: 20),

            // Text('Activity Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 15),
        child: AppFooter(
          currentIndex: _selectedIndex,
          onTabTapped: _onTabTapped,
        ),
      ),
    );
  }
}
