import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cooig_firebase/notice/noticedetailscreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StarredPostsScreen extends StatefulWidget {
  const StarredPostsScreen({super.key});

  @override
  _StarredPostsScreenState createState() => _StarredPostsScreenState();
}

class _StarredPostsScreenState extends State<StarredPostsScreen> {
  final String userId = 'yourUserId'; // Replace with the actual user ID

  Future<void> _toggleStar(String postId, List<dynamic>? starredBy) async {
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('noticeposts').doc(postId);
    if (starredBy != null && starredBy.contains(userId)) {
      await postRef.update({
        'starredBy': FieldValue.arrayRemove([userId])
      });
    } else {
      await postRef.update({
        'starredBy': FieldValue.arrayUnion([userId])
      });
    }
  }

  void _showOptionsMenu(BuildContext context, String noticeId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNotice(noticeId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  final Stream<QuerySnapshot> _starredPostsStream = FirebaseFirestore.instance
      .collection('noticeposts')
      .where('isStarred', isEqualTo: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: Text(
          'Favorites',
          style: GoogleFonts.libreBodoni(
            textStyle: const TextStyle(
              color: Color.fromARGB(255, 254, 253, 255),
              fontSize: 26,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 195, 106, 240),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _starredPostsStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No starred posts available.'));
            }

            final documents = snapshot.data!.docs;

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final item = documents[index].data() as Map<String, dynamic>;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoticeDetailScreen(notice: item),
                      ),
                    );
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading with Event Date and Posting Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['heading'] ?? 'No Title Available',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_horiz,
                                  color: Colors.white),
                              onPressed: () {
                                _showOptionsMenu(context, item['id']);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Event Date: ${DateFormat('yyyy-MM-dd').format((item['dateTime'] as Timestamp).toDate())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Image Section
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item['imageUrl'] ?? '',
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // User Profile and Icons (Avatar + Username + Posted Date)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: item['profileImage'] != null &&
                                      item['profileImage'].isNotEmpty
                                  ? NetworkImage(item['profileImage'])
                                  : const AssetImage(
                                          'assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['postedBy'] ?? 'Unknown User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                if (item['postedDate'] != null &&
                                    item['postedDate'] is Timestamp)
                                  Text(
                                    'Posted on: ${DateFormat('yyyy-MM-dd').format((item['postedDate'] as Timestamp).toDate())}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Posted on: Unknown Date',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                item['starredBy'] != null &&
                                        item['starredBy'].contains(userId)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.yellow,
                              ),
                              onPressed: () {
                                _toggleStar(item['id'], item['starredBy']);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _deleteNotice(String noticeId) {
    FirebaseFirestore.instance.collection('noticeposts').doc(noticeId).delete();
  }

  void _shareNotice(String heading, String imageUrl) {
    // Share notice functionality
  }
}
