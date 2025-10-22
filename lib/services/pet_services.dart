import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
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
}
