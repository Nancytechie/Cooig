import 'dart:io';

import 'package:cooig_firebase/appbar.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/profile/editprofile.dart';
import 'package:cooig_firebase/profile/societydetails.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// ignore: depend_on_referenced_packages

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _bannerImage;
  File? _profileImage;
  String? bannerImageUrl;
  String? profileImageUrl;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;
  TabController? _tabController;

  String? username;
  String? bio;
  String? branch;
  String? year;
  int _bondsCount = 0;
  int _postsCount = 0; // Replace with actual post count variable if available
  bool _isBonded = false;

  Future<void> _toggleBondStatus() async {
    if (_isBonded) {
      // Show confirmation dialog to unbond
      bool confirmUnbond = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Unbond"),
            content: Text("Are you sure you want to unbond?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Unbond"),
              ),
            ],
          );
        },
      );
      if (!confirmUnbond) return;

      // Unbond action
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'bonds': _bondsCount - 1,
          'isBonded': false,
        });
        setState(() {
          _bondsCount--;
          _isBonded = false;
        });
      } catch (e) {
        print('Failed to unbond: $e');
      }
    } else {
      // Bond action
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'bonds': _bondsCount + 1,
          'isBonded': true,
        });
        setState(() {
          _bondsCount++;
          _isBonded = true;
        });
      } catch (e) {
        print('Failed to bond: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUserData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

    setState(() {
      username = userDoc['username'] ?? 'Username';
      bio = userDoc['bio'] ?? 'Bio goes here';
      branch = userDoc['branch'] ?? 'Branch';
      year = userDoc['year'] ?? 'Year';
      _usernameController.text = username ?? '';
      _bioController.text = bio ?? '';
      _bondsCount = userDoc['bonds'] ?? 0;
      // Fetching image URLs (if available)
      bannerImageUrl = userDoc['bannerImageUrl'];
      profileImageUrl = userDoc['profileImageUrl'];
    });
  }

  // Upload image to Firebase Storage
  Future<void> _uploadImageToFirebase(File imageFile, bool isBanner) async {
    try {
      String path =
          'user_${_auth.currentUser!.uid}/${isBanner ? "banner" : "profile"}';
      UploadTask uploadTask = _storage.ref(path).putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        isBanner ? 'bannerImageUrl' : 'profileImageUrl': downloadUrl,
      });

      setState(() {
        if (isBanner) {
          bannerImageUrl = downloadUrl;
        } else {
          profileImageUrl = downloadUrl;
        }
      });
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  // Navigate to the Edit Profile Page
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cooig',
        textSize: 30.0,
      ),
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Banner and Profile Image Section
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey[300],
                  child: bannerImageUrl != null
                      ? Image.network(bannerImageUrl!, fit: BoxFit.cover)
                      : Icon(Icons.camera_alt, color: Colors.grey[700]),
                ),
              ),
              Positioned(
                bottom: -50,
                child: GestureDetector(
                  onTap: () => _pickImage(false),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey[700])
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: 14,
                child: _buildCircularBox(branch ?? 'Branch'),
              ),
              Positioned(
                bottom: -60,
                right: 14,
                child: _buildCircularBox(year ?? 'Year'),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _navigateToEditProfile,
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 60),

          // Username Display
          Center(
            child: Text(
              username ?? 'Username',
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 7),

          // Post and Bond Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    _postsCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Posts',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    _bondsCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Bonds',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 15),

          // Bond Action Button
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _toggleBondStatus,
                child: Row(
                  children: [
                    Icon(
                      _isBonded ? Icons.check : Icons.favorite,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      _isBonded ? 'Bonded' : 'Bond',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0XFF9752C5),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Icon(Icons.message, color: Colors.black),
                    SizedBox(width: 5),
                    Text('Messages',
                        style: GoogleFonts.poppins(color: Colors.black)),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),

          // Bio Display
          Text(
            bio ?? 'Bio goes here :)',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[300]),
          ),

          SizedBox(height: 15),

          // Tab Bar
          // TabBar(
          //   controller: _tabController,
          //   tabs: [
          //     Tab(text: 'Posts'),
          //     Tab(text: 'Highlights'),
          //     Tab(text: 'Clips'),
          //     Tab(text: 'Bookmark'),
          //   ],
          //   labelColor: Colors.white,
          //   unselectedLabelColor: Color.fromARGB(255, 187, 183, 183),
          //   indicatorColor: Colors.purple[50],
          //   dividerColor: Colors.black,
          // ),

          // // Tab Views Content
          // Expanded(
          //   child: TabBarView(
          //     controller: _tabController,
          //     children: [
          //       Center(child: Text('Posts Content')),
          //       Center(child: Text('Highlights Content')),
          //       Center(child: Text('Clips Content')),
          //       Center(child: Text('Bookmark Content')),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Helper function to display circular boxes (branch/year)
  Widget _buildCircularBox(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff50555C),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 30),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  // Image picker function
  Future<void> _pickImage(bool isBanner) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        if (isBanner) {
          _bannerImage = File(pickedImage.path);
        } else {
          _profileImage = File(pickedImage.path);
        }
      });

      // Upload the selected image to Firebase
      if (isBanner) {
        _uploadImageToFirebase(_bannerImage!, true);
      } else {
        _uploadImageToFirebase(_profileImage!, false);
      }
    }
  }
}
