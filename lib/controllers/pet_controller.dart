import 'dart:async';

import 'package:kazu/models/pet_model.dart';
import 'package:kazu/services/pet_services.dart';

final PetService _petService = PetService();

/// Fetch all pets and return as a list of maps suitable for UI
Future<List<Map<String, dynamic>>> getPetDetails() async {
  List<Pet> pets = await _petService.fetchAllPets();

  // Convert each Pet object into a Map<String, dynamic>
  List<Map<String, dynamic>> petDetails = pets.map((pet) {
    return {
      'deviceId': pet.deviceId,
      'userId': pet.userId,
      'name': pet.name,
      'species': pet.species,
      'breed': pet.breed,
      'age': pet.age,
      'safeZoneLocation': pet.safeZoneLocation,
      'safeZoneRadius': pet.safeZoneRadius,
      'lastLocation': pet.lastLocation,
      'totalWalkDistance': pet.totalWalkDistance,
      'dailyDistanceHistory': pet.dailyDistanceHistory,
      'isInsideSafeZone': pet.isInsideSafeZone,
      'createdAt': pet.createdAt,
    };
  }).toList();

  print('✅ Fetched ${petDetails.length} pets from DB');
  return petDetails;
}

/// Fetch live data form MQTT
class MqttHelper {
  final MqttService mqttService = MqttService();
  Timer? _timer;

  /// Connects to MQTT, subscribes to device, and returns a stream of live data
  Stream<Map<String, dynamic>> connectAndListen(String deviceId) {
    final StreamController<Map<String, dynamic>> controller =
        StreamController();

    mqttService.connect().then((_) {
      // Subscribe to the selected device
      mqttService.subscribeToDevice(deviceId);

      // Listen for live updates from MQTT
      mqttService.onDeviceUpdate = (data) {
        controller.add(data); // send data to stream
      };

      // Send initial connect command
      mqttService.sendCommand(deviceId, {"command": "connect"});
    });

    // Cancel timer when stream is closed
    controller.onCancel = () {
      _timer?.cancel();
    };

    return controller.stream;
  }
}
