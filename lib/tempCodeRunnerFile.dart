import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MicScreen extends StatefulWidget {
  final Function(String) onSendRecording;

  const MicScreen({super.key, required this.onSendRecording});

  @override
  State<MicScreen> createState() => _MicScreenState();
}

class _MicScreenState extends State<MicScreen> {
  late FlutterSoundRecorder _recorder;
  bool _isRecorderInitialized = false;
  bool isRecording = false;
  String recordingDuration = "00:00";
  Timer? _timer;
  DateTime? _startTime;
  String? recordedFilePath;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission not granted')),
      );
      return;
    }
    await _recorder.openRecorder();
    setState(() => _isRecorderInitialized = true);
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    recordedFilePath =
        '${dir.path}/post_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
        toFile: recordedFilePath, codec: Codec.aacADTS);

    _startTime = DateTime.now();
    _startTimer();

    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    if (!_isRecorderInitialized || !isRecording) return;

    final path = await _recorder.stopRecorder();
    _timer?.cancel();

    final totalDuration = DateTime.now().difference(_startTime!).inSeconds;

    if (path != null) {
      final url = await uploadToFirebase(File(path), 'post_audios');
      widget.onSendRecording("$url?duration=$totalDuration");
    }

    setState(() {
      isRecording = false;
      recordingDuration = "00:00";
    });
  }

  Future<String> uploadToFirebase(File file, String folder) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child(folder).child(fileName);
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      throw e;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_startTime!);
      final min = elapsed.inMinutes.toString().padLeft(2, '0');
      final sec = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      setState(() {
        recordingDuration = "$min:$sec";
      });
    });
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isRecording ? "Recording..." : "Hold mic to record",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 20),
            if (isRecording)
              Text(
                recordingDuration,
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            SizedBox(height: 20),
            GestureDetector(
              onLongPress: startRecording,
              onLongPressUp: stopRecording,
              child: Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording ? Colors.red : Colors.grey[800],
                ),
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            if (isRecording) ...[
              SizedBox(height: 30),
              WaveWidget(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  stopRecording();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Cancel"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WaveWidget extends StatefulWidget {
  @override
  _WaveWidgetState createState() => _WaveWidgetState();
}

class _WaveWidgetState extends State<WaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final height =
                  (index % 2 == 0 ? _animation.value : 1 - _animation.value) *
                      20;
              return Container(
                width: 5,
                height: height,
                margin: EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
