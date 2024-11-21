import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches a list of users based on the search name.
  Stream<List<User>> fetchUsers(String searchName) {
    return _db
        .collection('users')
        .orderBy('full_name') // Ensure that you're ordering by the correct field
        .startAt([searchName])
        .endAt([searchName + '\uf8ff']) // Use '\uf8ff' to match all possible suffixes
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromFirestore(doc))
            .toList());
  }

  /// Retrieves a user by their unique user ID.
  Future<User?> getUserById(String userId) async {
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null; // Return null if the user is not found
  }

  /// Updates the user's profile information in Firestore.
  Future<void> updateUserProfile(User user) async {
    await _db.collection('users').doc(user.id).update({
      'full_name': user.full_name,
      'image': user.image,
      'bio': user.bio,
    });
  }
}
