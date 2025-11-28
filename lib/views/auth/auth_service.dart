import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _firestore = FirebaseFirestore.instance;

  /// Saves user info to Firestore
  static Future<bool> saveUserToFirestore(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      final data = {
        'uid': user.uid,
        'email': user.email ?? '',
        'pets': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await userDoc.set(data, SetOptions(merge: true));
      return true; // Saved successfully
    } catch (e) {
      print('Error saving user to Firestore: $e');
      return false; // Failed
    }
  }
}
