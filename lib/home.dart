  import 'package:card_swiper/card_swiper.dart';
  import 'package:carousel_slider/carousel_slider.dart';
  import 'package:chewie/chewie.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:cooig_firebase/academic_section/branch_page.dart';
  import 'package:cooig_firebase/bar.dart';
  import 'package:cooig_firebase/chatmain.dart';
  import 'package:cooig_firebase/pdfviewerurl.dart';
  import 'package:cooig_firebase/profile/editprofile.dart';
  import 'package:cooig_firebase/notifications.dart';
  import 'package:cooig_firebase/post.dart';
  import 'package:cooig_firebase/clips.dart'; // Import the ClipsScreen
  import 'package:cooig_firebase/search.dart';
  import 'package:cooig_firebase/upload.dart';
  import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:iconsax_flutter/iconsax_flutter.dart';
  import 'package:line_icons/line_icons.dart';
  import 'package:flutter/material.dart';
  import 'package:pro_image_editor/pro_image_editor.dart';
  import 'package:video_player/video_player.dart';
  import 'package:camera/camera.dart'; // Import camera package

  import 'package:carousel_slider/carousel_slider.dart';
  //import 'package:chewie/chewie.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:cooig_firebase/academic_section/branch_page.dart';
  import 'package:cooig_firebase/bar.dart';
  import 'package:cooig_firebase/chatmain.dart';
  //import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
  import 'package:cooig_firebase/notifications.dart';
  //import 'package:cooig_firebase/PDFViewer.dart';
  import 'package:cooig_firebase/pdfviewerurl.dart';
  import 'package:cooig_firebase/search.dart';
  //import 'package:cooig_firebase/postscreen.dart';
  import 'package:flutter/material.dart';
  import 'package:iconsax_flutter/iconsax_flutter.dart';
  //import 'package:path/path.dart';
  import 'package:cooig_firebase/post.dart';
  import 'package:percent_indicator/linear_percent_indicator.dart';
  import 'package:video_player/video_player.dart';
  //import 'package:carousel_slider/carousel_slider.dart';

  class Homepage extends StatefulWidget {
    dynamic userId;

    Homepage({super.key, required this.userId});

    @override
    State<Homepage> createState() => _HomePageState();
  }

  class _HomePageState extends State<Homepage> {
    late Future<DocumentSnapshot> _userDataFuture;

    @override
    void initState() {
      super.initState();
      _userDataFuture =
          FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
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
                icon: const Icon(
                  Icons.school,
                  color: Colors.white,
                ),
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
              const SizedBox(width: 80),
              Text(
                'Cooig',
                style: GoogleFonts.libreBodoni(
                  textStyle: TextStyle(
                    color: const Color(0XFF9752C5),
                    fontSize: 23, // White text for contrast
                  ),
                ),
              ),
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
                      userId: widget.userId,
                    ),
                  ),
                );
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
                    builder: (context) => mainChat(
                      currentUserId: widget.userId,
                    ),
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
        ),
        bottomNavigationBar: Nav(userId: widget.userId),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserPostInput(widget.userId),
              const SizedBox(height: 16),
              _buildPostStream(),
            ],
          ),
        ),
      );
    }

    Widget _buildUserPostInput(userId) {
      return Center(
        child: InkWell(
          splashColor: Colors.blue.withOpacity(0.3),
          highlightColor: Colors.transparent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostScreen(userId: userId),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            width: 250,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: FutureBuilder<DocumentSnapshot>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildPlaceholderInput();
                } else {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  String? imageUrl = data['profilepic'] as String?;
                  return _buildUserInputRow(imageUrl);
                }
              },
            ),
          ),
        ),
      );
    }

    Widget _buildPlaceholderInput() {
      return const Row(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 5.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
          ),
          SizedBox(width: 16),
          Text(
            "What's on your head?",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Arial',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    Widget _buildUserInputRow(String? imageUrl) {
      return Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage:
                  NetworkImage(imageUrl ?? 'https://via.placeholder.com/150'),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "What's on your head?",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Arial',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    Widget _buildPostStream() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts_upload')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!mounted) return const SizedBox.shrink();
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data?.docs ?? [];

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>?;

              if (post == null || !post.containsKey('userID')) {
                return const SizedBox.shrink(); // Null safety check
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(post['userID'])
                    .get(),
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

                  return PostWidget(
                    postID: posts[index].id,
                    userName: userName,
                    userImage: userImage,
                    text: post['text'] ?? '',
                    mediaUrls: post['media'] != null
                        ? List<String>.from(post['media'])
                        : [],
                    timestamp: post['timestamp'] ?? Timestamp.now(),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

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

      List<dynamic> likesList = postData['likes'] ?? [];
      bool isCurrentlyLiked = likesList.contains(currentUserID);

      await FirebaseFirestore.instance
          .collection('posts_upload')
          .doc(widget.postID)
          .update({
        'likes': isCurrentlyLiked
            ? FieldValue.arrayRemove([currentUserID])
            : FieldValue.arrayUnion([currentUserID])
      });

      setState(() {
        isLiked = !isCurrentlyLiked;
        likeCount = isCurrentlyLiked ? likeCount - 1 : likeCount + 1;
      });
    }

    // void _addComment() async {
    //   if (commentController.text.isEmpty || currentUserID == null) return;

    //   DocumentReference postRef = FirebaseFirestore.instance
    //       .collection('posts_upload')
    //       .doc(widget.postID);

    //   await postRef.update({
    //     'comments': FieldValue.arrayUnion([
    //       {
    //         'userID': currentUserID,
    //         'text': commentController.text,
    //       }
    //     ]),
    //   });

    //   setState(() {
    //     commentCount++;
    //   });

    //   commentController.clear();
    // }

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

  class PollWidget extends StatefulWidget {
    final String userName;
    final String userImage;
    final String question;
    final List<String> options;
    final List<String> imageUrls;
    final bool isTextOption;

    const PollWidget({
      super.key,
      required this.userName,
      required this.userImage,
      required this.question,
      required this.options,
      required this.imageUrls,
      required this.isTextOption,
    });

    @override
    _PollWidgetState createState() => _PollWidgetState();
  }

  class _PollWidgetState extends State<PollWidget> {
    String? selectedOption;
    Map<String, int> votes = {}; // To store votes per option
    int totalVotes = 0; // To store total votes

    void _handleVote(String option) {
      setState(() {
        if (selectedOption == null) {
          selectedOption = option;
          votes[option] = (votes[option] ?? 0) + 1;
          totalVotes += 1;
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.userImage.isNotEmpty
                      ? NetworkImage(widget.userImage)
                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Iconsax.settings,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              widget.question,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            if (widget.isTextOption)
              ...widget.options.map((option) {
                double percentage =
                    totalVotes > 0 ? (votes[option] ?? 0) / totalVotes : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: selectedOption == null
                            ? () => _handleVote(option)
                            : null,
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.white, width: 2),
                          ),
                          minimumSize: Size(400, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (selectedOption != null) ...[
                        SizedBox(height: 10),
                        LinearPercentIndicator(
                          width: MediaQuery.of(context).size.width - 60,
                          lineHeight: 24.0,
                          percent: percentage,
                          backgroundColor: Colors.grey,
                          progressColor: Colors.purple,
                          center: Text(
                            "${(percentage * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      );
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

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(comment['userID'])
                            .get(),
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
