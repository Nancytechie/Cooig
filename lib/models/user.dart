import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  // ignore: non_constant_identifier_names
  final String full_name;
  final String image;
  final String bio;

  User({
    required this.id,
    // ignore: non_constant_identifier_names
    required this.full_name,
    required this.image,
    required this.bio,
  });

  /// Creates a User object from a Firestore document snapshot.
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      full_name: data['full_name'] ?? '', // Use empty string if not found
      image: data['image'] ?? '', // Use empty string if not found
      bio: data['bio'] ?? '', // Use empty string if not found
    );
  }

  /// Converts a User object to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': full_name,
      'image': image,
      'bio': bio,
    };
  }
}
