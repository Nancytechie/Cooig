import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({required this.imageUrl, Key? key}) : super(key: key);

  // Main function to handle image download
  Future<void> _downloadImage(BuildContext context) async {
    try {
      if (await _hasStoragePermission(context)) {
        await _saveImageToLocalStorage(context);
      } else {
        Fluttertoast.showToast(msg: "Storage permission is required.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  // Function to check and request storage permissions
  Future<bool> _hasStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.storage.status;

      if (status.isGranted) {
        return true; // Permission already granted
      } else if (status.isDenied || status.isLimited) {
        PermissionStatus newStatus = await Permission.storage.request();
        return newStatus.isGranted; // Grant permission after request
      } else if (status.isPermanentlyDenied) {
        // If permanently denied, show permission dialog
        await _showPermissionDialog(context);
        return false;
      } else if (await Permission.manageExternalStorage.isDenied) {
        PermissionStatus newStatus =
            await Permission.manageExternalStorage.request();
        return newStatus.isGranted; // For Android 11+ full storage access
      }
    } else if (Platform.isIOS) {
      return true; // iOS permissions are typically handled differently
    }
    return false; // Default false for unknown states
  }

  // Function to show dialog if permission is permanently denied
  Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "Storage permission is required to save images. Please enable storage access in your app settings."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Function to save the image to local storage
  Future<void> _saveImageToLocalStorage(BuildContext context) async {
    try {
      // For Android 11+ use custom directory
      final directory =
          Platform.isAndroid && await Permission.manageExternalStorage.isGranted
              ? Directory('/storage/emulated/0/Pictures/cooig_images')
              : await getExternalStorageDirectory();

      final folderPath = "${directory!.path}/cooig_images";

      // Create the directory if it doesn't exist
      await Directory(folderPath).create(recursive: true);

      // Download the image from the URL
      final response = await http.get(Uri.parse(imageUrl));
      final fileName = imageUrl.split('/').last;
      final filePath = "$folderPath/$fileName";

      // Save the file to the directory
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      Fluttertoast.showToast(msg: "Image saved to $folderPath");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Viewer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context), // Download button
          ),
        ],
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child; // Display image when loaded
            }
            return const CircularProgressIndicator(); // Loading indicator
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text("Failed to load image"); // Error message
          },
        ),
      ),
    );
  }
}
