import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';

import 'package:cooig_firebase/loginsignup/userprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:csv/csv.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _collegeNames = [];
  String? _selectedCollege;

  List<String> _courses = [];
  String? _selectedCourse;

  String defaultvalue = "";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _errorMessage = ''; // Variable to hold error message

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load college names
      final String collegeResponse =
          await rootBundle.loadString('assets/kaggledata/college_name.csv');
      final List<List<dynamic>> collegeData =
          const CsvToListConverter().convert(collegeResponse);
      _collegeNames = collegeData
          .skip(1)
          .map((row) => row[0].toString())
          .toList(); // Extracting only the 'name' column

      // Load courses
      final String courseResponse =
          await rootBundle.loadString('assets/kaggledata/Courses_name.csv');
      final List<List<dynamic>> courseData =
          const CsvToListConverter().convert(courseResponse);
      _courses = courseData
          .skip(1)
          .map((row) => row[0].toString())
          .toList(); // Extracting only the 'course' column

      setState(() {});
    } catch (e) {
      print("Error loading CSV: $e");
    }
  }

  Future<void> _signUpWithEmail() async {
    setState(() {
      _errorMessage = ''; // Clear any previous error messages
    });

    // Check if all fields are filled and password matches
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name.';
      });
      return;
    }

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email.';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password.';
      });
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please confirm your password.';
      });
      return;
    }

    if (_selectedCollege == null) {
      setState(() {
        _errorMessage = 'Please select your college.';
      });
      return;
    }

    if (_selectedCourse == null) {
      setState(() {
        _errorMessage = 'Please select your course.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    // Password validation (optional)
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long.';
      });
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Add user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'full_name': _nameController.text,
        'college_name': _selectedCollege,
        'course_name': _selectedCourse,
        'email': _emailController.text,
        'image': '',
      });

      Fluttertoast.showToast(
        msg: "Sign up successful!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Navigate to home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Userprofile()),
      );
    } catch (e) {
      print("Error signing up: $e");
      Fluttertoast.showToast(
        msg: "Sign up failed: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
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
            icon: const Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 195, 106, 240)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Create a new account",
                style: GoogleFonts.ebGaramond(
                  color: const Color.fromARGB(255, 171, 98, 220),
                  fontSize: 25,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 360,
                height: 650,
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
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(18),
                              right: Radius.circular(18),
                            ),
                          ),
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 148, 147, 147),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      DropdownSearch<String>(
                        items: _collegeNames,
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(18),
                                right: Radius.circular(18),
                              ),
                            ),
                            labelText: 'College Name',
                            prefixIcon: Icon(Icons.school),
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 148, 147, 147),
                            ),
                          ),
                        ),
                        dropdownBuilder: (context, selectedItem) {
                          return Text(
                            selectedItem ?? '',
                            style: const TextStyle(
                                color: Colors
                                    .white), // Set the text color to white
                          );
                        },
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCollege = newValue;
                          });
                        },
                        selectedItem: _selectedCollege,
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                        ),
                      ),
                      const SizedBox(height: 17),
                      DropdownSearch<String>(
                        items: _courses,
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(18),
                                right: Radius.circular(18),
                              ),
                            ),
                            labelText: 'Course Name',
                            prefixIcon: Icon(Icons.book),
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 148, 147, 147),
                            ),
                          ),
                        ),
                        dropdownBuilder: (context, selectedItem) {
                          return Text(
                            selectedItem ?? '',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 252, 252),
                            ),
                          );
                        },
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCourse = newValue;
                          });
                        },
                        selectedItem: _selectedCourse,
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                        ),
                      ),
                      const SizedBox(height: 17),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(18),
                              right: Radius.circular(18),
                            ),
                          ),
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 148, 147, 147),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(18),
                              right: Radius.circular(18),
                            ),
                          ),
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 148, 147, 147),
                          ),
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
                        ),
                      ),
                      const SizedBox(height: 17),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(18),
                              right: Radius.circular(18),
                            ),
                          ),
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 148, 147, 147),
                          ),
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
                        ),
                      ),
                      const SizedBox(height: 17),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Center(
                          child: ElevatedButton(
                        onPressed: _signUpWithEmail,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                          backgroundColor: const Color(0XFFC177F3),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 50.0),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
