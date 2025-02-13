import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentsScreen extends StatefulWidget {
  final String postID;

  const CommentsScreen({super.key, required this.postID});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}
class _CommentsScreenState extends State<CommentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  List<Map<String, dynamic>> users = []; // List to hold all user data
  List<QueryDocumentSnapshot> comments = []; // List to hold all comments data

  Future<void> _addComment() async {
  if (_auth.currentUser == null) return;

  final String currentUserId = _auth.currentUser!.uid;
  final String commentText = _commentController.text.trim();

  if (commentText.isNotEmpty) {
    DocumentReference postRef = _firestore.collection('posts').doc(widget.postID);
    CollectionReference commentsRef = postRef.collection('comments');

    await commentsRef.add({
      'userId': currentUserId,
      'comment': commentText,
      'timestamp': Timestamp.now(),
    });

    _commentController.clear();

    // 🔥 Update comment count in the post document
    await postRef.update({
      'commentCount': FieldValue.increment(1),
    });

    _loadComments(); // Reload comments after adding one
  }
}

Future<void> _deleteComment(String commentId) async {
  DocumentReference postRef = _firestore.collection('posts').doc(widget.postID);
  CollectionReference commentsRef = postRef.collection('comments');

  await commentsRef.doc(commentId).delete();

  // 🔥 Decrement comment count
  await postRef.update({
    'commentCount': FieldValue.increment(-1),
  });

  _loadComments();
}

Future<void> _loadComments() async {
  try {
    // 🔥 Fetch comments
    final commentSnapshot = await _firestore
        .collection('posts')
        .doc(widget.postID)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    print('Fetched ${commentSnapshot.docs.length} comments');

    // ✅ Store comments safely
    comments = commentSnapshot.docs;

    setState(() {});
  } catch (e) {
    print('Error loading comments: $e');
  }
}


  @override
  void initState() {
    super.initState();
    _loadComments(); // Load comments and users when screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index].data() as Map<String, dynamic>;
                      final user = users.firstWhere(
                        (user) => user['uid'] == comment['userId'],
                        orElse: () => {},
                      );

                      final userName = user['full_name'] ?? 'Unknown';
                      final userImage = user['profilepic'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: userImage.isNotEmpty
                              ? NetworkImage(userImage)
                              : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                        ),
                        title: Text(userName),
                        subtitle: Text(comment['comment']),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}