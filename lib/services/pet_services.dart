import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/pet_model.dart';

class PetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🐾 Fetch all pets from Firestore
  Future<List<Pet>> fetchAllPets() async {
    try {
      final snapshot = await _db.collection('pets').get();

      // Convert each document into a Pet object
      final pets = snapshot.docs.map((doc) {
        final data = doc.data();
        return Pet.fromMap(data);
      }).toList();

      print('✅ Fetched ${pets.length} pets from Firestore.');
      return pets;
    } catch (e) {
      print('❌ Error fetching pets: $e');
      return [];
    }
  }

  // update safezone to db
  Future<void> updateSafeZoneToDb({
    required String deviceId,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('pets').doc(deviceId).set({
        "safeZoneLocation": GeoPoint(latitude, longitude),
        "safeZoneRadius": radius,
        "updatedAt": DateTime.now(),
      }, SetOptions(merge: true));
      print('✅ Safe zone updated in DB for deviceId $deviceId');
    } catch (e) {
      print('❌ Error updating safe zone: $e');
    }
  }

  // register pet
  Future<bool> registerPet(Pet pet) async {
    try {
      await _db.collection('pets').doc(pet.deviceId).set(pet.toMap());
      // await _db.collection('users').doc(pet.userId).update({
      //   'pets': FieldValue.arrayUnion([pet.deviceId]),
      // });
      print('✅ Pet successfully registered!');
      return true;
    } catch (e) {
      print('❌ Error registering pet: $e');
      return false;
    }
  }
}

class RealtimePetService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetch pet live data by deviceId
  Future<Map<String, dynamic>?> fetchPetLive(String deviceId) async {
    try {
      final snapshot = await _db.child('pets_live/$deviceId').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('✅ pet live data fetched');
        return data;
      } else {
        print('⚠️ No pet live data found for deviceId $deviceId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching pet live data: $e');
      return null;
    }
  }

  // update safe zone to realtime db
  Future<void> updateSafeZoneToRealtimeDB({
    required String deviceId,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      await FirebaseDatabase.instance.ref("pets_live/$deviceId").update({
        'safeZoneLocation': {'lat': latitude, 'lon': longitude},
        'safeZoneRadius': radius,
        'isConnected': false,
        'isInSafeZone': true,
        'isPetSleep': false,
        'signalStrength': 0,
        'updatedAt': DateTime.now().toString(),
      });
      print('✅ Safe zone updated in Realtime DB for deviceId $deviceId');
    } catch (e) {
      print('❌ Error updating safe zone in Realtime DB: $e');
    }
  }

  // update Alert Message
Future<void> updateAlertMessageToRealtimeDB(
  String deviceId,
  Map<String, dynamic> message,
  int notificationCount,
) async {
  try {
    // Generate a timestamp-based key
    final now = DateTime.now();
    final formattedDate = "${now.year}${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}_"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}"
        "${now.second.toString().padLeft(2, '0')}";

    // Save the alert message
    await FirebaseDatabase.instance
        .ref("alert/$deviceId/$formattedDate")
        .set({
      'message': message["message"] ?? "",
      'createdAt': now.toIso8601String(),
    });

    // Update the notification count for this device
    await FirebaseDatabase.instance
        .ref("alert/notificationCount")
        .set(notificationCount + 1);

    print('✅ Alert saved for $deviceId at $formattedDate');
  } catch (e) {
    print('❌ Error updating Alert Message in Realtime DB: $e');
  }
}


  // Fetch notificaton from realtime db
  Future<Map<String, dynamic>?> fetchNotificationFromRealtimeDB() async {
    try {
      final snapshot = await _db.child('alert').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('✅ Notification data fetched');
        return data;
      } else {
        print('⚠️ No Notification data found');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching Notification data: $e');
      return null;
    }
  }
}

// MQTT Service for real-time communication
class MqttService {
  late MqttServerClient client;
  String currentDeviceId = "";

  // Callback for Flutter UI
  Function(Map<String, dynamic>)? onDeviceUpdate;

  // Connect to MQTT broker
  Future<void> connect() async {
    client = MqttServerClient('broker.hivemq.com', 'flutter_app_client');
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 30;

    client.onConnected = () => print('✅ Connected to MQTT broker');
    client.onDisconnected = () {
      print('❌ Disconnected from MQTT broker');
    };

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_app_client')
        .startClean();

    try {
      await client.connect();
    } catch (e) {
      print('MQTT connection failed: $e');
      client.disconnect();
      return;
    }

    // Listen for incoming messages
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final recMess = messages![0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      final data = jsonDecode(payload);
      if (onDeviceUpdate != null) onDeviceUpdate!(data);
    });
  }

  // Subscribe to a device
  void subscribeToDevice(String deviceId) {
    // Unsubscribe previous device
    if (currentDeviceId.isNotEmpty) {
      client.unsubscribe('pets_live/$currentDeviceId/data');
      print('Unsubscribed from $currentDeviceId');
    }
    // Subscribe new device
    currentDeviceId = deviceId;
    client.subscribe('pets_live/$deviceId/data', MqttQos.atMostOnce);
    print('Subscribed to $deviceId');
  }

  void subscribeDevicesForAlertService(List<String> devices) {
    if (currentDeviceId.isNotEmpty) {
      client.unsubscribe('pets_live/$currentDeviceId/alert');
      print('Unsubscribed from $currentDeviceId');
    }
    for (var device in devices) {
      client.subscribe('pets_live/$device/alert', MqttQos.atMostOnce);
      print('Subscribed to $device');
    }
  }

  // Send command to device
  void sendCommand(String deviceId, Map<String, dynamic> command) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(command));
    client.publishMessage(
      'pets_live/$deviceId/control',
      MqttQos.atMostOnce,
      builder.payload!,
    );
    print('📤 Sent command: $command to $deviceId');
  }

  /// reconnect logic

  void _reconnect() async {
    const retryDelay = Duration(seconds: 5);
    print('🔄 Attempting reconnect in 5 seconds...');
    await Future.delayed(retryDelay);
    try {
      await connect();
      if (currentDeviceId.isNotEmpty) {
        subscribeToDevice(currentDeviceId);
        print('✅ Reconnected and resubscribed to $currentDeviceId');
      }
    } catch (e) {
      print('❌ Reconnect failed: $e');
      _reconnect(); // keep retrying
    }
  }
}
