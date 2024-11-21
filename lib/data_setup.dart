// data_setup.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createSampleGroup() async {
  CollectionReference groups = FirebaseFirestore.instance.collection('groups');
  
  // Retrieve users from Firestore
  QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').get();
  List<QueryDocumentSnapshot> userDocs = userSnapshot.docs;
  
  if (userDocs.length < 3) {
    print("Not enough users to create the group.");
    return;
  }

  // Create a single group with three members
  Map<String, dynamic> groupData = {
    'name': 'Sample Group',
    'description': 'A group containing three sample users.',
    'imageUrl': 'https://via.placeholder.com/150?text=SampleGroup',
    'members': [userDocs[0].id, userDocs[1].id, userDocs[2].id], // First three users
    'createdBy': userDocs[0].id,
  };

  DocumentReference groupDoc = await groups.add(groupData);

  // Add sample messages to the group
  await createSampleMessages(groupDoc.id, userDocs);
  print("Sample group and messages created!");
}

Future<void> createSampleMessages(String groupId, List<QueryDocumentSnapshot> userDocs) async {
  CollectionReference messages = FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('messages');

  // Sample messages data
  List<Map<String, dynamic>> messageData = [
    {
      'fromId': userDocs[0].id, // User 1
      'toId': groupId,
      'msg': 'Hello everyone!',
      'type': 'text',
      'read': false,
      'sent': FieldValue.serverTimestamp(),
    },
    {
      'fromId': userDocs[1].id, // User 2
      'toId': groupId,
      'msg': 'Hi there!',
      'type': 'text',
      'read': false,
      'sent': FieldValue.serverTimestamp(),
    },
    {
      'fromId': userDocs[2].id, // User 3
      'toId': groupId,
      'msg': 'Good to be here!',
      'type': 'text',
      'read': false,
      'sent': FieldValue.serverTimestamp(),
    },
  ];

  for (var message in messageData) {
    await messages.add(message);
  }
}
