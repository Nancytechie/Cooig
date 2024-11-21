import 'package:cooig_firebase/individual_chat_screen.dart';
import 'package:flutter/material.dart';
import 'theme.dart'; // Import the theme selection screen
import 'media.dart'; // Import the media screen
import 'favourites.dart'; // Import the favourites screen
import 'privacy.dart'; // Import the privacy screen
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for saving theme
// Import for the chat screen

class HomePage extends StatefulWidget {
  final String fullName;
  final String image;
  final String conversationId;
  final String currentUserId; // Add this parameter

  HomePage({
    required this.fullName,
    required this.image,
    required this.conversationId,
    required this.currentUserId, // Initialize it
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color _selectedColor = Colors.white; // Default background color

  @override
  void initState() {
    super.initState();
    _fetchBackgroundColor(); // Fetch the current background color from Firestore
  }

  Future<void> _fetchBackgroundColor() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _selectedColor =
              Color(snapshot.data()?['backgroundColor'] ?? Colors.white.value);
        });
      }
    } catch (e) {
      print("Error fetching background color: $e");
    }
  }

  void _updateConversationBackgroundColor(Color color) {
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
      'backgroundColor': color.value, // Save the color value
    }).then((_) {
      print("Background color updated successfully");
    }).catchError((error) {
      print("Error updating background color: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.image),
            ),
            SizedBox(height: 10),
            Text(
              widget.fullName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  buildMenuOption(context, Icons.person, 'Profile', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IndividualChatScreen(
                          fullName: widget.fullName,
                          image: widget.image,
                          currentUserId: 'your_current_user_id_here',
                          chatUserId: 'chat_user_id_here',
                          backgroundColor: _selectedColor,
                        ),
                      ),
                    );
                  }),
                  buildMenuOption(context, Icons.apps, 'Theme', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThemeSelectionScreen(
                          onThemeSelected: (Color selectedColor) {
                            setState(() {
                              _selectedColor = selectedColor;
                            });
                            _updateConversationBackgroundColor(selectedColor);
                          },
                        ),
                      ),
                    );
                  }),
                  buildMenuOption(context, Icons.image, 'Media', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaScreen(
                          conversationId: widget.conversationId,
                        ),
                      ),
                    );
                  }),
                  buildMenuOption(context, Icons.star, 'Favourites', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FavoritesScreen(
                              currentUserId: widget.currentUserId)),
                    );
                  }),
                  buildMenuOption(context, Icons.security, 'Privacy', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrivacyScreen(),
                      ),
                    );
                  }),
                  buildMenuOption(context, Icons.notifications_off, 'Mute', () {
                    _showMuteOptions(context);
                  }),
                  buildMenuOption(context, Icons.search, 'Search', () {
                    print('Search tapped');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      // Apply the selected background color
    );
  }

  Widget buildMenuOption(BuildContext context, IconData icon, String title,
      [VoidCallback? onTap]) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showMuteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mute Notifications For:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text('For an Hour'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  print('Muted for an hour');
                },
              ),
              ListTile(
                leading: Icon(Icons.today),
                title: Text('For a Day'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  print('Muted for a day');
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('For a Week'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  print('Muted for a week');
                },
              ),
              ListTile(
                leading: Icon(Icons.volume_off),
                title: Text('Until I Unmute'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  print('Muted until unmuted');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
