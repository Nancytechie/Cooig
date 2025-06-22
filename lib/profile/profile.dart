import 'package:carousel_slider/carousel_slider.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/loginsignup/login.dart';
import 'package:cooig_firebase/pdfviewerurl.dart';
import 'package:cooig_firebase/profile/editprofile.dart';
import 'package:cooig_firebase/society/society_login.dart';
import 'package:cooig_firebase/upload.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:video_player/video_player.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId, required int index});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<DocumentSnapshot> _userDataFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String?> selectedOptions = {};
  //final TextEditingController _usernameController = TextEditingController();
  //final TextEditingController _bioController = TextEditingController();
  // Profile Data Variables
  String? username;
  String? bio;
  String? branch;
  String? year;
  String? bannerImageUrl;
  String? profilepic;
  int _bondsCount = 0;
  int _postsCount = 0;
  bool _isBonded = false;

  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: NavigationDrawer(userId: widget.userId),
      bottomNavigationBar: Nav(
        userId: widget.userId,
        index: 4,
      ),
      body: FutureBuilder(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileBox(),
                const SizedBox(height: 16),
                _buildPostStream(widget.userId),
              ],
            ),
          );
        },
      ),
    );
  }

  /// **Build App Bar**
  AppBar _buildAppBar() {
    return AppBar(
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
        // IconButton(
        //   onPressed: () {},
        //   icon: const Badge(
        //     backgroundColor: Color(0xFF635A8F),
        //     textColor: Colors.white,
        //     label: Text('5'),
        //     child: Icon(Icons.notifications, color: Colors.white),
        //   ),
        // ),
        // IconButton(
        //   onPressed: () {},
        //   icon: const Badge(
        //     backgroundColor: Color(0xFF635A8F),
        //     textColor: Colors.white,
        //     label: Text('5'),
        //     child: Icon(Icons.messenger_outline_rounded, color: Colors.white),
        //   ),
        // ),
      ],
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  /// **Fetch User Data from Firestore**
  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

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
          bannerImageUrl = userData?['bannerImageUrl'];
          profilepic = userData?['profilepic'];
        });
      }
      // Fetch the number of posts by the user
      QuerySnapshot postSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .get();

      setState(() {
        _postsCount = postSnapshot.size; // Count the posts
      });
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  /// **Build Profile Box**
  Widget _buildProfileBox() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found."));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>?;

        // Assign values safely
        String? fetchedUsername = userData?['username'] ?? "Username";
        String? fetchedBio = userData?['bio'] ?? "Bio goes here";
        String? fetchedBranch = userData?['branch'] ?? "Branch";
        String? fetchedYear = userData?['year'] ?? "Year";
        String? fetchedBannerImageUrl = userData?['bannerImageUrl'];
        String? fetchedProfilePic = userData?['profilepic'];

        return Column(
          children: [
            // **Banner & Profile Image**
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey[300],
                  child: fetchedBannerImageUrl != null
                      ? Image.network(fetchedBannerImageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.camera_alt, color: Colors.grey),
                ),
                Positioned(
                  bottom: -50,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: fetchedProfilePic != null
                        ? NetworkImage(fetchedProfilePic)
                        : null,
                    child: fetchedProfilePic == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: 14,
                  child: _buildCircularBox(fetchedBranch!),
                ),
                Positioned(
                  bottom: -60,
                  right: 14,
                  child: _buildCircularBox(fetchedYear!),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // **Username**
            Center(
              child: Text(
                fetchedUsername!,
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 7),

            // **Post Count Display**
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
              ],
            ),

            const SizedBox(height: 15),

            // **Edit Profile Button**
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditProfilePage(userid: widget.userId)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, color: Colors.black),
                  const SizedBox(width: 5),
                  Text('Edit Profile',
                      style: GoogleFonts.poppins(color: Colors.black)),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // **Bio Display**
            Text(
              fetchedBio!,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[300]),
            ),

            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  /// **Build Post Stream**
/*
  Widget _buildPostStream() {
    return StreamBuilder(
      stream: _firestore.collection('posts').where('userId', isEqualTo: widget.userId).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No posts available."));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var post = snapshot.data!.docs[index];
            return ListTile(
              title: Text(post['content']),
              subtitle: Text("Posted on: ${post['timestamp']}"),
            );
          },
        );
      },
    );
  }
*/
  /// **Build Circular Info Boxes**
  ///

  Widget _buildCircularBox(String text) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff50555C),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
      child: Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

