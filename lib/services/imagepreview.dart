import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:photofilters/photofilters.dart';
import 'package:image/image.dart' as imageLib;
import 'package:pro_image_editor/modules/filter_editor/filter_editor.dart';
import 'paintscreen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<XFile> imageFiles;

  const ImagePreviewScreen(
      {super.key, required this.imageFiles, required String imageUrl});

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late List<XFile> selectedImages;
  late XFile currentImageFile;

  @override
  void initState() {
    super.initState();
    selectedImages = widget.imageFiles;
    currentImageFile = selectedImages.first;
  }

  Future<void> _cropImage() async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: currentImageFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          currentImageFile = XFile(croppedFile.path);
        });
      }
    } catch (e) {
      print('Error cropping image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image')),
      );
    }
  }

/*
  Future<void> _applyFilter() async {
    try {
      final imageFile = File(currentImageFile.path);
      if (!await imageFile.exists()) return;

      final imageBytes = await imageFile.readAsBytes();
      final image = imageLib.decodeImage(imageBytes);

      if (image != null) {
        final resizedImage = imageLib.copyResize(image, width: 600);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => 
            
          ),
        );

        if (result != null && result.containsKey('image_filtered')) {
          setState(() {
            currentImageFile = XFile(result['image_filtered'].path);
          });
        }
      }
    } catch (e) {
      print("Error applying filter: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying filter')),
      );
    }
  }
*/
  Future<void> _removeImage(XFile image) async {
    setState(() {
      selectedImages.remove(image);
      if (selectedImages.isNotEmpty) {
        currentImageFile = selectedImages.first;
      }
    });
  }

  Future<void> _sendImage() async {
    // When the user clicks the tick mark, send the image and go back to the chat screen.
    Navigator.pop(context, currentImageFile); // Pass the selected image back
  }

  Future<void> _editImage() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
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
            onPressed: _editImage,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _sendImage, // Clicking the tick mark sends the image
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
          child: Stack(
            children: [
              Image.file(
                File(selectedImages[index].path),
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeImage(selectedImages[index]),
                ),
              ),
            ],
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
