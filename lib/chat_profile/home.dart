import 'package:cooig_firebase/individual_chat_screen.dart';
import 'package:flutter/material.dart';
import 'theme.dart'; // Import the theme selection screen
import 'privacy.dart'; // Import the privacy screen
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for saving theme

class HomePage extends StatefulWidget {
  final String fullName;
  final String image;
  final String conversationId;
  final String currentUserId;
  final String userid;

  const HomePage({
    super.key,
    required this.fullName,
    required this.image,
    required this.conversationId,
    required this.currentUserId,
    required this.userid,
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
                  //       children: [
                  //         buildMenuOption(context, Icons.person, 'Profile', () {
                  //           Navigator.push(
                  //             context,
                  //             MaterialPageRoute(
                  //               builder: (context) => IndividualChatScreen(
                  //                 fullName: widget.fullName,
                  //                 image: widget.image,
                  //                 currentUserId: widget.currentUserId,
                  //                 chatUserId: widget.userid,
                  //                 backgroundColor: _selectedColor,
                  //               ),
                  //             ),
                  //           );
                  //         }),
                  //         buildMenuOption(context, Icons.apps, 'Theme', () {
                  //           Navigator.push(
                  //             context,
                  //             MaterialPageRoute(
                  //               builder: (context) => ThemeSelectionScreen(
                  //                 onThemeSelected: (Color selectedColor) {
                  //                   setState(() {
                  //                     _selectedColor = selectedColor;
                  //                   });
                  //                   _updateConversationBackgroundColor(selectedColor);
                  //                 },
                  //               ),
                  //             ),
                  //           );
                  //         }),
                  //         buildMenuOption(context, Icons.security, 'Privacy', () {
                  //           Navigator.push(
                  //             context,
                  //             MaterialPageRoute(
                  //               builder: (context) => PrivacyScreen(),
                  //             ),
                  //           );
                  //         }),
                  //       ],
                  ),
            ),
          ],
        ),
      ),
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
}
