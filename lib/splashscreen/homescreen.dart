//import 'package:cooig_firebase/chat_profile/home.dart';
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/loginsignup/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Home screen design

class homescreen extends StatefulWidget {
  const homescreen({super.key});

  @override
  State<homescreen> createState() => _homescreenState();
}

class _homescreenState extends State<homescreen> {
  var currentScreen = "home";
  void changeScreen() {
    //app rebuild--build method reload
    setState(() {
      currentScreen = "screen2";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentScreen == "home") {
      return GradientContainer(
          changeScreen, const [Color(0XFF9752C5), Colors.black]);
    } else {
      return AuthWrapper();
    }
  }
}

/*


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(),
    );
  }
}
*/
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading screen while waiting
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // User is signed in
          //return Nav(userId: FirebaseAuth.instance.currentUser!.uid);
          return Homepage(
            userId: FirebaseAuth.instance.currentUser!.uid,
            index: 0,
          );
        } else {
          // User is signed out
          return Login();
        }
      },
    );
  }
}

class GradientContainer extends StatefulWidget {
  //GradientContainer(this.color1,this.color2,{super.key});
  const GradientContainer(this.gotoscreen2, this.mycolors, {super.key});
  // final Color color1;
  // final Color color2;
  final List<Color> mycolors;
  final Function gotoscreen2;

  @override
  State<GradientContainer> createState() => _GradientContainerState();
}

class _GradientContainerState extends State<GradientContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          // gradient: LinearGradient(colors: widget.mycolors,
          // begin: Alignment.bottomLeft,
          // end: Alignment.topRight
          // ),
          gradient: RadialGradient(
        colors: widget.mycolors,
        center: Alignment.center,
        radius: 0.8,
      )),
      child: Center(
        child: StyledText(widget.gotoscreen2, "Cooig"),
      ),
    );
  }
}

class StyledText extends StatefulWidget {
  const StyledText(this.change, this.txt, {super.key});
  final String txt;
  final Function change;

  @override
  State<StyledText> createState() => _StyledTextState();
}

class _StyledTextState extends State<StyledText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation = Tween(begin: -0.3, end: 0.1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, //will middle things
      children: [
        SizedBox(
          width: 300.0,
          child: Text(
            widget.txt,
            textAlign: TextAlign.center,
            style: GoogleFonts.libreBodoni(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 250, 242, 242), // Set text color
              decoration:
                  TextDecoration.none, // Ensure no underline or decoration
            ),
          ),
        ),
        const SizedBox(height: 50),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value,
              child: child,
            );
          },
          child: Image.asset(
            'assets/image/start.png',
            width: 340,
            height: 340,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 336,
          height: 39,
          child: Center(
            child: DefaultTextStyle(
              style: GoogleFonts.ebGaramond(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Connect with your colleagues',
                    speed: const Duration(milliseconds: 150),
                  ),
                ],
                repeatForever: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            widget.change();
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0XFFC177F3)),
            minimumSize: WidgetStateProperty.all(const Size(275, 60)),
          ),
          child: const Text(
            "Get Started",
            style: TextStyle(
                fontSize: 20, color: Color.fromARGB(255, 253, 249, 249)),
          ),
        ),
      ],
    );
  }
}
