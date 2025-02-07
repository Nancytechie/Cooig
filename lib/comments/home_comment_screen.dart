import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:sliding_up_panel/sliding_up_panel.dart';

class CommentSection extends StatefulWidget {
  // post id logic addition
  final String userId;
  final String? username;

  const CommentSection({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  // Function to add comment to Firestore
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    final userProfileImage = userDoc.data()?['profilepic'] ?? '';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.userId) //post id se fetch
        .collection('comments')
        .add({
      'userId': widget.userId,
      'username': widget.username,
      'userProfileImage': userProfileImage,
      'text': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  // Function to convert the timestamp into a human-readable format (time ago)
  String timeAgo(Timestamp timestamp) {
    final DateTime commentTime = timestamp.toDate();
    final DateTime currentTime = DateTime.now();
    final Duration difference = currentTime.difference(commentTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Comments",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 103, 57, 114),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.userId)
                  .collection('comments')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet."));
                }

                final comments = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment =
                        comments[index].data() as Map<String, dynamic>;

                    final commentTimestamp = comment['timestamp'] as Timestamp;
                    final commentTimeAgo =
                        timeAgo(commentTimestamp); // Calculate time ago

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment['userProfileImage'] != null
                            ? NetworkImage(comment['userProfileImage'])
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                        radius: 20,
                      ),
                      title: Text(
                        comment['username'] ?? "Unknown User",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        comment['text'] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      trailing: Text(
                        commentTimeAgo, // Display the calculated time ago
                        style: const TextStyle(
                            color: Color.fromARGB(255, 201, 200, 200),
                            fontSize: 12),
                      ),
                    );
                  },
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
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color.fromARGB(
                          255, 63, 65, 67), // Background color of TextField
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(20.0), // Circular border
                        borderSide: BorderSide.none, // Remove the border line
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 15.0),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color.fromARGB(255, 200, 133, 226)),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
