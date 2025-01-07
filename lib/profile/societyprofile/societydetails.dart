import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:uuid/uuid.dart';

class SocietyDetailsPage extends StatefulWidget {
  const SocietyDetailsPage({super.key});

  @override
  _SocietyDetailsPageState createState() => _SocietyDetailsPageState();
}

class _SocietyDetailsPageState extends State<SocietyDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _societyNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _emailController = TextEditingController();
  final _establishedYearController = TextEditingController();
  String? _selectedCategory;
  bool _isOtherCategorySelected = false;
  final TextEditingController _otherCategoryController =
      TextEditingController();
  String? _selectedStatus;
  File? _logoFile;

  final OutlineInputBorder _roundedBorder = const OutlineInputBorder(
    borderSide: BorderSide(color: Colors.white),
    borderRadius: BorderRadius.horizontal(
      left: Radius.circular(18),
      right: Radius.circular(18),
    ),
  );

  Future<void> _pickLogo() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _createSociety() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Create a unique ID for the society
      String societyId = const Uuid().v4();

      // Upload the logo to Firebase Storage
      String? logoUrl;
      if (_logoFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('societydetails/$societyId/logo.jpg');
        await storageRef.putFile(_logoFile!);
        logoUrl = await storageRef.getDownloadURL();
      }

      // Store society details in Firestore
      await FirebaseFirestore.instance
          .collection('societydetails')
          .doc(societyId)
          .set({
        'societyName': _societyNameController.text,
        'about': _aboutController.text,
        'email': _emailController.text,
        'establishedYear': _establishedYearController.text,
        'category': _selectedCategory,
        'status': _selectedStatus,
        'logoUrl': logoUrl,
      });

      // Display success message
      Fluttertoast.showToast(msg: "Society created successfully");

      // Clear the form
      _clearForm();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  void _clearForm() {
    setState(() {
      _societyNameController.clear();
      _aboutController.clear();
      _emailController.clear();
      _establishedYearController.clear();
      _selectedCategory = null;
      _selectedStatus = null;
      _logoFile = null;
    });
  }

  @override
  void dispose() {
    _societyNameController.dispose();
    _aboutController.dispose();
    _emailController.dispose();
    _establishedYearController.dispose();
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
                  "Create society",
                  style: GoogleFonts.ebGaramond(
                    color: const Color.fromARGB(255, 171, 98, 220),
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 360,
                  height: 800,
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
                            controller: _societyNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Society Name',
                              prefixIcon: const Icon(Icons.group),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the society name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _aboutController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'About',
                              prefixIcon: const Icon(Icons.info),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please tell us about your society';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            value: _selectedCategory,
                            items: [
                              'Cultural Club',
                              'Technical Club',
                              'Sports Club',
                              'Literary Club',
                              'Music Club',
                              'Dance Club',
                              'Art Club',
                              'Drama Club',
                              'Entrepreneurship Cell',
                              'NSS (National Service Scheme)',
                              'NCC (National Cadet Corps)',
                              'Robotics Club',
                              'Coding Club',
                              'Automobile Club',
                              'Photography Club',
                              'Debate Society',
                              'Quiz Club',
                              'Social Service Club',
                              'Language Club',
                              'Astronomy Club',
                              'Other',
                            ]
                                .map((category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                _isOtherCategorySelected = value == 'Other';
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                          if (_isOtherCategorySelected)
                            TextFormField(
                              controller: _otherCategoryController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                enabledBorder: _roundedBorder,
                                labelText: 'Other Category',
                                prefixIcon: const Icon(Icons.edit),
                                labelStyle: const TextStyle(
                                  color: Color.fromARGB(255, 148, 147, 147),
                                ),
                              ),
                              validator: (value) {
                                if (_isOtherCategorySelected &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter the category name';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _establishedYearController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Established Year',
                              prefixIcon: const Icon(Icons.calendar_today),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the established year';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              enabledBorder: _roundedBorder,
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.check_circle),
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                            value: _selectedStatus,
                            items: ['Recruiting', 'Non-Recruiting']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a status';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: GestureDetector(
                              onTap: _pickLogo,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _logoFile != null
                                    ? FileImage(_logoFile!)
                                    : null,
                                child: _logoFile == null
                                    ? const Icon(Icons.add_a_photo, size: 40)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: ElevatedButton(
                              onPressed: _createSociety,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0XFF9752C5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Create Society',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 253, 249, 249)),
                              ),
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
