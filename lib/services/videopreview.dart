import 'dart:io';
import 'dart:ui' as ui; // Corrected: Import dart:ui for Canvas and Offset
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File videoFile;

  VideoPreviewScreen({required this.videoFile});

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;

  List<Offset?> points = [];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    await _controller.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: _controller.value.aspectRatio,
      autoPlay: false,
      looping: false,
    );

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview Video'),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              Navigator.pop(context, widget.videoFile);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(renderBox.globalToLocal(details.globalPosition));
          });
        },
        onPanEnd: (details) {
          points.add(null);
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Chewie(controller: _chewieController),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _VideoPainter(points),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPainter extends CustomPainter {
  final List<Offset?> points;

  _VideoPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