Widget _buildPostStream(userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('posts_upload')
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final posts = snapshot.data?.docs ?? [];

      // Filter posts where userID matches widget.userId
      final filteredPosts =
          posts.where((post) => post['userID'] == userId).toList();

      if (filteredPosts.isEmpty) {
        return const Center(child: Text('No posts available.'));
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index].data() as Map<String, dynamic>?;

          if (post == null || !post.containsKey('userID')) {
            return const SizedBox.shrink();
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(post['userID'])
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const SizedBox.shrink();
              }

              final user = userSnapshot.data!.data() as Map<String, dynamic>?;

              if (user == null) {
                return const SizedBox.shrink();
              }

              final userName = user['full_name'] ?? 'Unknown';
              final userImage = user['profilepic'] ?? '';
              final posttype = post['type'];

              if (posttype == "poll") {
                Map<String, String?> selectedOptions = {};
                return PollWidget(
                  pollId: filteredPosts[index].id,
                  userName: userName,
                  userImage: userImage,
                  question: post['question'] ?? '',
                  options: post['options'] != null
                      ? post['options'].cast<String>()
                      : [],
                  imageUrls: post['imageUrls'] != null
                      ? post['imageUrls'].cast<String>()
                      : [],
                  isTextOption: post['options'] != null,
                  selectedOption: selectedOptions[filteredPosts[index].id],
                  onOptionSelected: (String option) {
                    setState(() {
                      selectedOptions[filteredPosts[index].id] = option;
                    });
                  },
                );
              } else {
                return PostWidget(
                  postID: filteredPosts[index].id,
                  userName: userName,
                  userImage: userImage,
                  text: post['text'] ?? '',
                  mediaUrls: post['media'] != null
                      ? List<String>.from(post['media'])
                      : [],
                  timestamp: post['timestamp'] ?? Timestamp.now(),
                );
              }
            },
          );
        },
      );
    },
  );
}

void setState(Null Function() param0) {}

class PollWidget extends StatefulWidget {
  final String pollId; // Pass poll ID from Firestore
  final String userName;
  final String userImage;
  final String question;
  final List<String> options;
  final List<String> imageUrls;
  final bool isTextOption;
  final String? selectedOption;
  final void Function(String option) onOptionSelected;
  const PollWidget({
    super.key,
    required this.pollId,
    required this.userName,
    required this.userImage,
    required this.question,
    required this.options,
    required this.imageUrls,
    required this.isTextOption,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  void _handleVote(String option) async {
    if (widget.selectedOption != null) return;

    widget.onOptionSelected(option);

    final pollRef = FirebaseFirestore.instance
        .collection('posts_upload')
        .doc(widget.pollId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final pollSnapshot = await transaction.get(pollRef);
      if (!pollSnapshot.exists) return;

      final pollData = pollSnapshot.data() as Map<String, dynamic>;
      final votes = Map<String, int>.from(pollData['votes'] ?? {});

      votes[option] = (votes[option] ?? 0) + 1;

      transaction.update(pollRef, {'votes': votes});
    });
  }
/*
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts_upload')
          .doc(widget.pollId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const CircularProgressIndicator();
        }

        final pollData = snapshot.data!.data() as Map<String, dynamic>;
        final votes = Map<String, int>.from(pollData['votes'] ?? {});
        final totalVotes = votes.values.fold(0, (sum, count) => sum + count);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.userImage.isNotEmpty
                        ? NetworkImage(widget.userImage)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.question,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 10),
              ...widget.options.map((option) {
                final voteCount = votes[option] ?? 0;
                final percentage =
                    totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Stack(
                    children: [
                      ElevatedButton(
                        onPressed: widget.selectedOption == null
                            ? () => _handleVote(option)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: widget.selectedOption == option
                                ? const BorderSide(color: Colors.blue, width: 2)
                                : const BorderSide(
                                    color: Colors.white, width: 2),
                          ),
                          minimumSize: const Size(400, 50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(option,
                                style: const TextStyle(color: Colors.white)),
                            Text(
                                '${(percentage * 100).toStringAsFixed(1)}% ($voteCount)',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 400 * percentage,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (totalVotes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Total votes: $totalVotes',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white)),
                ),
            ],
          ),
        );
      },
    );
  }
}
*/

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts_upload')
          .doc(widget.pollId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const CircularProgressIndicator();
        }

        final pollData = snapshot.data!.data() as Map<String, dynamic>;
        final votes = Map<String, int>.from(pollData['votes'] ?? {});
        final totalVotes = votes.values.fold(0, (sum, count) => sum + count);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.userImage.isNotEmpty
                        ? NetworkImage(widget.userImage)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.question,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 10),
              ...widget.options.map((option) {
                final voteCount = votes[option] ?? 0;
                final percentage =
                    totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Stack(
                    children: [
                      ElevatedButton(
                        onPressed: widget.selectedOption == null
                            ? () => _handleVote(option)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: widget.selectedOption == option
                                ? const BorderSide(color: Colors.blue, width: 2)
                                : const BorderSide(
                                    color: Colors.white, width: 2),
                          ),
                          minimumSize: const Size(400, 50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(option,
                                style: const TextStyle(color: Colors.white)),
                            Text(
                                '${(percentage * 100).toStringAsFixed(1)}% ($voteCount)',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 400 * percentage,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (totalVotes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Total votes: $totalVotes',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white)),
                ),
            ],
          ),
        );
      },
    );
  }
}

