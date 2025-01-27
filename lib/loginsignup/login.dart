import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';
import 'package:cooig_firebase/home.dart' hide Container, SizedBox;
//import 'package:cooig_firebase/.dart';
import 'package:cooig_firebase/loginsignup/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool passwordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = ''; // Variable to hold error message

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (error) {
      print('Error signing in with Google: $error');
    }
  }

  Future<void> _loginWithEmail() async {
    setState(() {
      _errorMessage = ''; // Clear any previous error messages
    });

    try {
      // Attempt to sign in with the email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if the user is logged in successfully
      User? user = userCredential.user;

      String userid = _auth.currentUser!.uid;

      if (user != null) {
        // If login is successful, navigate to the home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  Homepage(userId: userid)), // Replace with your desired page
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Login failed. Please try again later.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handling specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        Fluttertoast.showToast(
          msg: 'No user found for that email. Please check the email address.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else if (e.code == 'invalid-credential') {
        Fluttertoast.showToast(
          msg: 'Incorrect password. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else if (e.code == 'invalid-email') {
        Fluttertoast.showToast(
          msg: 'The email address is not valid. Please check the format.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else if (e.code == 'too-many-requests') {
        Fluttertoast.showToast(
          msg: 'Too many login attempts. Please try again later.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'An unexpected error occurred. Please try again later.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
      print(
          "Firebase Auth Error: ${e.code}"); // Optional: for debugging purposes
    } catch (e) {
      // Handling other types of errors (e.g., network connectivity)

      Fluttertoast.showToast(
        msg: 'An unexpected error occurred. Please try again later.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      print("General Error: $e"); // Optional: for debugging purposes
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isNotEmpty) {
      try {
        await _auth.sendPasswordResetEmail(email: _emailController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent!")),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Error sending password reset email.';
        });
        print("Error resetting password: $e");
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter your email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void navigateToSignup() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUp()),
      );
    }

    return RadialGradientBackground(
      colors: const [Color(0XFF9752C5), Color(0xFF000000)],
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
        ),
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(23.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                "Hello Mates!",
                style: GoogleFonts.ebGaramond(
                  color: const Color(0XFF9752C5),
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 60),
              Container(
                width: 360,
                height: 370,
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(25.86),
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
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: Color(0XFFA799FD),
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: Colors.white),
                          labelStyle: TextStyle(
                              color: Color.fromARGB(255, 148, 147, 147)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(25),
                              right: Radius.circular(24),
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _passwordController,
                        obscureText: !passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                passwordVisible = !passwordVisible;
                              });
                            },
                          ),
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 148, 147, 147)),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(25),
                              right: Radius.circular(24),
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _loginWithEmail,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                const Color(0XFFC177F3)),
                            minimumSize: WidgetStateProperty.all(
                              const Size(350, 50),
                            ),
                          ),
                          child: const Text("Login",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(255, 253, 249, 249))),
                        ),
                      ),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 45),
              ElevatedButton(
                onPressed: _loginWithGoogle,
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.white,
                  minimumSize: const Size(325, 50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/image/google_logo.jpeg',
                      height: 30,
                      width: 30,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Login with Google",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: navigateToSignup,
                  child: const Text(
                    "Create a new account",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0XFFD5AAEF),
                    ),
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
