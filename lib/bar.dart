import 'package:cooig_firebase/lostandfound/foundpage.dart';
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/profile/profile.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';
//import 'package:cooig_firebase/search.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class Nav extends StatefulWidget {
  final dynamic userId;

  const Nav({super.key, required this.userId});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(
                    userid: widget.userId,
                  )),
        );

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
