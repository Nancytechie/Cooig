import 'dart:io';
//import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:photofilters/photofilters.dart';
//import 'package:image/image.dart' as imageLib;
import 'paintscreen.dart';

class MultiImagePreviewScreen extends StatefulWidget {
  final List<XFile> imageFiles;

  MultiImagePreviewScreen(
      {required this.imageFiles, required List<String> imageUrls});

  @override
  _MultiImagePreviewScreenState createState() =>
      _MultiImagePreviewScreenState();
}

class _MultiImagePreviewScreenState extends State<MultiImagePreviewScreen> {
  late List<XFile> selectedImages;
  late XFile currentImageFile;

  @override
  void initState() {
    super.initState();
    selectedImages = widget.imageFiles;
    currentImageFile = selectedImages.first; // Set the first image as default
  }

  Future<void> _cropImage() async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: currentImageFile.path,
        aspectRatio: CropAspectRatio(ratioX: 2, ratioY: 3),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          currentImageFile = XFile(croppedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image cropping was canceled')),
        );
      }
    } catch (e) {
      print('Error cropping image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
    }
  }

/*  Future<void> _applyFilter() async {
    try {
      File imageFile = File(currentImageFile.path);

      if (!await imageFile.exists()) {
        print("Image file does not exist.");
        return;
      }

      var imageBytes = await imageFile.readAsBytes();
      var image = imageLib.decodeImage(imageBytes);

      if (image != null) {
        var correctedImage = imageLib.bakeOrientation(image);
        var resizedImage = imageLib.copyResize(correctedImage, width: 600);

        Map? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoFilterSelector(
              title: const Text("Apply Filters"),
              image: resizedImage,
              filters: presetFiltersList,
              filename: currentImageFile.name,
              appBarColor: Colors.deepPurple,
            ),
          ),
        );

        if (result != null && result.containsKey('image_filtered')) {
          setState(() {
            currentImageFile = XFile(result['image_filtered'].path);
          });
        }
      } else {
        throw Exception("Failed to decode image.");
      }
    } catch (e) {
      print("Error applying filter: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying filter: $e')),
      );
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Images'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: _cropImage,
          ),
          IconButton(
            icon: const Icon(Icons.photo_filter),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final editedImageBytes = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PainterScreen(
                    imageFile: File(currentImageFile.path),
                  ),
                ),
              );

              if (editedImageBytes != null) {
                final editedImageFile = File(currentImageFile.path);
                await editedImageFile.writeAsBytes(editedImageBytes);
                setState(() {
                  currentImageFile = XFile(editedImageFile.path);
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              Navigator.pop(context, selectedImages);
            },
          ),
        ],
      ),
      body: selectedImages.length > 1
          ? _buildImageGrid()
          : _buildSingleImageView(),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(8),
      itemCount: selectedImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              currentImageFile = selectedImages[index];
            });
          },
          child: Image.file(
            File(selectedImages[index].path),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildSingleImageView() {
    return Center(
      child: FutureBuilder<bool>(
        future: File(currentImageFile.path).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              File(currentImageFile.path),
              fit: BoxFit.contain,
            );
          } else {
            return const Text('Image not found');
          }
        },
      ),
    );
  }
}
