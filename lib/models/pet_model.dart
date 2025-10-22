import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String deviceId;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final double? age;
  final LatLng safeZoneLocation;
  final double safeZoneRadius;
  final LatLng lastLocation;
  final double totalWalkDistance;
  final isInsideSafeZone;
  final Map<String, dynamic>? dailyDistanceHistory;
  final DateTime createdAt;

  Pet({
    required this.deviceId,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.age,
    required this.safeZoneLocation,
    required this.safeZoneRadius,
    required this.lastLocation,
    required this.totalWalkDistance,
    required this.isInsideSafeZone,
    this.dailyDistanceHistory,
    required this.createdAt,
  });

  /// ✅ Convert Firestore document to Pet model
  factory Pet.fromMap(Map<String, dynamic> data) {
    final safeZoneGeo = data['safeZoneLocation'] as GeoPoint;
    final lastLocationGeo = data['lastLocation'] as GeoPoint;

    return Pet(
      deviceId: data['deviceId'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      species: data['species'] ?? '',
      breed: data['breed'],
      age: (data['age'] != null) ? (data['age'] as num).toDouble() : null,
      safeZoneLocation: LatLng(safeZoneGeo.latitude, safeZoneGeo.longitude),
      safeZoneRadius: (data['safeZoneRadius'] as num?)?.toDouble() ?? 0.0,
      lastLocation: LatLng(lastLocationGeo.latitude, lastLocationGeo.longitude),
      totalWalkDistance: (data['totalWalkDistance'] as num?)?.toDouble() ?? 0.0,
      isInsideSafeZone: (data['isInsideSafeZone'] ?? true),
      dailyDistanceHistory: data['dailyDistanceHistory'] != null
          ? Map<String, dynamic>.from(data['dailyDistanceHistory'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// ✅ Convert Pet model back to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'userId': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'age': age,
      'safeZoneLocation': GeoPoint(
        safeZoneLocation.latitude,
        safeZoneLocation.longitude,
      ),
      'safeZoneRadius': safeZoneRadius,
      'lastLocation': GeoPoint(lastLocation.latitude, lastLocation.longitude),
      'totalWalkDistance': totalWalkDistance,
      'isInsideSafeZone': isInsideSafeZone,
      'dailyDistanceHistory': dailyDistanceHistory,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
