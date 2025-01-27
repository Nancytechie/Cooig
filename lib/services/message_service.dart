import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Creates or retrieves a conversation ID based on two user IDs.
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    final conversationId = userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
    final docRef = _db.collection('conversations').doc(conversationId);

    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'users': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return conversationId;
  }

  // Fetches messages in a conversation, ordered by the 'sent' timestamp.
  Stream<List<Message>> fetchMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sent', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  // Sends a message to the specified conversation.
  Future<void> sendMessage(String conversationId, Message message) async {
    if (message.msg.isEmpty && message.fileUrl == null) {
      throw Exception('Message content cannot be empty.');
    }

    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      print('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Edits an existing message and updates Firestore.
  Future<void> editMessage(
      String conversationId, String messageId, String newContent) async {
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'msg': newContent,
        'isEdited': true,
        'editedAt': DateTime.now(), // Store the edit timestamp
      });
    } catch (e) {
      print('Failed to edit message: $e');
      throw Exception('Failed to edit message: $e');
    }
  }

  // Updates an existing message in Firestore.
  Future<void> updateMessage(
      String conversationId, String messageId, Message updatedMessage) async {
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update(updatedMessage.toMap());
    } catch (e) {
      print('Failed to update message: $e');
      throw Exception('Failed to update message: $e');
    }
  }

  // Marks a message as read.
  Future<void> markMessageAsRead(
      String conversationId, String messageId) async {
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'read': true,
        'readTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to mark message as read: $e');
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Updates the read status of a message in Firestore.
  Future<void> updateMessageReadStatus(
      String conversationId, String messageId, bool readStatus) async {
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'read': readStatus});
    } catch (e) {
      print('Error updating message read status: $e');
      throw Exception("Failed to update message read status");
    }
  }

  // Uploads a file to Firebase Storage and returns its URL.
  Future<String> uploadFile(File file, String chatUserId, String conversationId,
      String folder) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final ref = _storage
          .ref()
          .child('conversations/$conversationId/$chatUserId/$folder/$fileName');

      final snapshot = await ref.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('File upload error: $e');
      throw Exception('File upload failed: $e');
    }
  }

  // Sends a media message by uploading the file first.
  Future<void> sendMediaMessage(String conversationId, File file,
      String fileType, String folder, Message message) async {
    try {
      final fileUrl =
          await uploadFile(file, message.fromId, conversationId, folder);

      if (fileUrl.isNotEmpty) {
        final mediaMessage = Message(
          msg: '',
          fromId: message.fromId,
          toId: message.toId,
          type: fileType,
          fileUrl: fileUrl,
          fileType: fileType,
          read: false,
          sent: DateTime.now(),
          repliedTo: message.repliedTo,
        );

        await sendMessage(conversationId, mediaMessage);
      }
    } catch (e) {
      print('Error sending media message: $e');
      throw Exception('Error sending media message: $e');
    }
  }

  // Adds a reaction to a specific message.
  Future<void> addReaction(
      String conversationId, String messageId, String emoji) async {
    final docRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    try {
      final docSnapshot = await docRef.get();
      final reactions = docSnapshot['reactions'] as List<String>? ?? [];

      reactions.add(emoji);
      await docRef.update({'reactions': reactions});
    } catch (e) {
      print('Failed to add reaction: $e');
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Fetches a list of all messages in a conversation.
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final querySnapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('sent')
          .get();

      return querySnapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Failed to get messages: $e');
      return [];
    }
  }

  // Fetches a message by its ID.
  Future<Message?> getMessageById(
      String conversationId, String messageId) async {
    try {
      final doc = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();
      if (doc.exists) {
        return Message.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting message by ID: $e');
      return null;
    }
  }
}
