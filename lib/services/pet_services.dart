import 'package:cloud_firestore/cloud_firestore.dart';
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
