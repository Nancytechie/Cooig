import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String fromId;
  final String toId;
  String msg;
  final String? fileUrl; // URL of file (image/video/document)
  final String type; // Message type: text, image, video, document, etc.
  final bool read;
  final DateTime sent;
  final String? fileType; // Type of the file (image, video, document)
  final List<String>? reactions; // Reactions (e.g., emojis) for the message
  final String? repliedTo; // Replied message's ID, if any
  final String? messageId; // Unique message ID
  bool isEdited;
  DateTime? editedAt;
  bool isForwarded;
  bool isFavorite;
  final String? postId; // For post sharing
  final List<String>? mediaUrls; // For post sharing
  final String? userName; // For post sharing
  final String? userImage; // For post sharing

  // Typing-related fields (conversation-level, not per-message)
  bool isTyping;
  String? typingUser;
  final List<String>? deletedFor;

  // New field for theme color
  final String? themeColor; // Hex color or theme identifier

  // Constructor
  Message({
    required this.fromId,
    required this.toId,
    required this.msg,
    this.fileUrl,
    required this.type,
    required this.read,
    required this.sent,
    this.fileType,
    this.reactions,
    this.repliedTo,
    this.messageId,
    this.isEdited = false,
    this.editedAt,
    this.isForwarded = false,
    this.isFavorite = false,
    this.isTyping = false,
    this.typingUser,
    this.themeColor,
    this.deletedFor,
    this.postId,
    this.mediaUrls,
    this.userName,
    this.userImage,
  });

  // Factory method to create a Message object from Firestore document snapshot
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Message(
      fromId: data['fromId'] ?? '',
      toId: data['toId'] ?? '',
      msg: data['msg'] ?? '',
      fileUrl: data['fileUrl'],
      type: data['type'] ?? 'text', // Default type is text
      read: data['read'] ?? false,
      sent: (data['sent'] as Timestamp).toDate(),
      fileType: data['fileType'],
      reactions:
          data['reactions'] != null ? List<String>.from(data['reactions']) : [],
      repliedTo: data['repliedTo'],
      messageId: doc.id,
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      isForwarded: data['isForwarded'] ?? false,
      isFavorite: data['isFavorite'] ?? false,
      isTyping: data['isTyping'] ?? false,
      typingUser: data['typingUser'],
      themeColor: data['themeColor'],
      deletedFor: List<String>.from(data['deletedFor'] ?? []),
      postId: data['postId'],
      mediaUrls: data['mediaUrls'] != null
          ? List<String>.from(data['mediaUrls'])
          : null,
      userName: data['userName'],
      userImage: data['userImage'],
    );
  }

  // Method to convert a Message object to Firestore-compatible format
  Map<String, dynamic> toMap() {
    return {
      'fromId': fromId,
      'toId': toId,
      'msg': msg,
      'fileUrl': fileUrl,
      'type': type,
      'read': read,
      'sent': Timestamp.fromDate(sent),
      'fileType': fileType,
      'reactions': reactions,
      'repliedTo': repliedTo,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isForwarded': isForwarded,
      'isFavorite': isFavorite,
      'isTyping': isTyping,
      'typingUser': typingUser,
      'themeColor': themeColor,
      'deletedFor': deletedFor ?? [],
      'postId': postId,
      'mediaUrls': mediaUrls,
      'userName': userName,
      'userImage': userImage,
    };
  }

  void updateTypingStatus(bool typing, String? user) {
    isTyping = typing;
    typingUser = typing ? user : null;
  }

  // Method to edit the message content
  void editMessage(String newContent) {
    msg = newContent;
    isEdited = true;
    editedAt = DateTime.now();
  }

  // Method to toggle the favorite status
  void toggleFavorite(String conversationId) {
    if (conversationId.isEmpty || messageId == null) {
      print(
          'Error: Missing conversationId or messageId while toggling favorite.');
      return;
    }

    isFavorite = !isFavorite;

    FirebaseFirestore.instance
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isFavorite': isFavorite}).catchError((error) {
      print('Error updating favorite status in Firestore: $error');
    });
  }

  // Method to add a reaction to the message
  void addReaction(String emoji) {
    reactions?.add(emoji);
  }

  // Method to handle file types (image, video, document)
  bool isFileMessage() {
    return type == 'image' || type == 'video' || type == 'document';
  }
}