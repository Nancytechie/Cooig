/*
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cooig_firebase/appbar.dart'; // Replace with your actual import
import 'package:cooig_firebase/bar.dart'; // Replace with your actual import
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/loginsignup/login.dart'; // Replace with your actual import
import 'package:cooig_firebase/pdfviewerurl.dart';
import 'package:cooig_firebase/profile/editprofile.dart'; // Replace with your actual import
import 'package:cooig_firebase/society/society_login.dart'; // Replace with your actual import
import 'package:cooig_firebase/society/societyprofile/editsocietyprofile.dart';
import 'package:cooig_firebase/upload.dart'; // Replace with your actual import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';

class ProfilePage extends StatefulWidget {
  final dynamic userid;

  const ProfilePage({super.key, required this.userid, required int index});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
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
  List<Map<String, dynamic>> _posts = [];

  // Profile data
  String? username;
  String? bio;
  String? branch;
  String? year;
  int _bondsCount = 0;
  final int _postsCount = 0; // Replace with actual post count if available
  bool _isBonded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUserData();
    _fetchPosts();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userid).get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        setState(() {
          username = userData?['username'] ?? "Username";
          bio = userData?['bio'] ?? "Bio goes here";
          branch = userData?['branch'] ?? "Branch";
          year = userData?['year'] ?? "Year";
          _bondsCount = userData?['bonds'] ?? 0;
          _isBonded = userData?['isBonded'] ?? false;

          _usernameController.text = username!;
          _bioController.text = bio!;

          bannerImageUrl = userData?['bannerImageUrl'];
          profilepic = userData?['profilepic'];
        });
      } else {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cooig',
        textSize: 30.0,
      ),
      backgroundColor: Colors.black,
      bottomNavigationBar: Nav(
        userId: widget.userid,
        index: 4,
      ),
      drawer: NavigationDrawer(userId: widget.userid),
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
                bottom: -60,
                left: 14,
                child: _buildCircularBox(branch ?? 'Branch'),
              ),
              Positioned(
                bottom: -60,
                right: 14,
                child: _buildCircularBox(year ?? 'Year'),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _posts.length.toString(),
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
              // SizedBox(width: 40),
              // Column(
              //   children: [
              //     Text(
              //       _bondsCount.toString(),
              //       style: GoogleFonts.poppins(
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //         color: Colors.white,
              //       ),
              //     ),
              //     Text(
              //       'Bonds',
              //       style: GoogleFonts.poppins(
              //         fontSize: 14,
              //         color: Colors.grey[300],
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),

          SizedBox(height: 15),

          // Conditional Buttons

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
                      builder: (context) => EditProfilePage(
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

          SizedBox(height: 15),

          // Bio Display
          Text(
            bio ?? 'Bio goes here :)',
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
        ],
      ),
    );
  }

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
                "Society login",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocietyLogin(),
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

/*class PostDetailScreen extends StatelessWidget {}*/

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
*/