import 'package:cloud_firestore/cloud_firestore.dart';
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
      radius: 0.6,
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
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .doc(widget.userId)
              .collection('userNotifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
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

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No notifications yet!",
                  style: TextStyle(color: Colors.white, fontSize: 18.0),
                ),
              );
            }

            final notifications = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification =
                    notifications[index].data() as Map<String, dynamic>;

                return NotificationCard(notification: notification);
              },
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({super.key, required this.notification});

  IconData _getIcon(String type) {
    switch (type) {
      case "follow":
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
          backgroundColor: Colors.white.withOpacity(0.1),
          child: Icon(
            _getIcon(notification['type'] ?? 'default'),
            color: Colors.purpleAccent,
          ),
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
        onTap: () {
          // Handle tap to show notification details or redirect
        },
      ),
    );
  }
}

class RadialGradientBackground extends StatelessWidget {
  final List<Color> colors;
  final double radius;
  final AlignmentGeometry centerAlignment;
  final Widget child;

  const RadialGradientBackground({
    super.key,
    required this.colors,
    required this.radius,
    required this.centerAlignment,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: colors,
          radius: radius,
          center: centerAlignment,
        ),
      ),
      child: child,
    );
  }
}
