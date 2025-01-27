import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';

class PainterScreen extends StatefulWidget {
  final File imageFile;

  const PainterScreen({super.key, required this.imageFile});

  @override
  _PainterScreenState createState() => _PainterScreenState();
}

class _PainterScreenState extends State<PainterScreen> {
  late ImagePainterController _controller;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController();
  }

  Future<void> _exportImage() async {
    if (_isExporting || !mounted) return;

    setState(() {
      _isExporting = true;
    });

    try {
      Uint8List? editedImage = await _controller.exportImage();
      if (editedImage != null && mounted) {
        Navigator.pop(context, editedImage);
      }
    } catch (e) {
      print('Error during export: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Painter'),
        backgroundColor: Colors.purple, // AppBar color set to purple
        actions: [
          IconButton(
            icon: const Icon(Icons.check,
                color: Colors.white), // White color for the check icon
            onPressed: () {
              if (!_isExporting && mounted) {
                _exportImage();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ImagePainter.file(
            widget.imageFile,
            controller: _controller,
            scalable: true,
            // onImageRotated: (image) {
            //   // Ensure image orientation correction if needed
            // },
          ),
          if (_isExporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
