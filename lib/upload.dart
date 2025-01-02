import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class Screen extends StatefulWidget {
  final dynamic userId;

  const Screen({super.key, required this.userId});
  @override
  State<Screen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<Screen> {
  File? _image;
  final picker = ImagePicker();
  bool _isUploading = false;

  Future getImageGallery() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        return;
      }
    });
  }

  Future<void> uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Get a reference to the storage bucket
      Reference storageReference = FirebaseStorage.instance.ref().child(
          'images/${DateTime.now().millisecondsSinceEpoch}${basename(_image!.path)}');

      // Upload the file to Firebase Storage
      await storageReference.putFile(_image!).whenComplete(
          () => {Fluttertoast.showToast(msg: "Image uploaded successfully")});

      // Get the download URL
      String downloadURL = await storageReference.getDownloadURL();

      // Store the download URL in Firestore
      // String userId ='gklD4of1KLed1Y0lWmA9hRhW6cp1'; // Replace with the actual user ID or document ID

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'profilepic': downloadURL,
      });

      return;
    } catch (e) {
      print('Error uploading image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 100,
            ),
            InkWell(
              onTap: () {
                getImageGallery();
              },
              child: Container(
                height: 200,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey),
                ),
                child: _image != null
                    ? Image.file(
                        _image!.absolute,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                getImageGallery();
              },
              child: InkWell(
                onTap: uploadImage,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF635A8F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "UPLOAD",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
