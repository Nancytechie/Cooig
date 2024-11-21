import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isRecording = false;
  late List<CameraDescription> cameras;
  Timer? _timer;
  Duration _recordDuration = Duration();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      var cameraStatus = await Permission.camera.request();
      var microphoneStatus = await Permission.microphone.request();

      if (cameraStatus.isGranted && microphoneStatus.isGranted) {
        cameras = await availableCameras();
        _cameraController = CameraController(cameras[0], ResolutionPreset.high);
        await _cameraController!.initialize();

        if (mounted) {
          setState(() {});
        }
      } else {
        _showError('Camera or microphone permission not granted');
      }
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        // Navigate to image preview screen with the captured image
        Navigator.pushNamed(context, '/imageOptions',
            arguments: {'imageFile': image});
      } catch (e) {
        _showError('Error capturing photo: $e');
      }
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.startVideoRecording();
        _startTimer();
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        _showError('Error starting video recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      try {
        final video = await _cameraController!.stopVideoRecording();
        _timer?.cancel();
        setState(() {
          _isRecording = false;
          _recordDuration = Duration();
        });
        // Navigate to video preview screen with the recorded video
        Navigator.pushNamed(context, '/videoOptions', arguments: video);
      } catch (e) {
        _showError('Error stopping video recording: $e');
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _recordDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _switchCamera() async {
    if (cameras.length > 1) {
      final newCamera = _cameraController!.description.lensDirection ==
              CameraLensDirection.front
          ? cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back)
          : cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front);

      await _cameraController?.dispose();
      _cameraController = CameraController(newCamera, ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {});
    } else {
      _showError('No secondary camera found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cameraController!),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_tabController.index == 0) {
                            _capturePhoto(); // Capture photo only in Photo tab
                          } else {
                            if (_isRecording) {
                              _stopRecording(); // Stop recording if already recording
                            } else {
                              _startRecording(); // Start recording if not recording
                            }
                          }
                        },
                        child: Icon(
                          Icons.camera,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _tabController.index == 0
                            ? 'Click to shoot'
                            : _isRecording
                                ? 'Recording...'
                                : 'Hold to record',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Icon(Icons.switch_camera,
                        color: Colors.white, size: 40),
                    onPressed: _switchCamera,
                  ),
                ),
                if (_isRecording)
                  Positioned(
                    top: 30,
                    left: 20,
                    child: Text(
                      '${_recordDuration.inMinutes}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Photo'),
                      Tab(text: 'Video'),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }
}
