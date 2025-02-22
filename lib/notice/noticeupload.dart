import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:intl/intl.dart';

class NoticeUploadPage extends StatefulWidget {
  final String userId;
  const NoticeUploadPage({super.key, required this.userId});

  @override
  _NoticeUploadPageState createState() => _NoticeUploadPageState();
}

class _NoticeUploadPageState extends State<NoticeUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _headingController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailsController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _imageFile;

  final OutlineInputBorder _roundedBorder = const OutlineInputBorder(
    borderSide: BorderSide(color: Colors.white),
    borderRadius: BorderRadius.horizontal(
      left: Radius.circular(18),
      right: Radius.circular(18),
    ),
  );

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadNotice() async {
    if (!_formKey.currentState!.validate()) return;

    // Show a loading indicator while uploading
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Upload the image and get the URL
      String? imageUrl;
      if (_imageFile != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef =
            FirebaseStorage.instance.ref().child('noticeposts').child(fileName);
        final uploadTask = storageRef.putFile(_imageFile!);
        final snapshot = await uploadTask.whenComplete(() => {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Combine selected date and time
      DateTime? fullDateTime;
      String? timeString;
      if (_selectedDate != null && _selectedTime != null) {
        fullDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        timeString =
            _selectedTime!.format(context); // Format the time as a string
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Upload notice details to Firestore
      await FirebaseFirestore.instance.collection('noticeposts').add({
        'heading': _headingController.text,
        'location': _locationController.text,
        'details': _detailsController.text,
        'dateTime': fullDateTime != null
            ? Timestamp.fromDate(fullDateTime) // Convert to Firestore Timestamp
            : null,
        'time': timeString, // Store the time as a string
        'imageUrl': imageUrl,
        'username': userData['societyName'] ?? 'Unknown',
        'profilepic': userData['profilepic'] ?? '',
        'timestamp':
            FieldValue.serverTimestamp(), // Server timestamp for creation time
        "isStarred": false,
        'postedByUserId': widget.userId,
      });

      // Close the loading dialog
      Navigator.pop(context);

      // Show "Post Uploaded" success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
              SizedBox(height: 10),
              Text(
                "Post Uploaded",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

      // Wait for 1.5 seconds and then navigate back to the noticeboard page
      await Future.delayed(Duration(seconds: 1));
      Navigator.pop(context); // Close the success dialog
      Navigator.pop(context); // Navigate back to the noticeboard page
    } catch (error) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error message
      Fluttertoast.showToast(msg: "Failed to upload notice: $error");
    }
  }

  void _clearForm() {
    setState(() {
      _headingController.clear();
      _locationController.clear();
      _detailsController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _imageFile = null;
    });
  }

  @override
  void dispose() {
    _headingController.dispose();
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
      colors: const [
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
            'Cooig',
            style: GoogleFonts.libreBodoni(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 254, 253, 255),
                fontSize: 26,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(
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
                Text(
                  "Describe the event",
                  style: GoogleFonts.ebGaramond(
                    color: const Color.fromARGB(255, 171, 98, 220),
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 360,
                  height: 670,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(20.86),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFCACACA),
                        blurRadius: 9.24,
                        offset: Offset(2.77, 2.77),
                      ),
                      BoxShadow(
                        color: Color(0xFFC9C9C9),
                        blurRadius: 9.24,
                        offset: Offset(-2.77, -2.77),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _headingController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Heading',
                              prefixIcon: const Icon(Icons.title),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a heading';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDate == null
                                          ? 'No date chosen'
                                          : 'Date: ${DateFormat('yMMMd').format(_selectedDate!)}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    TextButton(
                                      onPressed: _pickDate,
                                      child: const Text('Choose Date',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedTime == null
                                          ? 'No time chosen'
                                          : 'Time: ${_selectedTime!.format(context)}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    TextButton(
                                      onPressed: _pickTime,
                                      child: const Text('Choose Time',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _locationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Location',
                              prefixIcon: const Icon(Icons.location_on),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _detailsController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Details of event',
                              prefixIcon: const Icon(Icons.description),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : null,
                                child: _imageFile == null
                                    ? const Icon(
                                        Icons.camera_alt,
                                        size: 50,
                                        color: Colors.black54,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: ElevatedButton(
                              onPressed: _uploadNotice,
                              child: const Text('Upload Notice'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
