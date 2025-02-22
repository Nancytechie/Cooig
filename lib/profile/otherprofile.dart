import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/individual_chat_screen.dart';
import 'package:cooig_firebase/pdfviewerurl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class Otherprofile extends StatefulWidget {
  dynamic userId;
  final dynamic otheruserid;

  Otherprofile({super.key, required this.userId, required this.otheruserid});

  @override
  State<Otherprofile> createState() => _OtherprofileState();
}

class _OtherprofileState extends State<Otherprofile>
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

  // Profile data
  String? username;
  String? bio;
  String? branch;
  String? year;
  int _bondsCount = 0;
  final int _postsCount = 0; // Replace with actual post count if available
  bool _isBonded = false;

  List<Map<String, dynamic>> _posts = [];

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
          await _firestore.collection('users').doc(widget.otheruserid).get();

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
          .where('userID', isEqualTo: widget.otheruserid)
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

  Future<void> _toggleBondStatus() async {
    if (_isBonded) {
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

      try {
        await _firestore.collection('users').doc(widget.otheruserid).update({
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
      try {
        await _firestore.collection('users').doc(widget.otheruserid).update({
          'bonds': _bondsCount + 1,
          'isBonded': true,
        });

        // Send notification
        await _firestore.collection('notifications').add({
          'type': 'bond',
          'fromUserId': FirebaseAuth.instance.currentUser!.uid,
          'toUserId': widget.otheruserid,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
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
              SizedBox(width: 40),
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
              SizedBox(width: 40),
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
              //   onPressed: _toggleBondStatus,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Color(0XFF9752C5),
              //     padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         _isBonded ? Icons.check : Icons.favorite,
              //         color: Colors.white,
              //       ),
              //       SizedBox(width: 5),
              //       Text(
              //         _isBonded ? 'Bonded' : 'Bond',
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
                        builder: (context) => IndividualChatScreen(
                            currentUserId: widget.userId,
                            chatUserId: widget.otheruserid,
                            fullName: username ?? 'Unknown',
                            image:
                                profilepic ?? 'https://via.placeholder.com/150',
                            backgroundColor:
                                const Color.fromARGB(255, 74, 72, 72))),
                  );

                  // Navigator.pushNamed(
                  //   context,
                  //   '/individual_chat',
                  //   arguments: {
                  // 'currentUserId': widget.userId,
                  // 'chatUserId': widget.otheruserid,
                  // 'fullName': username ??
                  //     'Unknown', // Replace with actual user name
                  // 'image': profilepic ??
                  //     'https://via.placeholder.com/150', // Replace with actual image URL
                  // 'backgroundColor': Colors.black, // Pass background color
                  //   },
                  // );
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
          /*
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
          */
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
/*
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