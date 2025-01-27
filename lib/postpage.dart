import 'package:carousel_slider/carousel_slider.dart';
//import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:cooig_firebase/PDFViewer.dart';
import 'package:cooig_firebase/pdfviewerurl.dart';
//import 'package:cooig_firebase/postscreen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
//import 'package:path/path.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:video_player/video_player.dart';
//import 'package:carousel_slider/carousel_slider.dart';

class PostPage extends StatefulWidget {
  dynamic userid;

  PostPage({super.key, required this.userid});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts_upload')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!mounted) return SizedBox.shrink();
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(post['userID'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final user =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = user['full_name'] ?? 'Unknown';
                  final userImage = user['profilepic'] ?? '';

                  return PostWidget(
                    userName: userName,
                    userImage: userImage,
                    text: post['text'] ?? '',
                    mediaUrls: post['media'] != null
                        ? List<String>.from(post['media'])
                        : [],
                    timestamp: post['timestamp'],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final String userName;
  final String userImage;
  final String text;
  final List<String> mediaUrls;
  final Timestamp timestamp;

  const PostWidget({
    super.key,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.mediaUrls,
    required this.timestamp,
  });

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
    List<Map<String, dynamic>> media = _classifyMedia(mediaUrls);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
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
                backgroundImage: userImage.isNotEmpty
                    ? NetworkImage(userImage)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // Iterate through the documents

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
        ],
      ),
    );
  }
}
/*
else if (medi['type'] == 'pdf') {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PDFViewerScreen(fileUrl: medi['url']),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          medi['url'].split('/').last,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
      ],
    ),
  );
}


*/
/*
Container(
                width: MediaQuery.of(context).size.width,
                height: 300,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                color: const Color.fromARGB(255, 26, 25, 25),
                child: FutureBuilder<DocumentSnapshot>(
                  future: _userDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return const Center(
                          child: Text('Error fetching user data'));
                    } else {
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      String? profileImageUrl = data['image'] as String?;
                      String? userName = data['full_name'] as String?;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Profile and Name
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: profileImageUrl != null &&
                                        profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : const AssetImage(
                                            'assets/default_avatar.png')
                                        as ImageProvider,
                                radius: 25,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                userName ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  // Handle settings action
                                },
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Posts or Media Content
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection(widget.userId)
                                  .where('userID', isEqualTo: widget.userId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                      child: Text('No Posts found'));
                                }

                                // Create a local list to hold media
                                List<Map<String, dynamic>> listOfMedia = [];
                                // Iterate through the documents
                                for (var doc in snapshot.data!.docs) {
                                  var urls = doc['urls'] as List;
                                  for (var url in urls) {
                                    String extension = url
                                        .split('?')[0]
                                        .split('.')
                                        .last; // Extract the extension
                                    listOfMedia.add({
                                      'url': url,
                                      'type': (extension == 'mp4' ||
                                              extension == 'mp3')
                                          ? 'video'
                                          : 'image',
                                    });
                                  }
                                }

                                return Swiper(
                                  itemCount: listOfMedia.length,
                                  itemBuilder: (context, index) {
                                    var media = listOfMedia[index];
                                    if (media['type'] == 'video') {
                                      return Chewie(
                                        controller: ChewieController(
                                          videoPlayerController:
                                              VideoPlayerController.network(
                                                  media['url']),
                                          aspectRatio: 16 / 9,
                                          autoPlay: false,
                                          looping: false,
                                        ),
                                      );
                                    } else {
                                      return Image.network(media['url'],
                                          fit: BoxFit.cover);
                                    }
                                  },
                                  pagination: const SwiperPagination(),
                                  control: const SwiperControl(),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
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