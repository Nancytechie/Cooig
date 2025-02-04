import 'dart:io';

import 'package:cooig_firebase/appbar.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/loginsignup/login.dart';

import 'package:cooig_firebase/society/societyprofile/editsocietyprofile.dart';

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
import 'package:url_launcher/url_launcher.dart';

// ignore: depend_on_referenced_packages
class Societyprofile extends StatefulWidget {
  final dynamic userid;

  const Societyprofile({super.key, required this.userid});

  @override
  State<Societyprofile> createState() => _SocietyprofileState();
}

class _SocietyprofileState extends State<Societyprofile>
    with SingleTickerProviderStateMixin {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _bannerImage;
  File? _profilepic;
  String? bannerImageUrl;
  String? profilepic;
  TextEditingController _societyNameController = TextEditingController();
  TextEditingController _aboutController = TextEditingController();
  final _LinkController = TextEditingController();

  bool _isEditing = false;
  TabController? _tabController;
//profile
  String? societyName;
  String? about;
  String? category;
  String? establishedYear;
  String? status;
  String? link;
  Future<void> _openLink(BuildContext context, String url) async {
    debugPrint('Opening URL: $url'); // Log the URL for debugging
    if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme == true) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Could not launch URL: $url'); // Log the error
          throw 'Could not open the link';
        }
      } catch (e) {
        debugPrint('Error launching URL: $e'); // Log the exception
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    } else {
      debugPrint('Invalid URL provided: $url'); // Log invalid URLs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid URL')),
      );
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
          societyName = userData?['societyName'] ?? "Society Name";
          about = userData?['about'] ?? "About goes here";
          category = userData?['category'] ?? "Category";
          establishedYear = userData?['establishedYear'] ?? "Year";
          status = userData?['status'] ?? "Non-Recruiting";
          link = userData?['Link'] ?? "";

          // Text controllers for editable fields
          _societyNameController.text = societyName!;
          _aboutController.text = about!;

          // Image URLs
          bannerImageUrl = userData?['bannerImageUrl'] ?? null;
          profilepic = userData?['profilepic'] ?? null;
        });
      } else {
        // Handle case where the document does not exist
        setState(() {
          societyName = "Society Name";
          about = "About goes here";
          category = "Category";
          establishedYear = "Year";

          _societyNameController.text = societyName!;
          _aboutController.text = about!;

          bannerImageUrl = null;
          profilepic = null;
        });
      }
    } catch (e) {
      // Handle errors
      print("Error fetching user data: $e");
      setState(() {
        societyName = "Society Name";
        about = "About goes here";
        category = "Category";
        establishedYear = "Year";

        _societyNameController.text = societyName!;
        _aboutController.text = about!;

        bannerImageUrl = null;
        profilepic = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isCurrentUser = currentUserId == widget.userid;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cooig',
        textSize: 30.0,
        //iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      bottomNavigationBar: Nav(userId: widget.userid),
      drawer: isCurrentUser ? NavigationDrawer(userId: widget.userid) : null,
      body: Column(
        children: [
          // Banner and Profile Image Sections
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GestureDetector(
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
                bottom: -50,
                left: 14,
                child: _buildCircularBox(category ?? 'category'),
              ),
              Positioned(
                bottom: -50,
                right: 14,
                child: _buildCircularBox(establishedYear ?? 'establishedYear'),
              ),
            ],
          ),

          SizedBox(height: 60),

          // societyName Display
          Center(
            child: Row(
              mainAxisSize: MainAxisSize
                  .min, // Ensures the Row takes up only as much space as needed
              children: [
                Text(
                  societyName ?? 'Society Name',
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                    width: 2), // Add spacing between the text and the icon
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ],
            ),
          ),

          SizedBox(height: 7),

          // Post and Bond Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [],
              ),
            ],
          ),

          // Bond Action Button
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCurrentUser)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Implement share profile link functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF9752C5),
                        padding:
                            EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.share, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Share Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSocietyprofile(
                              userid: widget.userid,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.black),
                          SizedBox(width: 5),
                          Text('Edit Profile',
                              style: GoogleFonts.poppins(color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // The Join button
                ElevatedButton(
                  onPressed: status == 'Recruiting'
                      ? () {
                          _openLink(context, link!);
                        }
                      : null, // Disable the button if not recruiting
                  child: Row(
                    children: [
                      Icon(
                        Icons.group_add, // Icon for joining
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Join', // Text on the button
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'Recruiting'
                        ? Colors.blue // Blue for recruiting
                        : Colors.grey, // Grey for not recruiting
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

          // about Display
          Text(
            about ?? 'about goes here :)',
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

  // Helper function to display circular boxes (category/establishedYear)
  Widget _buildCircularBox(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 112, 24, 171),
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
                        String? email = data['category'] as String?;
                        String? name = data['societyName'] as String?;
                        String? imageUrl = data['profilepic'] as String?;

                        return UserAccountsDrawerHeader(
                          accountEmail: Text(email ?? "No category Available"),
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
              title: const Text("Edit Society Profile",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSocietyprofile(
                      userid: userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.white),
              title: const Text("Recruitment",
                  style: TextStyle(color: Colors.white)),
              onTap: () {},
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
              leading: const Icon(Icons.swap_calls, color: Colors.white),
              title: const Text("Switch to main account",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ));
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.logout, color: Colors.white),
              title:
                  const Text("Log out", style: TextStyle(color: Colors.white)),
              onTap: () {},
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
