import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceCallScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const VoiceCallScreen(
      {super.key, required this.userId, required this.userName});

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  String _profileImageUrl = ''; // Profile image URL
  bool _isSpeakerOn = false; // Speaker state
  bool _isMuted = false; // Mute state

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

  // Fetch profile image from Firestore
  Future<void> _fetchProfileImage() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc['image'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade800, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User's profile picture
              CircleAvatar(
                radius: 70,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : AssetImage('assets/default_profile.png') as ImageProvider,
                backgroundColor: Colors.grey[300],
              ),
              SizedBox(height: 30), // Increased space for better layout

              // User's name
              Text(
                widget.userName,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              // Calling text
              Text(
                'Calling...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                ),
              ),
              Spacer(),

              // Mute, Speaker, and End Call buttons with animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button with animation and icon change
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      height: _isMuted ? 60 : 50,
                      width: _isMuted ? 60 : 50,
                      decoration: BoxDecoration(
                        color:
                            _isMuted ? Colors.red.shade300 : Colors.grey[800],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                        size: _isMuted ? 40 : 35,
                      ),
                    ),
                  ),

                  // End call button
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      // End call logic here
                      Navigator.pop(context); // Pop the screen to end the call
                    },
                  ),

                  // Speaker button with animation and color change
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      height: _isSpeakerOn ? 60 : 50,
                      width: _isSpeakerOn ? 60 : 50,
                      decoration: BoxDecoration(
                        color: _isSpeakerOn
                            ? Colors.purpleAccent
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: _isSpeakerOn ? 40 : 35,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
