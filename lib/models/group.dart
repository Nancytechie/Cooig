import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<String> memberIds;
  final DateTime createdAt;
  final String createdBy;

  Group({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.memberIds,
    required this.createdAt,
    required this.createdBy,
  });

  /// Creates a Group object from a Firestore document snapshot.
  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '', // Default to empty string if not found
      imageUrl: data['image'] ?? '', // Default to empty string if not found
      description: data['description'] ?? '', // Default to empty string if not found
      memberIds: List<String>.from(data['memberIds'] ?? []), // Default to empty list if not found
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '', // Default to empty string if not found
    );
  }

  /// Converts a Group object to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': imageUrl,
      'description': description,
      'memberIds': memberIds,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}
