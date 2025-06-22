import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/academic_section/branch_page.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/chatmain.dart';
import 'package:cooig_firebase/pdfviewerurl.dart';
//import 'package:cooig_firebase/profile/editprofile.dart';
import 'package:cooig_firebase/notifications.dart';
import 'package:cooig_firebase/post.dart';
//import 'package:cooig_firebase/clips.dart'; // Import the ClipsScreen
import 'package:cooig_firebase/search.dart';
import 'package:cooig_firebase/selectuser.dart';
//import 'package:cooig_firebase/upload.dart';
//import 'package:line_icons/line_icons.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
//import 'package:camera/camera.dart'; // Import camera package

//import 'package:chewie/chewie.dart';
//import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
//import 'package:cooig_firebase/PDFViewer.dart';
//import 'package:cooig_firebase/postscreen.dart';
//import 'package:path/path.dart';
//import 'package:carousel_slider/carousel_slider.dart';

// Import the ClipsScreen
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import camera package

//import 'package:chewie/chewie.dart';
//import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
//import 'package:cooig_firebase/PDFViewer.dart';
//import 'package:cooig_firebase/postscreen.dart';
//import 'package:path/path.dart';
//import 'package:carousel_slider/carousel_slider.dart';

class Homepage extends StatefulWidget {
  dynamic userId;

  Homepage({super.key, required this.userId, required int index});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  late Future<DocumentSnapshot> _userDataFuture;

  //get postId => null;

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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        centerTitle: false,
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => BranchPage()));
              },
              icon: const Icon(Icons.school, color: Colors.white),
            ),
            const SizedBox(width: 1),
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MySearchPage(
                              userId: widget.userId,
                            )));
              },
              icon: const Icon(Icons.search, color: Colors.white),
            ),
            const SizedBox(width: 50),
            const Text('Cooig',
                style: TextStyle(color: Colors.white, fontSize: 30.0)),
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
            icon: Icon(Icons.notifications, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => mainChat(currentUserId: widget.userId),
                ),
              );
            },
            icon: Icon(Icons.messenger_outline_rounded, color: Colors.white),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Nav(
        userId: widget.userId,
        index: 0,
      ),
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
        //final posttype = posts["type"];

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
                final posttype = post['type'];

                if (posttype == "poll") {
                  Map<String, String?> selectedOptions = {};
                  return PollWidget(
                    pollId: posts[index].id, // Pass the document ID as pollId
                    userName: userName,
                    userImage: userImage,
                    timestamp: post['timestamp'] ?? Timestamp.now(),
                    question: post['question'] ?? '',
                    options: post['options'] != null
                        ? post['options'].cast<String>()
                        : [],
                    imageUrls: post['imageUrls'] != null
                        ? post['imageUrls'].cast<String>()
                        : [],
                    isTextOption: post['options'] != null,
                    selectedOption: selectedOptions[posts[index].id],
                    onOptionSelected: (String option) {
                      setState(() {
                        selectedOptions[posts[index].id] = option;
                      });
                    },
                  );
                } else {
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
                }
              },
            );
          },
        );
      },
    );
  }
}

