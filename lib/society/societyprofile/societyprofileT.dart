import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/loginsignup/login.dart';
import 'package:cooig_firebase/pdfviewerurl.dart';

import 'package:cooig_firebase/society/societyprofile/editsocietyprofile.dart';

import 'package:cooig_firebase/upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
  List<Map<String, dynamic>> _posts = [];

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

  Future<void> _fetchPosts() async {
    try {
      QuerySnapshot postsSnapshot = await _firestore
          .collection('posts_upload')
          .where('userID', isEqualTo: widget.userid)
          .get();

      setState(() {
        _posts = postsSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'media':
                List<String>.from(data['media'] ?? []), // Cast to List<String>
          };
        }).toList();
      });

      // Debugging: Print fetched posts
      print("Fetched Posts: $_posts");
    } catch (e) {
      print("Error fetching posts: $e");
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
          societyName = userData?['full_name'] ?? "Society Name";
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "Cooig",
          style: GoogleFonts.libreBodoni(
            textStyle: const TextStyle(
              color: Color(0XFF9752C5),
              fontSize: 30,
            ),
          ),
        ),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white), // Drawer icon
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Opens the drawer
            },
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Badge(
              backgroundColor: Color(0xFF635A8F),
              textColor: Colors.white,
              label: Text('5'),
              child: Icon(Icons.notifications, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Badge(
              backgroundColor: Color(0xFF635A8F),
              textColor: Colors.white,
              label: Text('5'),
              child: Icon(Icons.messenger_outline_rounded, color: Colors.white),
            ),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: NavigationDrawer(userId: widget.userid),
      body: Column(children: [
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
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ElevatedButton(
              //   onPressed: () {
              //     // Implement share profile link functionality
              //   },
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Color(0XFF9752C5),
              //     padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(Icons.share, color: Colors.white),
              //       SizedBox(width: 5),
              //       Text(
              //         'Share Profile',
              //         style: TextStyle(color: Colors.white),
              //       ),
              //     ],
              //   ),
              // ),
              // SizedBox(width: 20),
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
                  padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
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
          ),
        ]),

        SizedBox(height: 15),

        // about Display
        Text(
          about ?? 'about goes here :)',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[300]),
        ),

        SizedBox(height: 15),

        // Posts Grid View
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns for the grid
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to the detailed post view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ),
                  );
                },
                child: Image.network(
                  post['media']
                      [0], // Use the first media item for the grid thumbnail
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),

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
      ]),
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
                        String? name = data['full_name'] as String?;
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

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Post Details",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                    post['userImage'] ?? 'https://via.placeholder.com/150'),
              ),
              title: Text(
                post['userName'] ?? 'Unknown',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Posted on ${_formatTimestamp(post['timestamp'])}",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(height: 10),

            // Post Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post['text'] ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Media (Images, Videos, PDFs)
            if (post['media'] != null && post['media'].isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 300,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  aspectRatio: 16 / 9,
                ),
                items: post['media'].map<Widget>((mediaUrl) {
                  if (mediaUrl.endsWith('.mp4') || mediaUrl.endsWith('.mov')) {
                    return VideoPlayerWidget(mediaUrl);
                  } else if (mediaUrl.endsWith('.pdf')) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PDFViewerFromUrl(
                              pdfUrl: mediaUrl,
                              fileName: mediaUrl.split('/').last,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        color: const Color.fromARGB(255, 44, 32, 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf,
                                size: 40, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              mediaUrl.split('/').last,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,
                    );
                  }
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute}";
  }
}
