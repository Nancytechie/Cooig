import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/lostandfound/foundpage.dart';
import 'package:cooig_firebase/home.dart';

import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/profile/profile.dart';
import 'package:cooig_firebase/society/societyprofile/societyprofile.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';

//import 'package:cooig_firebase/search.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import 'package:firebase_auth/firebase_auth.dart'
    as firebaseAuth; // Aliased FirebaseAuth User

class Nav extends StatefulWidget {
  final dynamic userId;

  const Nav({super.key, required this.userId});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;
  Future<String> getUserRole() async {
    firebaseAuth.User? user = firebaseAuth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return "guest"; // Default role if no user is logged in
    }

    try {
      // Fetch the user's document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // Retrieve the role field from the document
        return userDoc['role'] ??
            'guest'; // Default to 'guest' if role is not found
      } else {
        return 'guest'; // If no document found for the user
      }
    } catch (e) {
      print("Error fetching user role: $e");
      return 'guest'; // Return default role in case of an error
    }
  }

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == index) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    String userRole = await getUserRole();
// cant switch back to home  nav bar can
    switch (_selectedIndex) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  Homepage(userId: widget.userId)), // Navigate to HomePage
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Shopscreen(userId: widget.userId)),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Noticeboard(
                    userid: widget.userId,
                  )),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Foundpage()),
        );
        break;
      case 4:
        if (userRole == "Society") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Societyprofile(
                      userid: widget.userId,
                    )), // Navigate to SocietyProfilePage
          );
        } else if (userRole == "Student") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ProfilePage(
                      userid: widget.userId,
                    )), // Navigate to StudentProfilePage
          );
        } else {
          print("Unknown role: $userRole");
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(LineAwesomeIcons.tag_solid),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              LineAwesomeIcons.bullseye_solid,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.briefcase),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF635A8F),
        onTap: _onItemTapped,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
