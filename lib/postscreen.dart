import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostScreen extends StatelessWidget {
  final String userId;

  const PostScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Posts'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(userId)
            .collection('userPosts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              return PostWidget(post: post);
            },
          );
        },
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final QueryDocumentSnapshot post;

  const PostWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(post['images'] ?? []);
    final videos = List<String>.from(post['videos'] ?? []);
    final userProfileImage = post['profileImage']; // Assuming this is the URL
    final name = post['name'];
    final course = post['course'];
    final text = post['text'];
    final timestamp = post['timestamp'] as Timestamp?;
    final timeAgo =
        timestamp != null ? timeago.format(timestamp.toDate()) : 'Just now';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(userProfileImage),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      course,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                aspectRatio: 16 / 9,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
              ),
              items: [...images, ...videos].map((mediaUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    if (mediaUrl.endsWith('.mp4')) {
                      // Video handling (You can use a video player package like `video_player`)
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      );
                    } else {
                      // Image handling
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(mediaUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
