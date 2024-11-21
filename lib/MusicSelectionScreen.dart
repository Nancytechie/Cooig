import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'MusicPreviewScreen.dart';

class MusicSelectionScreen extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onMusicSelected;
  final List<Map<String, dynamic>> spotifyTracks;
  final File capturedImage;

  const MusicSelectionScreen({
    super.key,
    required this.onMusicSelected,
    required this.spotifyTracks,
    required this.capturedImage,
  });

  @override
  _MusicSelectionScreenState createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlaying;
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose(); // Dispose the player
    super.dispose();
  }

  void _togglePlayback(String? previewUrl) async {
    if (previewUrl == null || previewUrl.isEmpty) {
      return;
    }
    try {
      if (_currentlyPlaying == previewUrl && _isPlaying) {
        await _player.pause(); // Pause playback
        setState(() {
          _isPlaying = false;
          _currentlyPlaying = null;
        });
      } else {
        await _player.stop(); // Stop any previous playback
        await _player.setUrl(previewUrl); // Set new audio URL
        await _player.play(); // Play the new audio
        setState(() {
          _currentlyPlaying = previewUrl;
          _isPlaying = true;
        });
      }
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Music"),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        itemCount: widget.spotifyTracks.length,
        itemBuilder: (context, index) {
          final track = widget.spotifyTracks[index];
          final previewUrl = track['previewUrl'] ?? '';

          if (previewUrl.isEmpty) {
            return Container(); // Skip tracks with no preview URL
          }

          return ListTile(
            leading: Image.network(track['albumArtUrl'] ?? ''),
            title: Text(track['name'] ?? 'Unknown Track'),
            subtitle: Text(track['artist'] ?? 'Unknown Artist'),
            trailing: IconButton(
              icon: Icon(
                _currentlyPlaying == previewUrl && _isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                _togglePlayback(previewUrl);
              },
            ),
            onTap: () {
              // No stop here; let the song continue playing
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MusicPreviewScreen(
                    selectedImage: widget.capturedImage,
                    musicUrl: previewUrl,
                    trackInfo: track,
                    initialPosition: _player.position,
                    autoPlay:
                        true, // Start playing automatically in Preview screen
                    audioPlayer: _player, // Pass the same AudioPlayer instance
                  ),
                ),
              ).then((_) {
                setState(() {
                  _isPlaying = _player.playing; // Update playing state
                  _currentlyPlaying = _player.playing ? previewUrl : null;
                });
              });

              widget.onMusicSelected(previewUrl, track);
            },
          );
        },
      ),
    );
  }
}
