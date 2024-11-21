import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class MusicPreviewScreen extends StatefulWidget {
  final File selectedImage;
  final String musicUrl;
  final Map<String, dynamic> trackInfo;
  final Duration initialPosition;
  final bool autoPlay;
  final AudioPlayer audioPlayer; // Receive the same player instance

  const MusicPreviewScreen({
    super.key,
    required this.selectedImage,
    required this.musicUrl,
    required this.trackInfo,
    required this.initialPosition,
    this.autoPlay = true,
    required this.audioPlayer, // Use the same player instance
  });

  @override
  _MusicPreviewScreenState createState() => _MusicPreviewScreenState();
}

class _MusicPreviewScreenState extends State<MusicPreviewScreen> {
  late AudioPlayer _player;
  double _startValue = 0;
  double _endValue = 15; // Max story duration in seconds
  Duration _songDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false; // Track if the player is playing
  bool _userInteraction =
      false; // Track if the slider has been adjusted by user

  @override
  void initState() {
    super.initState();
    _player = widget.audioPlayer; // Use the passed AudioPlayer instance
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _songDuration = _player.duration ?? Duration.zero;

      _player.positionStream.listen((position) {
        if (_userInteraction) {
          return; // Ignore auto-seek when user is interacting with slider
        }

        setState(() {
          _currentPosition = position;
        });

        // Check if current position exceeds the end point
        if (_currentPosition.inSeconds >= _endValue) {
          _player.pause();
          _player.seek(Duration(seconds: _startValue.toInt()));
          setState(() {
            _isPlaying = false;
          });
        }
      });

      if (widget.autoPlay) {
        _player.seek(widget.initialPosition);
        setState(() {
          _isPlaying = true; // Set play button to show as playing
        });
      }
    } catch (e) {
      print('Error initializing player: $e');
    }
  }

  @override
  void dispose() {
    super.dispose(); // Do not dispose the player here as it's shared
  }

  void _handlePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.seek(Duration(
          seconds:
              _startValue.toInt())); // Seek to start position before playing
      await _player.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _handleSliderStartChange(double start) async {
    setState(() {
      _startValue = start;
      _userInteraction = true; // User is interacting with the slider
    });
    await _player.seek(Duration(
        seconds:
            _startValue.toInt())); // Seek to the new start position immediately
    if (_isPlaying) {
      await _player
          .play(); // Resume playing immediately from the start position
    }
  }

  void _handleSliderEndChange(double end) {
    setState(() {
      _endValue = end;
    });
  }

  void _handleSliderInteractionEnd() async {
    if (_isPlaying) {
      await _player.seek(Duration(
          seconds: _startValue
              .toInt())); // Seek and start playing after slider interaction
      _player.play();
    }
    setState(() {
      _userInteraction = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Music'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              Navigator.pop(context, {'start': _startValue, 'end': _endValue});
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Image.file(
            widget.selectedImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trackInfo['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    widget.trackInfo['artist'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 20,
            right: 20,
            child: Center(
              child: _songDuration.inSeconds > 0
                  ? SfRangeSlider(
                      min: 0.0,
                      max: _songDuration.inSeconds.toDouble(),
                      values: SfRangeValues(_startValue, _endValue),
                      onChanged: (SfRangeValues newValues) {
                        _handleSliderStartChange(newValues.start);
                        _handleSliderEndChange(newValues.end);
                      },
                      onChangeEnd: (_) {
                        _handleSliderInteractionEnd(); // Reset the user interaction flag
                      },
                      activeColor: Colors.purple,
                      inactiveColor: Colors.grey.withOpacity(0.3),
                    )
                  : const CircularProgressIndicator(), // Show loader until duration is loaded
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 50,
                    color: Colors.white,
                  ),
                  onPressed: _handlePlayPause,
                ),
                const Text(
                  "Adjust the slider to choose start and end points",
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  "${_formatDuration(Duration(seconds: _startValue.toInt()))} - ${_formatDuration(Duration(seconds: _endValue.toInt()))}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
