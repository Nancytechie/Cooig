import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/profile/profile.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class BottomNavScreen extends StatefulWidget {
  final dynamic userId;
  const BottomNavScreen({super.key, required this.userId});

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      Homepage(
        userId: widget.userId,
        index: 0,
      ),
      Shopscreen(
        userId: widget.userId,
        index: 1,
      ),
      Noticeboard(
        userId: widget.userId,
        index: 2,
      ),
      PostScreen(userId: widget.userId),
      ProfilePage(
        userid: widget.userId,
        index: 4,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple, // Active icon color
        unselectedItemColor: Colors.grey, // Inactive icon color
        items: [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home,
                color: _selectedIndex == 0 ? Colors.purple : Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LineAwesomeIcons.tag_solid,
                color: _selectedIndex == 1 ? Colors.purple : Colors.grey),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(LineAwesomeIcons.bullseye_solid,
                color: _selectedIndex == 2 ? Colors.purple : Colors.grey),
            label: 'Notice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.briefcase,
                color: _selectedIndex == 3 ? Colors.purple : Colors.grey),
            label: 'Lost & Found',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _selectedIndex == 4 ? Colors.purple : Colors.grey),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
