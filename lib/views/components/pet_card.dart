import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kazu/constants/app_colors.dart';
import 'package:kazu/services/pet_services.dart';
import 'package:kazu/views/pet_details.dart';

class PetCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final String deviceId;

  const PetCard({
    super.key,
    required this.name,
    required this.deviceId,
    this.imagePath = 'assets/images/dog1.png',
  });

  @override
  Widget build(BuildContext context) {
    RealtimePetService realtimePetService = RealtimePetService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: realtimePetService.fetchPetLive(deviceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error loading pet data');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Text('No pet data');
        }

        final petData = snapshot.data!;
        final LatLng safeZoneCoordinates = LatLng(
          petData['safeZoneLocation']['lat'] ?? 0.0,
          petData['safeZoneLocation']['lon'] ?? 0.0,
        );
        bool isPetInSafeZone = petData['isInSafeZone'] ?? true;
        double safeZoneRadius = petData['safeZoneRadius']?.toDouble() ?? 100.0;
        return Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isPetInSafeZone ? '🏠 Safe Zone' : '⚠️ Outside Zone',
                        style: TextStyle(
                          color: isPetInSafeZone ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetails(
                            name: name,
                            deviceId: deviceId,
                            imagePath: imagePath,
                            safeZoneCoordinates: safeZoneCoordinates,
                            safeZoneRadius:safeZoneRadius,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnBack,
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: AppColors.btnTextPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ElevatedButton(
                  //   onPressed: () {},
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: AppColors.divider,
                  //   ),
                  //   child: const Text('Track'),
                  // ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
