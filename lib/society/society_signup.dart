import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/society/society_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class SocietySignup extends StatefulWidget {
  const SocietySignup({super.key});

  @override
  State<SocietySignup> createState() => _SocietySignupState();
}

class _SocietySignupState extends State<SocietySignup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _societyNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _establishedYearController = TextEditingController();
  String? _selectedCategory;
  bool _isOtherCategorySelected = false;
  final TextEditingController _otherCategoryController =
      TextEditingController();
  String? _selectedStatus;
  File? _logoFile;
  String? logoUrl;

  String _errorMessage = ''; // Variable to hold error message

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerificationStatus();
    _loadData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _societyNameController.dispose();
    _aboutController.dispose();
    _establishedYearController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load college names and courses...
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _societySignUpWithEmail() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(
        msg: "Passwords do not match.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        Fluttertoast.showToast(
          msg: "Verification email sent. Please check your inbox.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Verify Your Email"),
            content: Text(
                "A verification link has been sent to ${user.email}. Please verify your email to complete the sign-up process."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );

        _checkEmailVerificationStatus(); // Start polling for verification
      }
    } catch (e) {
      print("Error signing up: $e");
      Fluttertoast.showToast(
        msg: "Sign up failed: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _checkEmailVerificationStatus() async {
    User? user = _auth.currentUser;

    if (user != null) {
      bool emailVerified = false;

      while (!emailVerified) {
        await Future.delayed(const Duration(seconds: 3)); // Wait 3 seconds
        await user?.reload(); // Refresh user information
        user = _auth.currentUser; // Get updated user instance
        emailVerified = user!.emailVerified;

        if (emailVerified) {
          Fluttertoast.showToast(
            msg: "Email verified successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Upload logo to Firebase Storage and get the URL
          if (_logoFile != null) {
            logoUrl = await _uploadLogoToFirebase(user.uid);
          }

          // Add user details to Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'full_name': _societyNameController.text,
            'about': _aboutController.text,
            'email': _emailController.text,
            'establishedYear': _establishedYearController.text,
            'category': _selectedCategory,
            'status': _selectedStatus,
            'logoUrl': logoUrl,
            "role": "Society",
          });

          // Navigate to Userprofile
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => Homepage(
                      userId: user!.uid,
                      index: 0,
                    )),
          );
          break;
        }
      }
    }
  }

  Future<String?> _uploadLogoToFirebase(String userId) async {
    if (_logoFile == null) {
      print('No logo file to upload');
      return null;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final logoRef = storageRef.child(
          'society_logos/$userId/${DateTime.now().millisecondsSinceEpoch}.png');

      final uploadTask = await logoRef.putFile(_logoFile!);
      final downloadUrl = await logoRef.getDownloadURL();

      print('Logo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading logo: $e');
      return null;
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        _logoFile = File(pickedFile.path);
        setState(() {}); // Update the UI to reflect the picked file
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking logo: $e');
    }
  }

  InputBorder get _roundedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 148, 147, 147),
          width: 1.0,
        ),
      );

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
            icon: const Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 195, 106, 240)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SocietyLogin()),
              );
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: const EdgeInsets.all(30.0),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Create a new society",
                  style: GoogleFonts.ebGaramond(
                    color: const Color.fromARGB(255, 171, 98, 220),
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 360,
                  height: 750,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 15),
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
                            labelText: 'About Society',
                            prefixIcon: const Icon(Icons.info_outline),
                            labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 148, 147, 147),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a brief about the society';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _establishedYearController,
                          keyboardType: TextInputType.number,
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
                              return 'Please enter the year of establishment';
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
                            'Cultural',
                            'Technical',
                            'Sports',
                            'Literary',
                            'Music',
                            'Dance',
                            'Art',
                            'Drama',
                            'Startup',
                            'NSS',
                            'NCC',
                            'Robotics',
                            'Coding',
                            'Automobile',
                            'Photography',
                            'Debate',
                            'Social Service',
                            'Language',
                            'Astronomy',
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
                        DropdownSearch<String>(
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                          ),
                          items: ['Recruiting', 'Non-Recruiting'],
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.check_circle),
                              enabledBorder: _roundedBorder,
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 148, 147, 147),
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
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
                              return 'Please enter an email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            enabledBorder: _roundedBorder,
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 148, 147, 147),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            enabledBorder: _roundedBorder,
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              },
                            ),
                            labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 148, 147, 147),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _societySignUpWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 108, 61, 192),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Create Society',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
