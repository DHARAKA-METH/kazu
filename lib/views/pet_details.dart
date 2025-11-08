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
  Timer? _timer;
  final RealtimePetService _service = RealtimePetService();
  final MqttHelper mqttHelper = MqttHelper();

  // MQTT data
  late String selectedPet;
  Map<String, dynamic>? deviceData;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  // variables
  Map<String, dynamic>? petLiveData;
  String age = '06';
  bool isPetInSafeZone = false;
  final double _distanceFromSafeZone = 10.0;

  GoogleMapController? _mapController;
  // Safe zone
  LatLng? _safeZone_Location;
  double? _safeZoneRadius;
  Circle? _safeZoneCircle;
  Marker? _petMarker;

  LatLng _petCurrent_Location = const LatLng(6.8440, 80.0029);
  bool isDeviceConnected = false;
  String _batteryLife = '6%';

  @override
  void initState() {
    super.initState();

    // Subscribe to MQTT live data stream
    selectedPet = widget.deviceId;
    _subscription = mqttHelper.connectAndListen(selectedPet).listen((data) {
      setState(() {
        deviceData = data;
        final _loc = deviceData?['currentLocation'];
        if (_loc != null) {
          _petCurrent_Location = LatLng(
            (_loc['lat'] ?? 0).toDouble(),
            (_loc['lng'] ?? 0).toDouble(),
          );
        }

        // Update pet marker in map
        _petMarker = Marker(
          markerId: const MarkerId('PetCurrent_Location'),
          position: _petCurrent_Location,
          infoWindow: const InfoWindow(title: '🐶 Pet Location'),
          icon: _petMarker?.icon ?? BitmapDescriptor.defaultMarker,
        );

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_petCurrent_Location),
          );
        }

        isPetInSafeZone = data['isInsideSafeZone'] ?? true;
        isDeviceConnected = data['isConnected'] ?? false;
        _batteryLife = "${data['batteryLevel'] ?? 0}%";

        print(
          '-------------"_petCurrent_Location" -- ${_petCurrent_Location} ----------------------',
        );
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      print('🔴🔴 🔴 🔴 🔴 🔴  Live Data for : $deviceData');
    });

    _setCustomMarker();
    // _timer = Timer.periodic(Duration(minutes: 1), (timer) {
    //   _loadPetLiveData();
    // });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // Future<void> _loadPetLiveData() async {
  //   final data = await _service.fetchPetLive(widget.deviceId);
  //   setState(() {
  //     if (data != null) {
  //       petLiveData = data;
  //       // Update status
  //       isPetInSafeZone = data['isInsideSafeZone'] ?? true;
  //       isDeviceConnected = data['isConnected'] ?? false;
  //       _batteryLife = "${data['batteryLevel'] ?? 0}%";

  //       // Update pet _location
  //       final _loc = data['current_Location'];
  //       if (_loc != null) {
  //         _petCurrent_Location = LatLng(
  //           (_loc['lat'] ?? 0).toDouble(),
  //           (_loc['lng'] ?? 0).toDouble(),
  //         );
  //       }
  //     }
  //   });
  // }

  // Set custom marker for pet
  Future<void> _setCustomMarker() async {
    final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      'assets/images/pet_marker.png',
    );

    setState(() {
      _petMarker = Marker(
        markerId: const MarkerId('PetCurrent_Location'),
        position: _petCurrent_Location,
        infoWindow: const InfoWindow(title: '🐶 Pet _Location'),
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

  // Open _location in Google Maps app
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
    if (_safeZone_Location != null && _safeZoneRadius != null) {
      setState(() {
        _safeZoneCircle = Circle(
          circleId: const CircleId('safeZone'),
          center: _safeZone_Location!,
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
                  target: _petCurrent_Location,
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
                                : 'Have $_distanceFromSafeZone km From Safe Zone ⚠️',
                            style: TextStyle(
                              color: isPetInSafeZone
                                  ? Colors.green
                                  : Colors.red,
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
                        _safeZone_Location = LatLng(
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
                      _petCurrent_Location.latitude,
                      _petCurrent_Location.longitude,
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
