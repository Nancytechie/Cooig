import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import for Firestore

class VideoCallScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const VideoCallScreen(
      {super.key, required this.userId, required this.userName});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _cameraController;
  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isVideoOff = false;
  bool isFrontCamera = true;
  String _profileImageUrl = ''; // For profile image URL

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
    _initializeCamera();
  }

  // Fetch profile image URL from Firestore
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

  // Initialize camera feed with front camera
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(frontCamera, ResolutionPreset.high);
    await _cameraController!.initialize();
    setState(() {});
  }

  // Switch camera between front and back
  void _switchCamera() async {
    final cameras = await availableCameras();
    final newCamera = isFrontCamera
        ? cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back)
        : cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front);

    _cameraController = CameraController(newCamera, ResolutionPreset.high);
    await _cameraController!.initialize();
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  // Turn off video feed
  void _turnOffVideo() {
    setState(() {
      isVideoOff = true;
    });
    _cameraController?.dispose();
    _cameraController = null;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.grey[850]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Camera Feed or Placeholder
          if (isVideoOff)
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.black54,
                child: Text(
                  'You turned off your camera',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!)
          else
            Center(child: CircularProgressIndicator()),

          // Profile Picture and User Name
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImageUrl.isNotEmpty
                      ? NetworkImage(_profileImageUrl)
                      : AssetImage('assets/default_profile.png')
                          as ImageProvider,
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(height: 10),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Dialing...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Buttons
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side buttons: Mute and Speaker
                Column(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        icon: Icon(
                          isMuted ? Icons.mic_off : Icons.mic,
                          size: 40,
                          color: isMuted ? Colors.purple : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            isMuted = !isMuted;
                          });
                        },
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        icon: Icon(
                          isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          size: 40,
                          color: isSpeakerOn ? Colors.purple : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            isSpeakerOn = !isSpeakerOn;
                          });
                        },
                      ),
                    ),
                  ],
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
                    // End call logic
                    Navigator.pop(context);
                  },
                ),

                // Right side buttons: Video Off and Switch Camera
                Column(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        icon: Icon(
                          isVideoOff ? Icons.videocam_off : Icons.videocam,
                          size: 40,
                          color: isVideoOff ? Colors.purple : Colors.white,
                        ),
                        onPressed: () {
                          if (!isVideoOff) {
                            _turnOffVideo();
                          } else {
                            // Logic to turn on the video feed
                            _initializeCamera();
                            setState(() {
                              isVideoOff = false;
                            });
                          }
                        },
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        icon: Icon(
                          Icons.switch_camera,
                          size: 40,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _switchCamera();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
