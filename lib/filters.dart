import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class FiltersScreen extends StatefulWidget {
  final File selectedImage;
  final Function(Uint8List) onFilterApplied;

  const FiltersScreen(
      {super.key, required this.selectedImage, required this.onFilterApplied});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  File? _imageFile;
  Uint8List? _filteredImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Filters'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _filteredImage != null
                  ? Image.memory(_filteredImage!)
                  : (_imageFile != null
                      ? Image.file(_imageFile!)
                      : const Text('No image selected',
                          style: TextStyle(fontSize: 16))),
            ),
          ),
          if (_imageFile != null)
            Container(
              height: 80,
              color: Colors.black12,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterButton("Original", () => _applyFilter("original")),
                  _filterButton("Smooth", () => _applyFilter("smooth")),
                  _filterButton("Black & White", () => _applyFilter("bw")),
                  _filterButton("Brighten", () => _applyFilter("brighten")),
                  _filterButton("Darken", () => _applyFilter("darken")),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Choose Image', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.purple, width: 2),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.purple)),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _filteredImage = null; // Reset filtered image
      });
    }
  }

  void _applyFilter(String filter) async {
    if (_imageFile == null) return;

    // Load the image using the image library
    final img.Image? originalImage =
        img.decodeImage(await _imageFile!.readAsBytes());
    if (originalImage == null) return;

    img.Image filteredImage;

    // Apply filters
    switch (filter) {
      case "smooth":
        filteredImage =
            img.gaussianBlur(originalImage, radius: 5); // Smooth effect
        // Smooth effect
        break;
      case "bw":
        filteredImage = img.grayscale(originalImage); // Black & White
        break;
      case "brighten":
        filteredImage =
            img.adjustColor(originalImage, brightness: 1.2); // Brighten
        break;
      case "darken":
        filteredImage =
            img.adjustColor(originalImage, brightness: 0.8); // Darken
        break;
      default:
        filteredImage = originalImage; // Original
        break;
    }

    // Convert the filtered image to Uint8List
    final Uint8List filteredBytes =
        Uint8List.fromList(img.encodePng(filteredImage));

    setState(() {
      _filteredImage = filteredBytes;
    });
  }
}
