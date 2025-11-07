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
