/*
import 'package:cooig_firebase/academic_section/branch_page.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/chatmain.dart';
import 'package:cooig_firebase/notifications.dart';
import 'package:cooig_firebase/search.dart';
import 'package:flutter/material.dart';
//import 'nav.dart'; // Ensure Nav is imported

class BaseScreen extends StatelessWidget {
  final Widget body;
  final String userId;

  const BaseScreen({required this.body, required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: body,
      bottomNavigationBar: Nav(
        userId: userId,
        index: 0,
      ), // Persistent Nav Bar
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.black,
      centerTitle: false,
      title: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BranchPage()));
            },
            icon: const Icon(Icons.school, color: Colors.white),
          ),
          const SizedBox(width: 1),
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MySearchPage()));
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          const SizedBox(width: 50),
          const Text('Cooig',
              style: TextStyle(color: Colors.white, fontSize: 30.0)),
        ],
      ),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Notifications(
                          userId: userId,
                        )));
          },
          icon: const Badge(
            backgroundColor: Color(0xFF635A8F),
            textColor: Colors.white,
            label: Text('5'),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => mainChat(currentUserId: userId)));
          },
          icon: const Badge(
            backgroundColor: Color(0xFF635A8F),
            textColor: Colors.white,
            label: Text('5'),
            child: Icon(Icons.messenger_outline_rounded, color: Colors.white),
          ),
        ),
      ],
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

 PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.black,
      centerTitle: false,
      title: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BranchPage()),
              );
            },
            icon: const Icon(Icons.school, color: Colors.white),
          ),
          const SizedBox(width: 1),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MySearchPage()),
              );
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          const SizedBox(width: 50),
          const Text(
            'Cooig',
            style: TextStyle(color: Colors.white, fontSize: 30.0),
          ),
        ],
      ),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => Notifications(userId: widget.userId),
            //   ),
            // );
          },
          icon: const Badge(
            backgroundColor: Color(0xFF635A8F),
            textColor: Colors.white,
            label: Text('5'),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => mainChat(currentUserId: widget.userId),
              ),
            );
          },
          icon: const Badge(
            backgroundColor: Color(0xFF635A8F),
            textColor: Colors.white,
            label: Text('5'),
            child: Icon(Icons.messenger_outline_rounded, color: Colors.white),
          ),
        ),
      ],
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
*/  