//void setState(Null Function() param0) {}

class PostWidget extends StatefulWidget {
  final String postID;
  final String userName;
  final String userImage;
  final String text;
  final List<String> mediaUrls;
  final Timestamp timestamp;

  const PostWidget({
    super.key,
    required this.postID,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.mediaUrls,
    required this.timestamp,
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isLiked = false;
  bool showCommentField = false;
  int likeCount = 0;
  int commentCount = 0;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  String? currentUserID = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _fetchPostData() async {
    DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
        .collection('posts_upload')
        .doc(widget.postID)
        .get();

    if (postSnapshot.exists) {
      Map<String, dynamic> postData =
          postSnapshot.data() as Map<String, dynamic>;
      List<dynamic> likesList = postData['likes'] ?? [];
      List<dynamic> commentsList = postData['comments'] ?? [];

      setState(() {
        likeCount = likesList.length;
        commentCount = commentsList.length;
        isLiked = currentUserID != null && likesList.contains(currentUserID);
      });
    }
  }

  void _toggleLike() async {
    if (currentUserID == null) return;

    DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
        .collection('posts_upload')
        .doc(widget.postID)
        .get();

    if (!postSnapshot.exists) return;

    Map<String, dynamic> postData = postSnapshot.data() as Map<String, dynamic>;
    String postOwnerID = postData['userID'];

    if (currentUserID == postOwnerID) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot like your own post."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    List<dynamic> likesList = List.from(postData['likes'] ?? []);
    bool isCurrentlyLiked = likesList.contains(currentUserID);

    // Only proceed if there's a valid state change
    if (isCurrentlyLiked) {
      likesList.remove(currentUserID);
    } else {
      likesList.add(currentUserID);
    }

    int updatedLikeCount = likesList.length;

    await FirebaseFirestore.instance
        .collection('posts_upload')
        .doc(widget.postID)
        .update({
      'likes': likesList,
      'likeCount': updatedLikeCount, // optional: use server-side count
    });

    setState(() {
      isLiked = !isCurrentlyLiked;
      likeCount = updatedLikeCount;
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute}";
  }

  List<Map<String, dynamic>> _classifyMedia(List<String> urls) {
    return urls.map((url) {
      String extension = url.split('?')[0].split('.').last.toLowerCase();
      String type;
      if (extension == 'mp4' || extension == 'mp3') {
        type = 'video';
      } else if (extension == 'pdf') {
        type = 'pdf';
      } else {
        type = 'image';
      }
      return {'url': url, 'type': type};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> media = _classifyMedia(widget.mediaUrls);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.userImage.isNotEmpty
                    ? NetworkImage(widget.userImage)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTimestamp(widget.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.text,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 12),

          // Media Rendering
          if (media.isNotEmpty)
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                aspectRatio: 16 / 9,
              ),
              items: media.map((medi) {
                if (medi['type'] == 'image') {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: Image.network(
                      medi['url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                } else if (medi['type'] == 'video') {
                  return VideoPlayerWidget(medi['url']);
                } else if (medi['type'] == 'pdf') {
                  String url = medi['url'];
                  final String fileName = Uri.decodeFull(
                      url.split('/o/').last.split('?').first.split('%2F').last);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDFViewerFromUrl(
                            pdfUrl: url,
                            fileName: fileName,
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
                          const Icon(Icons.picture_as_pdf,
                              size: 40, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),

          // Like & Comment Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                      size: 20,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    '$likeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.comment,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CommentsScreen(postID: widget.postID),
                        ),
                      );
                    },
                  ),
                  Text(
                    '$commentCount',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget(this.videoUrl, {super.key});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: () {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
              setState(() {});
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                if (!_controller.value.isPlaying)
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 50,
                  ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}

class CommentsScreen extends StatefulWidget {
  final String postID;

  const CommentsScreen({super.key, required this.postID});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  String? currentUserID = FirebaseAuth.instance.currentUser?.uid;
  bool _isEmojiVisible = false;

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || currentUserID == null) return;

    DocumentReference postRef = FirebaseFirestore.instance
        .collection('posts_upload')
        .doc(widget.postID);

    await postRef.update({
      'comments': FieldValue.arrayUnion([
        {
          'userID': currentUserID,
          'text': _commentController.text,
          'timestamp': Timestamp.now(), // Add this line to store timestamp
        }
      ]),
    });

    _commentController.clear();
  }

  String timeAgo(Timestamp timestamp) {
    final DateTime commentTime = timestamp.toDate();
    final DateTime currentTime = DateTime.now();
    final Duration difference = currentTime.difference(commentTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Comments', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts_upload')
            .doc(widget.postID)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final postData = snapshot.data!.data() as Map<String, dynamic>;
          final comments = postData['comments'] as List<dynamic>? ?? [];
          final String postOwnerID = postData['userID']; // Fetch from postID

          final bool isCurrentUserPostOwner = currentUserID == postOwnerID;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index] as Map<String, dynamic>;
                    Timestamp? timestamp =
                        comment['timestamp'] as Timestamp?; // Correct retrieval

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(comment['userID'])
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final userName = userData['full_name'] ?? 'Unknown';
                        final userImage = userData['profilepic'] ?? '';
                        final String timeAgoText = timestamp != null
                            ? timeAgo(timestamp)
                            : 'Unknown time';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userImage.isNotEmpty
                                ? NetworkImage(userImage)
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['text'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeAgoText,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Emoji Picker (Only if user is NOT the post owner)
              if (_isEmojiVisible && !isCurrentUserPostOwner)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _commentController.text += emoji.emoji;
                    },
                  ),
                ),
              // Comment Input Bar (Only if user is NOT the post owner)
              if (!isCurrentUserPostOwner)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: Colors.black,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions,
                            color: Colors.blue),
                        onPressed: _toggleEmojiPicker,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
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
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
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
                              'https://via.placeholder.com/150',
                              context,
                              userId),
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
                              userId),
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
            // ListTile(
            //   leading: const Icon(Iconsax.security_safe, color: Colors.white),
            //   title:
            //       const Text("Privacy", style: TextStyle(color: Colors.white)),
            //   onTap: () {},
            // ),
            // ListTile(
            //   leading: const Icon(Icons.bookmark, color: Colors.white),
            //   title: const Text("Bookmarked",
            //       style: TextStyle(color: Colors.white)),
            //   onTap: () {},
            // ),
            // ListTile(
            //   leading: const Icon(LineIcons.handshake, color: Colors.white),
            //   title: const Text("Help", style: TextStyle(color: Colors.white)),
            //   onTap: () {},
            // ),
            // ListTile(
            //   leading: const Icon(LineIcons.cog, color: Colors.white),
            //   title:
            //       const Text("Settings", style: TextStyle(color: Colors.white)),
            //   onTap: () {},
            // ),
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
}

Widget buildProfilePicture(
    String imageUrl, BuildContext context, String userId) {
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
