import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kazu/models/pet_model.dart';
import 'package:kazu/services/pet_services.dart';

final PetService _petService = PetService();
final RealtimePetService _realtimePetService = RealtimePetService();

/// Fetch all pets and return as a list of maps suitable for UI
Future<List<Map<String, dynamic>>> getPetDetails(String uId) async {
  List<Pet> pets = await _petService.fetchAllPets();

  // Filter pets that belong to the current user
  List<Pet> userPets = pets.where((pet) => pet.userId == uId).toList();

  // Convert each Pet object into a Map<String, dynamic>
  List<Map<String, dynamic>> petDetails = userPets.map((pet) {
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

// Register pet
Future<void> addNewPet(
  String userId,
  String deviceId,
  String petName,
  String petAge,
  String petType,
  Gender,
  LatLng safeZoneLocation,
  double safeZoneRadius,
) async {
  Pet newPet = Pet(
    deviceId: deviceId,
    userId: userId,
    name: petName,
    species: "",
    breed: "",
    age: double.tryParse(petAge) ?? 0.0,
    safeZoneLocation: safeZoneLocation, // LatLng from Google Maps
    safeZoneRadius: safeZoneRadius,
    lastLocation: LatLng(0.0, 0.0),
    totalWalkDistance: 0.0,
    isInsideSafeZone: true,
    dailyDistanceHistory: {},
    createdAt: DateTime.now(),
  );

  try {
    await _petService.registerPet(newPet);
    await _realtimePetService.updateSafeZoneToRealtimeDB(
      deviceId: deviceId,
      latitude: safeZoneLocation.latitude,
      longitude: safeZoneLocation.longitude,
      radius: safeZoneRadius,
    );

    print('✅ Pet successfully registered to firestore and realtime DB!');
  } catch (e) {
    print('❌ Error registering pet: $e');
  }
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

  Stream<Map<String, dynamic>> connectAndListenMultipleDevicesForAlertService(
    List<String> devices,
  ) {
    StreamController<Map<String, dynamic>> controller = StreamController();

    mqttService.connect().then((_) {
      mqttService.subscribeDevicesForAlertService(devices);

      mqttService.onDeviceUpdate = (alerts) {
        controller.add(alerts);
      };
    });
    return controller.stream;
  }
}

List<Map<String, dynamic>> getFilteredMessages(Map<String, dynamic> data) {
  List<Map<String, dynamic>> allMessages = [];
  data.forEach((key, value) {
    // Skip notification counter
    if (key == "notificationCount") return;

    // Cast value to Map<String, dynamic>
    if (value is Map) {
      final deviceMap = Map<String, dynamic>.from(value);
      deviceMap.forEach((msgId, msgData) {
        // Cast msgData to Map<String, dynamic>
        if (msgData is Map) {
          final msgMap = Map<String, dynamic>.from(msgData);
          final createdAtStr = msgMap["createdAt"]?.toString();
          if (createdAtStr == null) return;
          allMessages.add({
            "deviceId": key,
            "messageId": msgId,
            "createdAt": DateTime.parse(createdAtStr.replaceFirst(' ', 'T')),
            "message": msgMap["message"] ?? "",
          });
        }
      });
    } else {
      print("value is not a Map<String, dynamic> - ${value.runtimeType}");
    }
  });

  // Sort by createdAt descending
  allMessages.sort((a, b) => b["createdAt"].compareTo(a["createdAt"]));

  // Return latest 10 messages
  return allMessages.take(10).toList();
}
