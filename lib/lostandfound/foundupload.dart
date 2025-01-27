import 'package:cooig_firebase/background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
// Import your custom background widget

class FoundItemScreen extends StatefulWidget {
  const FoundItemScreen({super.key});

  @override
  _FoundItemScreenState createState() => _FoundItemScreenState();
}

class _FoundItemScreenState extends State<FoundItemScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _galleryFiles = [];
  List<File> media = [];
  File? _image;
  DateTime? _dateTime;
  String _location = '';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _uploadFile(List<File> files, String userID) async {
    try {
      List<String> downloadURLs = [];
      for (File file in files) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef =
            FirebaseStorage.instance.ref().child('foundposts').child(fileName);
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadURL = await snapshot.ref.getDownloadURL();
        downloadURLs.add(downloadURL);
      }

      await FirebaseFirestore.instance.collection('foundposts').add({
        'userID': userID,
        'images': downloadURLs, // Storing list of image URLs
        'timestamp': FieldValue.serverTimestamp(),
        'dateTime': _dateTime,
        'location': _location,
        'title': _titleController.text,
        'description': _descriptionController.text,
      });
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final List<XFile> pickedImages = await _picker.pickMultiImage();

    if (pickedImages != null) {
      List<File> files = pickedImages.map((xFile) => File(xFile.path)).toList();

      setState(() {
        _galleryFiles.addAll(files);
        media.addAll(files);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      File file = File(photo.path);

      setState(() {
        _galleryFiles.add(file);
        media.add(file);
      });
    }
  }

  String _generatePostID() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _onPostButtonClick() async {
    if (media.isEmpty ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _dateTime == null ||
        _location.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please fill all fields and add at least one image");
      return;
    }

    String postID = _generatePostID();
    await _uploadFile(
        media, 'kD3X6HBv8eP6nA3WasHjE0RMHnH3'); // Replace with actual userID

    setState(() {
      media.clear();
      _galleryFiles.clear();
    });

    await Fluttertoast.showToast(msg: "Post uploaded successfully");
  }

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _dateTime = pickedDate;
      });
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Select Image Source'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _takePhoto();
              },
              child: Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _pickImageFromGallery();
              },
              child: Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
      colors: [
        Color(0XFF9752C5),
        Color(0xFF000000),
      ],
      radius: 0.8,
      centerAlignment: Alignment.bottomRight,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text(
            'Found Item Details',
            style: GoogleFonts.ebGaramond(
              textStyle: TextStyle(
                color: Color.fromARGB(255, 254, 253, 255),
                fontSize: 30,
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Color.fromARGB(255, 195, 106, 240),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                ),
                _galleryFiles.isNotEmpty
                    ? Column(
                        children: _galleryFiles.map((file) {
                          return Column(
                            children: [
                              SizedBox(
                                height: 250,
                                width: double.infinity,
                                child: Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _showImageSourceDialog(context),
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              'Upload Image',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF9752C5),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title of Found Item',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _selectDateTime(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0XFF9752C5),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(Icons.calendar_today, color: Colors.white),
                        label: Text(
                          _dateTime == null
                              ? 'Select Date'
                              : DateFormat('yyyy-MM-dd').format(_dateTime!),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _location = value;
                      });
                    },
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _onPostButtonClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
