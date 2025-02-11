/*
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
*/
/*
import 'package:cooig_firebase/home.dart';
//import 'package:cooig_firebase/lostandfound/lostpage.dart';
import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/profile/profile.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:badges/badges.dart' as badges;

//import 'homepage.dart';
//import 'shopscreen.dart';
//import 'noticeboard.dart';
//import 'lostpage.dart';
//import 'profile_page.dart';
//import 'society_profile.dart';

class Nav extends StatefulWidget {
  final dynamic userId;

  const Nav({super.key, required this.userId});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      Homepage(userId: widget.userId),
      Shopscreen(userId: widget.userId),
      Noticeboard(userId: widget.userId),
      PostScreen(userId: widget.userId),
      ProfilePage(userid: widget.userId),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
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
*/
/*
import 'package:cooig_firebase/basescreen.dart';
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/profile/profile.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';
import 'package:flutter/material.dart';

class Nav extends StatefulWidget {
  final String userId;

  const Nav({Key? key, required this.userId}) : super(key: key);

  @override
  _NavState createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BaseScreen(body: Homepage(userId: widget.userId), userId: widget.userId),
      BaseScreen(
          body: Shopscreen(userId: widget.userId), userId: widget.userId),
      BaseScreen(
          body: Noticeboard(userId: widget.userId), userId: widget.userId),
      BaseScreen(
          body: PostScreen(userId: widget.userId), userId: widget.userId),
      BaseScreen(
          body: ProfilePage(userid: widget.userId), userId: widget.userId),
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
      body: IndexedStack(
        // ✅ Prevents unnecessary rebuilding
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notice'),
          BottomNavigationBarItem(
              icon: Icon(Icons.business), label: 'Lost & Found'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
*/
/*
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/profile/profile.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:cloud_firestore/cloud_firestore.dart';

class Nav extends StatefulWidget {
  final String userId;

  Nav({required this.userId});

  @override
  _NavState createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;
  int _unseenHomePosts = 0;
  int _unseenShopPosts = 0;
  int _unseenNoticePosts = 0;
  int _unseenFoundPosts = 0;

  final List<Widget> _pages = [
    Homepage(userId: 'userId'), // Replace with your pages
    Shopscreen(userId: 'userId'),
    Noticeboard(userId: 'userId'),
    PostScreen(userId: 'userId'),
    ProfilePage(userid: 'userId'), // Replace with your profile page
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnseenPostCounts();
  }

  Future<void> _fetchUnseenPostCounts() async {
    _unseenHomePosts = await _getUnseenPostCount('posts_upload');
    _unseenShopPosts = await _getUnseenPostCount('sellposts');
    _unseenNoticePosts = await _getUnseenPostCount('noticeposts');
    _unseenFoundPosts = await _getUnseenPostCount('lostpost');

    setState(() {});
  }

  Future<int> _getUnseenPostCount(String collectionName) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();
    List<String> seenPostIds = await _getSeenPostIds(collectionName);

    int unseenCount = 0;
    for (var doc in snapshot.docs) {
      if (!seenPostIds.contains(doc.id)) {
        unseenCount++;
      }
    }

    return unseenCount;
  }

  Future<List<String>> _getSeenPostIds(String collectionName) async {
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

    switch (index) {
      case 0:
        await _markPostsAsSeen('posts_upload');
        _unseenHomePosts = 0;
        break;
      case 1:
        await _markPostsAsSeen('sellposts');
        _unseenShopPosts = 0;
        break;
      case 2:
        await _markPostsAsSeen('noticeposts');
        _unseenNoticePosts = 0;
        break;
      case 3:
        await _markPostsAsSeen('lostpost');
        _unseenFoundPosts = 0;
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _markPostsAsSeen(String collectionName) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();
    List<String> seenPostIds = snapshot.docs.map((doc) => doc.id).toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'seen_$collectionName': seenPostIds,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: Container(
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
                child: Icon(Icons.home),
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
                child: Icon(Icons.shopping_cart),
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
                child: Icon(Icons.notifications),
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
                child: Icon(Icons.search),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF635A8F),
          onTap: _onItemTapped,
          unselectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
*/

import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/lostandfound/lostpage.dart';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/profile/profile.dart';
import 'package:cooig_firebase/shop/shopscreen.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

class Nav extends StatefulWidget {
  final dynamic userId;
  final int index; // Added index parameter

  const Nav({super.key, required this.userId, required this.index});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index; // Initialize index from widget
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Homepage(userId: widget.userId, index: 0)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  Shopscreen(userId: widget.userId, index: 1)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  Noticeboard(userId: widget.userId, index: 2)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Lostpage(userId: widget.userId, index: 3)),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfilePage(userid: widget.userId, index: 4)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      items: [
        BottomNavigationBarItem(icon: Icon(Iconsax.home), label: ''),
        BottomNavigationBarItem(
            icon: Icon(LineAwesomeIcons.tag_solid), label: ''),
        BottomNavigationBarItem(
            icon: Icon(LineAwesomeIcons.bullseye_solid), label: ''),
        BottomNavigationBarItem(
            icon: Icon(LineAwesomeIcons.briefcase_solid), label: ''),
        BottomNavigationBarItem(
            icon: Icon(
              Iconsax.user,
              size: 20,
            ),
            label: ''),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF635A8F),
      unselectedItemColor: Colors.white,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }
}
