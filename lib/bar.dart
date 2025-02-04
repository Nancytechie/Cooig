import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/lostandfound/foundpage.dart';
import 'package:cooig_firebase/home.dart' hide Container, SizedBox;
import 'package:cooig_firebase/lostandfound/lostpage.dart';
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

import 'package:badges/badges.dart' as badges;

class Nav extends StatefulWidget {
  final dynamic userId;

  const Nav({super.key, required this.userId});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;
  int _unseenHomePosts = 0; // Track unseen posts for Home
  int _unseenShopPosts = 0; // Track unseen posts for Shop
  int _unseenNoticePosts = 0; // Track unseen posts for Noticeboard
  int _unseenFoundPosts = 0; // Track unseen posts for Found\

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

  @override
  void initState() {
    super.initState();
    _fetchUnseenPostCounts(); // Fetch unseen post counts when the widget initializes
  }

  Future<void> _fetchUnseenPostCounts() async {
    // Fetch unseen post counts for each page
    _unseenHomePosts = await _getUnseenPostCount('posts_upload');
    _unseenShopPosts = await _getUnseenPostCount(
        'sellposts'); // Replace with your collection name
    _unseenNoticePosts = await _getUnseenPostCount('noticeposts');
    _unseenFoundPosts = await _getUnseenPostCount(
        'lostpost'); // Replace with your collection name

    setState(() {}); // Update the UI
  }

  Future<int> _getUnseenPostCount(String collectionName) async {
    // Fetch all posts from the collection
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();

    // Fetch the list of seen post IDs from local storage or Firestore
    List<String> seenPostIds = await _getSeenPostIds(collectionName);

    // Calculate the number of unseen posts
    int unseenCount = 0;
    for (var doc in snapshot.docs) {
      if (!seenPostIds.contains(doc.id)) {
        unseenCount++;
      }
    }

    return unseenCount;
  }

  Future<List<String>> _getSeenPostIds(String collectionName) async {
    // Fetch seen post IDs from local storage or Firestore
    // Example using SharedPreferences:
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // return prefs.getStringList('seen_$collectionName') ?? [];

    // Example using Firestore:
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    return List<String>.from(userDoc['seen_$collectionName'] ?? []);
  }

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == index) {
      return;
    }

    // Reset the badge count for the selected page
    switch (index) {
      case 0:
        await _markPostsAsSeen('posts_upload');
        _unseenHomePosts = 0;
        break;
      case 1:
        await _markPostsAsSeen(
            'shop_posts'); // Replace with your collection name
        _unseenShopPosts = 0;
        break;
      case 2:
        await _markPostsAsSeen('noticeposts');
        _unseenNoticePosts = 0;
        break;
      case 3:
        await _markPostsAsSeen('lostpost'); // Replace with your collection name
        _unseenFoundPosts = 0;
        break;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the selected page
    String userRole = await getUserRole();
    switch (_selectedIndex) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Homepage(userId: widget.userId)),
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
              builder: (context) => Noticeboard(userId: widget.userId)),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Lostpage(userId: widget.userId)),
        );
        break;
      case 4:
        if (userRole == "Society") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Societyprofile(userid: widget.userId)),
          );
        } else if (userRole == "Student") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ProfilePage(userid: widget.userId)),
          );
        }
        break;
    }
  }

  Future<void> _markPostsAsSeen(String collectionName) async {
    // Fetch all post IDs from the collection
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();

    // Save the list of seen post IDs to local storage or Firestore
    List<String> seenPostIds = snapshot.docs.map((doc) => doc.id).toList();

    // Example using SharedPreferences:
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setStringList('seen_$collectionName', seenPostIds);

    // Example using Firestore:
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'seen_$collectionName': seenPostIds,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                _unseenHomePosts.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: _unseenHomePosts > 0,
              child: Icon(Iconsax.home),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                _unseenShopPosts.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: _unseenShopPosts > 0,
              child: Icon(LineAwesomeIcons.tag_solid),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                _unseenNoticePosts.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: _unseenNoticePosts > 0,
              child: Icon(LineAwesomeIcons.bullseye_solid),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                _unseenFoundPosts.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: _unseenFoundPosts > 0,
              child: Icon(Iconsax.briefcase),
            ),
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
