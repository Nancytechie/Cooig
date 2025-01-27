import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/individual_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cooig_firebase/models/message.dart';
import 'package:cooig_firebase/services/imageview.dart';

class FavoritesScreen extends StatefulWidget {
  final String currentUserId;

  const FavoritesScreen({super.key, required this.currentUserId});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Stream<List<Message>> favoritesStream;

  @override
  void initState() {
    super.initState();
    favoritesStream = _fetchFavoriteMessages();
  }

  Stream<List<Message>> _fetchFavoriteMessages() {
    // Fetch all messages where isFavorite is true from any collection of messages
    return FirebaseFirestore.instance
        .collectionGroup(
            'messages') // Collection group to fetch messages across all conversations
        .where('isFavorite',
            isEqualTo: true) // Filter to only get favorite messages
        .snapshots()
        .map((snapshot) {
      // Map the Firestore snapshot to a list of Message objects
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  void _navigateToMessage(Message message) {
    // Navigate to the chat screen for the selected message
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualChatScreen(
          currentUserId: widget.currentUserId,
          chatUserId: message.fromId == widget.currentUserId
              ? message.toId
              : message.fromId,
          fullName: message.fromId == widget.currentUserId
              ? message.toId // Ideally, fetch the full name from the user
              : message.fromId, // Same here: fetch the name of the sender
          image:
              'https://via.placeholder.com/150', // Use a placeholder, replace with actual user image
          backgroundColor: Colors.white, // Set the background color
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorite Messages"),
      ),
      body: StreamBuilder<List<Message>>(
        stream: favoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator()); // Show loading while data is being fetched
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text("No favorite messages")); // No messages to show
          }

          final messages = snapshot.data!; // Get the list of favorite messages

          return ListView.builder(
            itemCount: messages.length, // Set the number of items in the list
            itemBuilder: (context, index) {
              final message = messages[index]; // Get each message from the list

              return ListTile(
                leading: _buildLeadingIcon(
                    message), // Add leading icon for each message type
                title: Text(
                  message.msg, // Display the message text
                  maxLines: 1,
                  overflow: TextOverflow
                      .ellipsis, // Show ellipsis if the message is too long
                ),
                subtitle: Text(
                  "${message.fromId == widget.currentUserId ? 'Sent' : 'Received'} - ${message.type}",
                ),
                onTap: () => _navigateToMessage(
                    message), // Navigate to the message's chat screen when tapped
              );
            },
          );
        },
      ),
    );
  }

  // This method returns an appropriate icon based on the message type
  Widget _buildLeadingIcon(Message message) {
    switch (message.type) {
      case 'image':
        return GestureDetector(
          onTap: () {
            // Open the image view when the image is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewScreen(imageUrl: message.msg),
              ),
            );
          },
          child: Image.network(
            message.msg, // Show the image from the URL
            width: 50,
            height: 50,
            fit: BoxFit.cover, // Ensure the image fits well within the box
          ),
        );
      case 'video':
        return Icon(Icons.video_library, color: Colors.blue); // Show video icon
      case 'audio':
        return Icon(Icons.audiotrack, color: Colors.green); // Show audio icon
      case 'document':
        return Icon(Icons.insert_drive_file,
            color: Colors.orange); // Show document icon
      default:
        return Icon(Icons.message,
            color: Colors.grey); // Default icon for other types of messages
    }
  }
}
