import 'dart:io';

import 'package:cooig_firebase/appbar.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/loginsignup/login.dart';
import 'package:cooig_firebase/profile/editprofile.dart';
import 'package:cooig_firebase/profile/societydetails.dart';
import 'package:cooig_firebase/upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';

// ignore: depend_on_referenced_packages
class ProfilePage extends StatefulWidget {
  final dynamic userid;

  const ProfilePage({super.key, required this.userid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _bannerImage;
  File? _profilepic;
  String? bannerImageUrl;
  String? profilepic;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final bool _isEditing = false;
  TabController? _tabController;
//profile
  String? username;
  String? bio;
  String? branch;
  String? year;
  int _bondsCount = 0;
  final int _postsCount =
      0; // Replace with actual post count variable if available
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
            .doc(widget.userid)
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
            .doc(widget.userid)
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
  Future<void> _uploadImageToFirebase(File image, bool isBanner) async {
    try {
      final String fileName =
          '${widget.userid}_${isBanner ? 'banner' : 'profile'}.jpg';
      final ref = _storage.ref().child('user_images').child(fileName);

      // Upload image to Firebase Storage
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with the new URL
      await _firestore.collection('users').doc(widget.userid).update({
        isBanner ? 'bannerImageUrl' : 'profilepic': downloadUrl,
      });

      // Update state to reflect changes
      setState(() {
        if (isBanner) {
          bannerImageUrl = downloadUrl;
        } else {
          profilepic = downloadUrl;
        }
      });

      print("Image uploaded and URL updated successfully.");
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      // Fetch user document from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userid).get();

      if (userDoc.exists) {
        // Safely access user data
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        setState(() {
          // Fetch and set the required fields with fallbacks
          username = userData?['username'] ?? "Username";
          bio = userData?['bio'] ?? "Bio goes here";
          branch = userData?['branch'] ?? "Branch";
          year = userData?['year'] ?? "Year";
          _bondsCount = userData?['bonds'] ?? 0;

          // Text controllers for editable fields
          _usernameController.text = username!;
          _bioController.text = bio!;

          // Image URLs
          bannerImageUrl = userData?['bannerImageUrl'];
          profilepic = userData?['profilepic'];
        });
      } else {
        // Handle case where the document does not exist
        setState(() {
          username = "Username";
          bio = "Bio goes here";
          branch = "Branch";
          year = "Year";
          _bondsCount = 0;

          _usernameController.text = username!;
          _bioController.text = bio!;

          bannerImageUrl = null;
          profilepic = null;
        });
      }
    } catch (e) {
      // Handle errors
      print("Error fetching user data: $e");
      setState(() {
        username = "Username";
        bio = "Bio goes here";
        branch = "Branch";
        year = "Year";
        _bondsCount = 0;

        _usernameController.text = username!;
        _bioController.text = bio!;

        bannerImageUrl = null;
        profilepic = null;
      });
    }
  }

/*
  // Navigate to the Edit Profile Page
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userid: widget.userid,
        ),
      ),
    );
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cooig',
        textSize: 30.0,
        //iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      bottomNavigationBar: Nav(userId: widget.userid),
      drawer: NavigationDrawer(userId: widget.userid),
      body: Column(
        children: [
          // Banner and Profile Image Sections
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
                    backgroundImage:
                        profilepic != null ? NetworkImage(profilepic!) : null,
                    child: profilepic == null
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
              /*Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),*/
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0XFF9752C5),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
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
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.message, color: Colors.black),
                    SizedBox(width: 5),
                    Text('Messages',
                        style: GoogleFonts.poppins(color: Colors.black)),
                  ],
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
          _profilepic = File(pickedImage.path);
        }
      });

      // Upload the selected image to Firebase
      if (isBanner) {
        _uploadImageToFirebase(_bannerImage!, true);
      } else {
        _uploadImageToFirebase(_profilepic!, false);
      }
    }
  }
}

class NavigationDrawer extends StatelessWidget {
  final String userId;

  const NavigationDrawer({super.key, required this.userId});

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              padding: const EdgeInsets.all(0),
              child: Center(
                child: Align(
                  alignment: Alignment.center,
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return UserAccountsDrawerHeader(
                          accountEmail: const Text(""),
                          accountName: const Text(""),
                          currentAccountPicture: buildProfilePicture(
                              'https://via.placeholder.com/150', context),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                        );
                      } else {
                        var data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        String? email = data['course_name'] as String?;
                        String? name = data['full_name'] as String?;
                        String? imageUrl = data['profilepic'] as String?;

                        return UserAccountsDrawerHeader(
                          accountEmail: Text(email ?? "No Course Available"),
                          accountName: Text(name ?? "No Name Available"),
                          currentAccountPicture: buildProfilePicture(
                            imageUrl ?? 'https://via.placeholder.com/150',
                            context,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Iconsax.user_edit, color: Colors.white),
              title: const Text("Edit Profile",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      userid: userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(CupertinoIcons.group_solid, color: Colors.white),
              title: const Text(
                "Create Society",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocietyDetailsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.security_safe, color: Colors.white),
              title:
                  const Text("Privacy", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.white),
              title: const Text("Bookmarked",
                  style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(LineIcons.handshake, color: Colors.white),
              title: const Text("Help", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(LineIcons.cog, color: Colors.white),
              title:
                  const Text("Settings", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Iconsax.logout, color: Colors.white),
              title:
                  const Text("Log out", style: TextStyle(color: Colors.white)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                  (route) => false, // Remove all previous routes
                );
              },
            ),
          ],
        ),
      );

  Widget buildProfilePicture(String imageUrl, BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 100, // Adjust size as needed
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2.0, color: Colors.purpleAccent),
            ),
            child: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 3, // Adjust as needed to position the icon
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Screen(
                          userId: userId,
                        )), // Replace with your screen
              );
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(width: 2.0, color: const Color(0xFF5334C7)),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.purple,
                size: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
