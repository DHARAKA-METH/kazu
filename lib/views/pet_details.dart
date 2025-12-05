import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kazu/constants/app_colors.dart';
import 'package:kazu/controllers/pet_controller.dart';
import 'package:kazu/services/pet_services.dart';
import 'package:kazu/views/components/app_footer.dart';
import 'package:kazu/views/home_page.dart';
import 'package:kazu/views/safe_zone_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class PetDetails extends StatefulWidget {
  final String name;
  final String deviceId;
  final String imagePath;
  final LatLng safeZoneCoordinates;
  final double safeZoneRadius;

  const PetDetails({
    super.key,
    required this.name,
    required this.deviceId,
    required this.imagePath,
    required this.safeZoneCoordinates,
    required this.safeZoneRadius,
  });

  @override
  State<PetDetails> createState() => _PetDetailsState();
}

class _PetDetailsState extends State<PetDetails> {
  final PetService _petService = PetService();
  final RealtimePetService _realtimePetService = RealtimePetService();
  final MqttHelper mqttHelper = MqttHelper();
  int _selectedIndex = 2;
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  // MQTT / device variables
  late String selectedPet;
  Map<String, dynamic>? deviceData;
  bool isPetInSafeZone = false;
  bool isPetSleeping = false;
  bool isDeviceConnected = false;
  String _batteryLife = '60%';
  String _signalStrength = '🛜- N/A';

  // Map variables
  GoogleMapController? _mapController;
  late LatLng _petCurrentLocation;
  late LatLng _safeZoneLocation;
  late double _safeZoneRadius;
  Circle? _safeZoneCircle;
  Marker? _petMarker;
  Marker? _safeZoneMarker;

  @override
  void initState() {
    super.initState();

    selectedPet = widget.deviceId;

    // Initialize locations
    _petCurrentLocation = widget.safeZoneCoordinates;
    _safeZoneLocation = widget.safeZoneCoordinates;
    _safeZoneRadius = widget.safeZoneRadius;

    _updateSafeZoneCircle();

    // Subscribe to MQTT live data
    _subscription = mqttHelper.connectAndListen(selectedPet).listen((data) {
      setState(() {
        deviceData = data;

        final loc = data['currentLocation'];
        if (loc != null) {
          _petCurrentLocation = LatLng(
            (loc['lat'] ?? 0).toDouble(),
            (loc['lng'] ?? 0).toDouble(),
          );
        }

        // Update pet marker
        _petMarker = Marker(
          markerId: const MarkerId('PetCurrent_Location'),
          position: _petCurrentLocation,
          infoWindow: const InfoWindow(title: '🐶 Pet Location'),
          icon: _petMarker?.icon ?? BitmapDescriptor.defaultMarker,
        );

        // Animate camera
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_petCurrentLocation),
        );

        isPetInSafeZone = data['isInSafeZone'] ?? true;
        isPetSleeping = data['isPetSleep'] ?? false;
        isDeviceConnected = data['isConnected'] ?? false;
        _batteryLife = "${data['batteryLevel'] ?? 0}%";

        // Safe signal strength handling
        _signalStrength = data['signalStrength'] != null
            ? "🛜- ${data['signalStrength']}%"
            : "🛜- N/A";
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      print('🔴 Live Data: $deviceData');
    });

    _setCustomMarker();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _setCustomMarker() async {
    final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      'assets/images/petMarker2.png',
    );

    setState(() {
      _petMarker = Marker(
        markerId: const MarkerId('PetCurrent_Location'),
        position: _petCurrentLocation,
        infoWindow: const InfoWindow(title: '🐶 Pet Location'),
        icon: customIcon,
      );
    });
  }

  void _updateSafeZoneCircle() {
    _safeZoneCircle = Circle(
      circleId: const CircleId('safeZone'),
      center: _safeZoneLocation,
      radius: _safeZoneRadius,
      strokeColor: Colors.blue.withOpacity(0.7),
      fillColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 2,
    );

    _safeZoneMarker = Marker(
      markerId: const MarkerId('SafeZone'),
      position: _safeZoneLocation,
      infoWindow: const InfoWindow(title: 'Safe Zone 🏠'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );

    setState(() {
      _selectedIndex = index;
    });
  }

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
      body: Stack(
        children: [
          // MAIN CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              children: [
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _petCurrentLocation,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: {
                      if (_petMarker != null) _petMarker!,
                      if (_safeZoneMarker != null) _safeZoneMarker!,
                    },
                    circles: _safeZoneCircle != null ? {_safeZoneCircle!} : {},
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        widget.imagePath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
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
                                : 'Out of Safe Zone ⚠️',
                            style: TextStyle(
                              color: isPetInSafeZone
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPetSleeping
                                ? 'Pet is Calm and Resting 💤'
                                : 'Pet is Playful/Active 🐾',
                            style: TextStyle(
                              color: isPetSleeping
                                  ? Colors.green
                                  : const Color.fromARGB(255, 26, 12, 226),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
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
                              const SizedBox(width: 6),
                              Text(
                                _signalStrength,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 20),
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
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
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
                            _updateSafeZoneCircle();
                            _petService.updateSafeZoneToDb(
                              deviceId: widget.deviceId,
                              latitude: result['latitude'],
                              longitude: result['longitude'],
                              radius: result['radius'],
                            );
                            _realtimePetService.updateSafeZoneToRealtimeDB(
                              deviceId: widget.deviceId,
                              latitude: result['latitude'],
                              longitude: result['longitude'],
                              radius: result['radius'],
                            );
                          });
                        }
                      },
                      child: const Text(
                        'Update Safe Zone',
                        style: TextStyle(color: AppColors.btnTextPrimary),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.btnBack,
                      ),
                      onPressed: () {
                        openInGoogleMaps(
                          _petCurrentLocation.latitude,
                          _petCurrentLocation.longitude,
                        );
                      },
                      child: const Text(
                        'Get Direction',
                        style: TextStyle(color: AppColors.btnTextPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FULL-SCREEN LOADING OVERLAY
          if (!isDeviceConnected)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Connecting to device...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
