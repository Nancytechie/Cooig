import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//storage sent and recieved both shouls be stored in the conversatiosn collection in storage
class MediaScreen extends StatelessWidget {
  final String
      conversationId; // Pass the conversation ID to fetch relevant data

  MediaScreen({required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Media'),
          bottom: TabBar(
            labelStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16.0),
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Media'),
              Tab(text: 'Documents'),
              Tab(text: 'Audio'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MediaTabContent(
              conversationId: conversationId,
              mediaType: ['image', 'video'], // Fetch images and videos
            ),
            MediaTabContent(
              conversationId: conversationId,
              mediaType: ['document'], // Fetch documents
            ),
            MediaTabContent(
              conversationId: conversationId,
              mediaType: ['audio'], // Fetch audio files
            ),
          ],
        ),
      ),
    );
  }
}

class MediaTabContent extends StatelessWidget {
  final String conversationId;
  final List<String> mediaType; // Specify the type of media to fetch

  MediaTabContent({required this.conversationId, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .where('type', whereIn: mediaType) // Filter messages by type
          .orderBy('sent', descending: true) // Order by sent timestamp
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading media.'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No media found.'));
        }

        final messages = snapshot.data!.docs;

        if (mediaType.contains('image') || mediaType.contains('video')) {
          // Display grid for images and videos
          return GridView.builder(
            padding: EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Number of columns in the grid
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final messageType = message['type'];
              final messageContent = message['msg'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenMediaPreview(
                        mediaUrl: messageContent,
                        isVideo: messageType == 'video',
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    messageContent,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image, size: 50),
                  ),
                ),
              );
            },
          );
        } else {
          // Display list for documents and audio
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final messageType = message['type'];
              final messageContent = message['msg'];
              final messageName =
                  message['msg'].split('/').last; // Extract file name

              if (mediaType.contains('document')) {
                // Display documents
                return ListTile(
                  leading: Icon(Icons.insert_drive_file, size: 40),
                  title: Text(
                    messageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // Open document viewer (implement this later)
                  },
                );
              } else if (mediaType.contains('audio')) {
                // Display audio files
                return ListTile(
                  leading: Icon(Icons.audiotrack, size: 40),
                  title: Text(
                    messageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // Play audio (implement this later)
                  },
                );
              }

              return SizedBox.shrink(); // Fallback for unsupported types
            },
          );
        }
      },
    );
  }
}

class FullScreenMediaPreview extends StatelessWidget {
  final String mediaUrl;
  final bool isVideo;

  FullScreenMediaPreview({required this.mediaUrl, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: isVideo
            ? Text('Video Preview: $mediaUrl') // Implement video player
            : Image.network(
                mediaUrl,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.broken_image, size: 100),
              ),
      ),
    );
  }
}
