import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MicScreen extends StatefulWidget {
  @override
  _MicScreenState createState() => _MicScreenState();
}

class _MicScreenState extends State<MicScreen> with TickerProviderStateMixin {
  bool isRecording = false;
  String? _filePath;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  late AnimationController _micMovementController;
  late Animation<double> _micMovementAnimation;

  // Dummy recorder object
  dynamic _recorder;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();

    // Ripple animation controller
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _rippleAnimation = Tween<double>(begin: 0, end: 120).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Mic movement animation controller
    _micMovementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 10.0,
    );

    _micMovementAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _micMovementController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder?.openRecorder();
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<void> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath =
        '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp4';

    try {
      // Start recording (dummy logic here)
      await _recorder?.startRecorder(toFile: _filePath, codec: Codec.aacMP4);
      setState(() {
        isRecording = true;
        _rippleController.repeat(); // Start ripple animation
        _micMovementController.repeat(reverse: true); // Start mic movement
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      await _recorder?.stopRecorder();
      setState(() {
        isRecording = false;
        _rippleController.stop(); // Stop ripple animation
        _micMovementController.stop(); // Stop mic movement
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _micMovementController.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta! > 0) {
          // Swipe right to start recording
          if (!isRecording) startRecording();
        } else if (details.primaryDelta! < 0) {
          // Swipe left to stop recording
          if (isRecording) stopRecording();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Ripple effect
            if (isRecording)
              Center(
                child: AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return Container(
                      width: _rippleAnimation.value * 2,
                      height: _rippleAnimation.value * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    );
                  },
                ),
              ),

            // Microphone icon with movement animation
            Center(
              child: AnimatedBuilder(
                animation: _micMovementAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _micMovementAnimation.value),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Fake waveform animation
            if (isRecording)
              Positioned(
                bottom: 200,
                left: 0,
                right: 0,
                child: Center(
                  child: CustomPaint(
                    painter: WaveformPainter(),
                    size: const Size(300, 100),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final random = Random();

    for (double i = 0; i < size.width; i += 10) {
      final y = size.height / 2 + random.nextInt(30).toDouble() * sin(i / 20);
      path.lineTo(i, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