class PollWidget extends StatefulWidget {
  final String pollId; // Pass poll ID from Firestore
  final String userName;
  final String userImage;
  final String question;
  final List<String> options;
  final List<String> imageUrls;
  final bool isTextOption;
  final String? selectedOption;
  final Timestamp timestamp;
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
    required this.timestamp,
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

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute}";
  }

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
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    _formatTimestamp(widget.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
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
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.question,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ...widget.options.map((option) {
                  final voteCount = votes[option] ?? 0;
                  final percentage =
                      totalVotes > 0 ? voteCount / totalVotes : 0.0;

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
                                  ? const BorderSide(
                                      color: Colors.blue, width: 2)
                                  : const BorderSide(
                                      color: Colors.white, width: 2),
                            ),
                            minimumSize: const Size(400, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                          ),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        if (widget.selectedOption != null &&
                            widget.selectedOption == option)
                          Positioned(
                            top: 2,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 400 * percentage,
                                  height: 35,
                                  color: const Color.fromRGBO(128, 0, 128, 0.3),
                                ),
                                const SizedBox(height: 0),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    '${(percentage * 100).toStringAsFixed(1)}% ($voteCount votes)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        });
  }
}
*/
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
  int likeCount = 0;
  int commentCount = 0;
  TextEditingController commentController = TextEditingController();
  String? currentUserID = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
        .collection('posts_upload')
        .doc(widget.postID)
        .get();

    if (postSnapshot.exists) {
      Map<String, dynamic> postData =
          postSnapshot.data() as Map<String, dynamic>;

      // Handle likes as a Map<String, dynamic>
      Map<String, dynamic> likesMap = postData['likes'] ?? {};
      List<dynamic> commentsList = postData['comments'] ?? [];

      setState(() {
        likeCount = likesMap.length; // Count the number of keys in the map
        commentCount = commentsList.length;
        isLiked = currentUserID != null &&
            likesMap.containsKey(
                currentUserID); // Check if the current user's ID is in the map
      });
    }
  }

  void _toggleLike() async {
    if (currentUserID == null) {
      print("User is not authenticated.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in to like a post."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Fetch the post document
      DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('posts_upload')
          .doc(widget.postID)
          .get();

      if (!postSnapshot.exists) {
        print("Post does not exist.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post not found."),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Get post data
      Map<String, dynamic> postData =
          postSnapshot.data() as Map<String, dynamic>;
      String postOwnerID = postData['userID'];

      // Prevent users from liking their own posts
      if (currentUserID == postOwnerID) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You cannot like your own post."),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check if the user has already liked the post
      Map<String, dynamic> likesMap = postData['likes'] ?? {};
      bool isCurrentlyLiked = likesMap.containsKey(currentUserID);

      // Update the likes map in Firestore
      if (isCurrentlyLiked) {
        // Remove the user's like
        await FirebaseFirestore.instance
            .collection('posts_upload')
            .doc(widget.postID)
            .update({
          'likes.$currentUserID':
              FieldValue.delete(), // Remove the specific key from the map
        });
      } else {
        // Add the user's like
        await FirebaseFirestore.instance
            .collection('posts_upload')
            .doc(widget.postID)
            .update({
          'likes.$currentUserID': true, // Add the user's ID to the map
        });
      }

      // Update the UI
      setState(() {
        isLiked = !isCurrentlyLiked;
        likeCount = isCurrentlyLiked ? likeCount - 1 : likeCount + 1;
      });

      // Add a notification if the post is liked
      if (!isCurrentlyLiked) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'like',
          'fromUserID': currentUserID,
          'toUserID': postOwnerID,
          'postID': widget.postID,
          'timestamp': Timestamp.now(),
        });
      }

      print("Like toggled successfully.");
    } catch (e) {
      // Log the error and show a snackbar
      print("Error toggling like: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to like the post: ${e.toString()}"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _addComment() async {
    if (commentController.text.isEmpty || currentUserID == null) return;

    DocumentReference postRef = FirebaseFirestore.instance
        .collection('posts_upload')
        .doc(widget.postID);

    // Add the comment to Firestore
    await postRef.update({
      'comments': FieldValue.arrayUnion([
        {
          'userID': currentUserID,
          'text': commentController.text,
          'timestamp': Timestamp.now(),
        }
      ]),
    });

    // Update the UI
    setState(() {
      commentCount++;
    });

    // Clear the comment input field
    commentController.clear();

    // Fetch the post data to get the post owner's ID
    DocumentSnapshot postSnapshot = await postRef.get();
    if (postSnapshot.exists) {
      Map<String, dynamic> postData =
          postSnapshot.data() as Map<String, dynamic>;
      String postOwnerID = postData['userID'];

      // Add a notification for the comment

      // Ensure the commenter is not the post owner
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'comment',
        'fromUserID': currentUserID,
        'toUserID': postOwnerID,
        'postID': widget.postID,
        'timestamp': Timestamp.now(),
        'commentText':
            commentController.text, // Optional: Include the comment text
      });
    }

    print("Comment added successfully.");
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
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Like Button Group
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      onPressed: _toggleLike,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                    Text(
                      '$likeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(width: 16), // Spacing between button groups

                // Comment Button Group
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                    Text(
                      '$commentCount',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(width: 16), // Spacing between button groups

                // Share Button
                IconButton(
                  icon: const Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // Implement share functionality
                    // Share.share('Check out this post!'); You'll need to import 'package:share_plus/share_plus.dart'
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectUserScreen(
                          postID: widget.postID,
                          userName: widget.userName,
                          userImage: widget.userImage,
                          text: widget.text,
                          mediaUrls: widget.mediaUrls,
                          timestamp: widget.timestamp,
                        ),
                      ),
                    );
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/*
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
*/
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

    // Fetch the post data to get the post owner's ID
    DocumentSnapshot postSnapshot = await postRef.get();
    final postData = postSnapshot.data() as Map<String, dynamic>;
    final String postOwnerID = postData['userID'];

    // Add the comment to the post
    await postRef.update({
      'comments': FieldValue.arrayUnion([
        {
          'userID': currentUserID,
          'text': _commentController.text,
          'timestamp': Timestamp.now(),
        }
      ]),
    });

    // Add a notification to the notifications collection
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'comment',
      'fromUserID': currentUserID,
      'toUserID': postOwnerID,
      'postID': widget.postID,
      'timestamp': Timestamp.now(),
      'commentText':
          _commentController.text, // Optional: Include the comment text
      'isRead': false, // Mark the notification as unread
    });

    print("Commented and notification added");
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
