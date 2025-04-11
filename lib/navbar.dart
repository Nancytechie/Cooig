import 'package:cooig_firebase/society/societyprofile/societyprofile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
import 'package:cooig_firebase/profile/profile.dart';


class BottomNavScreen extends StatefulWidget {
  final dynamic userId;

  BottomNavScreen({super.key, required this.userId});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    Homepage(userId: widget.userId, index: 0),
    Shopscreen(userId: widget.userId, index: 1),
    Noticeboard(userId: widget.userId, index: 2),
    PostScreen(userId: widget.userId),
    Container(), // Placeholder for Profile page
  ];

  Future<String> getUserRole() async {
    firebaseAuth.User? user = firebaseAuth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return "guest";
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc['role'] ?? 'guest';
      } else {
        return 'guest';
      }
    } catch (e) {
      print("Error fetching user role: $e");
      return 'guest';
    }
  }

  void _onItemTapped(int index) async {
    if (index == 4) {
      String role = await getUserRole();

      if (role == "Society") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Societyprofile(userid: widget.userId),
          ),
        );
      } else if (role == "Student") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: widget.userId, index: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unrecognized role or guest user.")),
        );
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Iconsax.home,
              color: _selectedIndex == 0 ? Colors.purple : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              LineAwesomeIcons.tag_solid,
              color: _selectedIndex == 1 ? Colors.purple : Colors.grey,
            ),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              LineAwesomeIcons.bullseye_solid,
              color: _selectedIndex == 2 ? Colors.purple : Colors.grey,
            ),
            label: 'Notice',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Iconsax.briefcase,
              color: _selectedIndex == 3 ? Colors.purple : Colors.grey,
            ),
            label: 'Lost & Found',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _selectedIndex == 4 ? Colors.purple : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
