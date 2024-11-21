import 'package:cooig_firebase/feature_enum.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PostClipFeaturesScreen extends StatefulWidget {
  final File selectedImage;
  final String? selectedMusic; // Final selected music URL
  final Feature? selectedFeature;
  final Map<String, dynamic>? selectedTrackInfo; // Info of the selected track

  const PostClipFeaturesScreen({
    super.key,
    required this.selectedImage,
    this.selectedMusic,
    this.selectedFeature,
    this.selectedTrackInfo,
  });

  @override
  _PostClipFeaturesScreenState createState() => _PostClipFeaturesScreenState();
}

class _PostClipFeaturesScreenState extends State<PostClipFeaturesScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Clip Features'),
        backgroundColor: Colors.purple,
      ),
      body: Stack(
        children: [
          // Display the selected image as the background
          Image.file(
            widget.selectedImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Display track information if music is selected
          if (widget.selectedTrackInfo != null)
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
                      widget.selectedTrackInfo!['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      widget.selectedTrackInfo!['artist'],
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          // Additional features like text, stickers, etc., can be added here.
          // Placeholder for feature icons
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.text_fields, color: Colors.white),
                  onPressed: () {
                    // Implement text addition functionality here
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions, color: Colors.white),
                  onPressed: () {
                    // Implement sticker addition functionality here
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.music_note, color: Colors.white),
                  onPressed: () {
                    // Navigate to music selection or preview screen if needed
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
