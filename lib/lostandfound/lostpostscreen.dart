import 'dart:io';

import 'package:cooig_firebase/background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart'; // For basename function

class PostScreen extends StatefulWidget {
  final String userId;
  const PostScreen({super.key, required this.userId});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image; // This will hold the selected image
  DateTime? _dateTime;
  String _location = '';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;
  bool _uploadSuccess = false;

  Future<void> _uploadFile(File file, String userID) async {
    try {
      print('Starting upload...');
      final storageRef = FirebaseStorage.instance.ref();
      final fileRef =
          storageRef.child('lostpost/$userID/${basename(file.path)}');
      print('File reference created: ${fileRef.fullPath}');

      await fileRef.putFile(file);
      print('File uploaded successfully.');

      final downloadURL = await fileRef.getDownloadURL();
      print('Download URL: $downloadURL');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('lostpost').add({
        'userID': userID,
        'image': downloadURL,
        'dateTime': _dateTime,
        'location': _location,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'username':
            userData['full_name'] ?? userData['societyName'] ?? 'Unknown',
        'profilepic': userData['profilepic'] ?? '',
        'postedByUserId': widget.userId,
      });

      print('Firestore document added successfully.');

      setState(() {
        _uploadSuccess = true;
      });

      await Future.delayed(Duration(seconds: 2)); // Show success for 2 seconds

      setState(() {
        _isUploading = false;
        _uploadSuccess = false;
      });

      Navigator.pop(context as BuildContext);
    } catch (e) {
      print('Error uploading file: $e');
      setState(() {
        _isUploading = false;
      });
      await Fluttertoast.showToast(msg: "Error uploading post: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path); // Update _image with the selected file
      });
    }
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
                _pickImageFromGallery();
              },
              child: Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onPostButtonClick() async {
    if (_image == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _dateTime == null ||
        _location.isEmpty) {
      await Fluttertoast.showToast(
          msg: "Please fill in all fields and select an image.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    await _uploadFile(_image!, widget.userId);

    setState(() {
      _image = null; // Clear the selected image
    });
  }

  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
        colors: [
          Color(0XFF9752C5),
          Color(0xFF000000),
        ],
        radius: 0.0,
        centerAlignment: Alignment.bottomRight,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: Colors.black,
              title: Text(
                'Lost Item Details',
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
            body: Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _image != null
                                ? SizedBox(
                                    height: 250,
                                    width: double.infinity,
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _showImageSourceDialog(context),
                                        icon: Icon(Icons.add,
                                            color: Colors.white),
                                        label: Text(
                                          'Upload Image',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF9752C5),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
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
                                  labelText: 'Title of Lost Item',
                                  labelStyle: TextStyle(color: Colors.white),
                                  border: OutlineInputBorder(),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
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
                                    icon: Icon(Icons.calendar_today,
                                        color: Colors.white),
                                    label: Text(
                                      _dateTime == null
                                          ? 'Select Date'
                                          : DateFormat('yyyy-MM-dd')
                                              .format(_dateTime!),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 10),
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
                          ])),
                ),
                if (_isUploading || _uploadSuccess)
                  AnimatedOpacity(
                    opacity: _isUploading || _uploadSuccess ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: _uploadSuccess ? 100 : 50,
                          height: _uploadSuccess ? 100 : 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(_uploadSuccess ? 50 : 25),
                          ),
                          child: _uploadSuccess
                              ? Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 50,
                                )
                              : CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
              ],
            )));
  }
}
