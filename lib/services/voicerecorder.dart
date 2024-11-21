// import 'dart:async';
// import 'dart:math'; // For random waveform

// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: RecordingScreen(),
//     );
//   }
// }

// class RecordingScreen extends StatefulWidget {
//   @override
//   _RecordingScreenState createState() => _RecordingScreenState();
// }

// class _RecordingScreenState extends State<RecordingScreen> {
//   FlutterSoundRecorder? _recorder;
//   bool _isRecording = false;
//   String _timeText = "00:00";
//   Timer? _timer;
//   int _elapsedTime = 0;
//   String _filePath = '';
//   Random _random = Random();

//   @override
//   void initState() {
//     super.initState();
//     _recorder = FlutterSoundRecorder();
//     _requestPermissions();
//     _initRecorder();
//   }

//   // Request permissions
//   void _requestPermissions() async {
//     PermissionStatus status = await Permission.microphone.request();
//     if (!status.isGranted) {
//       print('Microphone permission denied');
//     }

//     PermissionStatus storageStatus = await Permission.storage.request();
//     if (!storageStatus.isGranted) {
//       print('Storage permission denied');
//     }
//   }

//   // Initialize the recorder
//   Future<void> _initRecorder() async {
//     try {
//       await _recorder!.openRecorder();
//       final tempDir = await getTemporaryDirectory();
//       _filePath = '${tempDir.path}/audio_recording.aac';
//     } catch (e) {
//       print('Error initializing recorder: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _recorder?.closeRecorder();
//     _timer?.cancel();
//     super.dispose();
//   }

//   // Start recording
//   void _startRecording() async {
//     try {
//       if (!_isRecording) {
//         await _recorder!.startRecorder(
//           toFile: _filePath,
//           codec: Codec.aacADTS,
//         );
//         setState(() {
//           _isRecording = true;
//           _elapsedTime = 0;
//           _timeText = "00:00"; // Reset timer text on start
//         });

//         _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//           if (_elapsedTime < 60) {
//             setState(() {
//               _elapsedTime++;
//               _timeText = _formatTime(_elapsedTime);
//             });
//           } else {
//             // Automatically stop recording after 1 minute
//             _stopRecording();
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("Maximum recording length is 1 minute.")),
//             );
//           }
//         });
//       }
//     } catch (e) {
//       print('Error starting recorder: $e');
//     }
//   }

//   // Stop recording
//   void _stopRecording() async {
//     try {
//       if (_isRecording) {
//         await _recorder!.stopRecorder();
//         _timer?.cancel(); // Cancel the timer
//         setState(() {
//           _isRecording = false;
//         });
//       }
//     } catch (e) {
//       print('Error stopping recorder: $e');
//     }
//   }

//   // Discard the recording
//   void _discardRecording() async {
//     if (_isRecording) {
//       _stopRecording(); // Ensure recording is stopped
//     }
//     setState(() {
//       _timeText = "00:00"; // Reset time display
//       _elapsedTime = 0; // Reset elapsed time
//     });
//     Navigator.pop(context); // Go back without sending
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Recording discarded.")),
//     );
//   }

//   // Format time in mm:ss format
//   String _formatTime(int seconds) {
//     int minutes = seconds ~/ 60;
//     int secs = seconds % 60;
//     return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
//   }

//   // Reset the recording state
//   void _resetRecording() {
//     _timer?.cancel(); // Cancel the timer on reset
//     setState(() {
//       _isRecording = false;
//       _timeText = "00:00";
//       _elapsedTime = 0;
//     });
//   }

//   // Simulate a random waveform (only visible when recording)
//   Widget _buildWaveform() {
//     if (_elapsedTime == 0 || !_isRecording) {
//       return Container(
//         height: 100,
//         color: Colors
//             .transparent, // Hide waveform when not recording or at time zero
//       );
//     }

//     return Container(
//       height: 100,
//       color: const Color.fromARGB(255, 0, 0, 0),
//       child: Row(
//         children: List.generate(50, (index) {
//           return Container(
//             width: 5,
//             height: 30 +
//                 _random.nextInt(50).toDouble(), // Random height for wave effect
//             color: Colors.white, // White waveform
//           );
//         }),
//       ),
//     );
//   }

//   // Send the recording file and displayed duration back to the chat screen
//   void _sendRecording() {
//     if (_elapsedTime < 1) {
//       // Show prompt for minimum recording length
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Recording must be at least 1 second long.")),
//       );
//       return;
//     }

//     Navigator.pop(context, {
//       'filePath': _filePath,
//       'duration': _timeText, // Use the displayed time as the duration
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         _discardRecording(); // Discard recording when back button is pressed
//         return false; // Prevent automatic navigation
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text("Audio Recording"),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back),
//             onPressed: _discardRecording, // Handle app bar back button
//           ),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Simulated waveform (visible only during recording)
//               _buildWaveform(),
//               SizedBox(height: 20),
//               Text(_timeText, style: TextStyle(fontSize: 30)),
//               SizedBox(height: 20),
//               // Start/Stop button
//               _isRecording
//                   ? IconButton(
//                       icon: Icon(Icons.stop,
//                           size: 60,
//                           color: const Color.fromARGB(255, 226, 17, 17)),
//                       onPressed: _stopRecording,
//                     )
//                   : IconButton(
//                       icon: Icon(Icons.mic, size: 60, color: Colors.green),
//                       onPressed: _startRecording,
//                     ),
//               SizedBox(height: 20),
//               Text(
//                 "Press the mic to start recording. You can record for up to 1 minute.",
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 20),
//               // Reset and Send buttons after stopping recording
//               if (!_isRecording) ...[
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: _resetRecording,
//                       icon: Icon(Icons.refresh),
//                       label: Text("Reset"),
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: _sendRecording,
//                       icon: Icon(Icons.send),
//                       label: Text("Send"),
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
