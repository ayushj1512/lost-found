import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  static Future<void> saveUserDataToFirestore({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String gender,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      rethrow;
    }
  }
}
