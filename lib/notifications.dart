import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';
import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  final String userId; // Pass the current user's ID

  const Notifications({super.key, required this.userId});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
      colors: [Color(0XFF9752C5), Color(0xFF000000)],
      radius: 0.5,
      centerAlignment: Alignment.bottomRight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Navigates back to the previous screen
            },
          ),
          title: const Text(
            "Notifications",
            style: TextStyle(fontSize: 24.0, color: Colors.white),
          ),
          centerTitle: false, // Align the title to the left
          backgroundColor: Colors.black,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          // Use FutureBuilder to return a list of notifications
          future: _getMockNotifications(), // Fetch mock notifications
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error loading notifications",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No notifications yet!",
                  style: TextStyle(color: Colors.white, fontSize: 18.0),
                ),
              );
            }

            final notifications = snapshot.data!;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return NotificationCard(notification: notification);
              },
            );
          },
        ),
      ),
    );
  }

  // Return mock notifications as Future
  Future<List<Map<String, dynamic>>> _getMockNotifications() async {
    // Mock notifications data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      {
        'user': 'Akshika',
        'type': 'Bond',
        'message': 'Builded bond with you',
        'timestamp': Timestamp.now(),
      },
      {
        'user': 'Disha',
        'type': 'like',
        'message': 'Liked your post.',
        'timestamp': Timestamp.now(),
      },
      {
        'user': 'Jiya',
        'type': 'comment',
        'message': 'Commented on your photo.',
        'timestamp': Timestamp.now(),
      },
      {
        'user': 'Bushra',
        'type': 'like',
        'message': 'Liked Your notes',
        'timestamp': Timestamp.now(),
      },
    ];
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({Key? key, required this.notification})
      : super(key: key);

  IconData _getIcon(String type) {
    switch (type) {
      case "Bond":
        return Icons.person_add_alt_1;
      case "like":
        return Icons.favorite;
      case "comment":
        return Icons.comment;
      case "reaction":
        return Icons.emoji_emotions;

      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(notification['profilepic'] ?? ''),
          backgroundColor: Colors.white.withOpacity(0.1),
        ),
        title: Text(
          notification['user'] ?? 'Unknown User',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins', // Custom font
          ),
        ),
        subtitle: Text(
          notification['message'] ?? '',
          style: const TextStyle(
            fontSize: 15.0,
            color: Colors.white70,
            fontFamily: 'Poppins', // Custom font
          ),
        ),
        trailing: Icon(
          _getIcon(notification['type'] ?? 'default'),
          color: Colors.purpleAccent,
        ),
        onTap: () {
          // Handle tap to show notification details or redirect
        },
      ),
    );
  }
}
