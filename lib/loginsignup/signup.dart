import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';

import 'package:cooig_firebase/loginsignup/userprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _collegeNames = [];
  String? _selectedCollege;

  final List<String> _courses = [];
  String? _selectedCourse;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final String _errorMessage = ''; // Variable to hold error message

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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load college names and courses...
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _signUpWithEmail() async {
    // Validation logic...
    final RegExp igdtuwEmailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@igdtuw\.ac\.in$');

    if (!igdtuwEmailRegex.hasMatch(_emailController.text)) {
      Fluttertoast.showToast(
        msg: 'Enter a valid college email id.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    } else {
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
              title: Text("Verify Your Email"),
              content: Text(
                  "A verification link has been sent to ${user.email}. Please verify your email to complete the sign-up process."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
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

          // Add user details to Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'full_name': _nameController.text,
            'college_name': _selectedCollege,
            'course_name': _selectedCourse,
            'email': user.email,
            'username': '',
            'branch': '',
            'bio': '',
            'profilepic': '',
            'year': '',
            "role": "Student",
          });

          // Navigate to Userprofile
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => Userprofile(
                      userid: user!.uid,
                    )),
          );
          break;
        }
      }
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
                        items: [
                          "Indira Gandhi Delhi Technical University For Women"
                        ],
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
                        items: [
                          "Bachelors of Technology",
                          "Masters of Technology",
                          "Bachelors in Business Administration",
                          "Masters in Business Administration",
                          "Bachelors in Architecture",
                          "Masters in Planning ",
                        ],
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
                            ), //add text for others
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
