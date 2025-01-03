import 'package:card_swiper/card_swiper.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/academic_section/branch_page.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/chatmain.dart';
import 'package:cooig_firebase/profile/editprofile.dart';
import 'package:cooig_firebase/notifications.dart';
import 'package:cooig_firebase/post.dart';
import 'package:cooig_firebase/clips.dart'; // Import the ClipsScreen
import 'package:cooig_firebase/search.dart';
<<<<<<< HEAD
//import 'package:cooig_firebase/upload.dart';
=======
import 'package:cooig_firebase/upload.dart';
import 'package:google_fonts/google_fonts.dart';
>>>>>>> 81516a68eb047976e7051450d128bdbc35e373dd
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart'; // Import camera package

class Homepage extends StatefulWidget {
  final String userId;

  Homepage({super.key, required this.userId});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // final List<ChewieController> _chewieControllers = [];
  late Future<DocumentSnapshot> _userDataFuture;
  final PanelController _panelController = PanelController();

  @override
  void initState() {
    super.initState();
    _userDataFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

/*
  @override
  void dispose() {
    // Dispose all ChewieControllers to free up resources
    for (var controller in _chewieControllers) {
      controller.dispose();
    }
    super.dispose();
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
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
                  )),
              const SizedBox(width: 1),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MySearchPage()),
                  );
                },
                icon: const Icon(Icons.search, color: Colors.white),
              ),
              const SizedBox(width: 50),
              Text(
                'Cooig',
                style: GoogleFonts.libreBodoni(
                  textStyle: TextStyle(
                    color: Color(0XFF9752C5),
                    fontSize: 30,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black,
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
                    ));
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
                          )),
                );
              },
              icon: const Badge(
                backgroundColor: Color(0xFF635A8F),
                textColor: Colors.white,
                label: Text('5'),
                child:
                    Icon(Icons.messenger_outline_rounded, color: Colors.white),
              ),
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Pass userId to the NavigationDrawer
        bottomNavigationBar: Nav(userId: widget.userId),
        body: SingleChildScrollView(
            child: IntrinsicHeight(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: InkWell(
                splashColor: Colors.blue.withOpacity(0.3),
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PostScreen(userId: widget.userId)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 35.0),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  width: 320,
                  height: 90,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: _userDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return const Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 5.0),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                    'https://via.placeholder.com/150'),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "What's on your head?",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.1,
                              ),
                            ),
                          ],
                        );
                      } else {
                        var data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        String? imageUrl = data['image'] as String?;

                                return Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: CircleAvatar(
                                        radius: 25,
                                        backgroundImage: NetworkImage(imageUrl ??
                                            'https://via.placeholder.com/150'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "What's on your head?",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'Arial',
                                        fontWeight: FontWeight.w400,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    // const Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    //   child: Text(
                    //     "Clips",
                    //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    //   ),
                    // ),
                    // const SizedBox(height: 10.0),
                    // SingleChildScrollView(
                    //   scrollDirection: Axis.horizontal,
                    //   child: Row(
                    //     children: [
                    //       // Inside the HomePage build method
                    //       Container(
                    //         height: 70.0,
                    //         width: 56.0,
                    //         alignment: Alignment.center,
                    //         margin: const EdgeInsets.only(left: 24.0),
                    //         decoration: const BoxDecoration(
                    //           shape: BoxShape.circle,
                    //           color: Colors.grey,
                    //           boxShadow: [
                    //             BoxShadow(
                    //               blurRadius: 12.0,
                    //               offset: Offset(0, 4),
                    //               color: Color.fromARGB(255, 225, 0, 172),
                    //             ),
                    //           ],
                    //         ),
                    //         child: IconButton(
                    //           onPressed: () {
                    //             // Navigate to ClipsScreen when add button is clicked
                    //             Navigator.push(
                    //               context,
                    //               MaterialPageRoute(
                    //                 builder: (context) => const ClipsScreen(
                    //                   cameraLensDirection: CameraLensDirection.front,
                    //                 ),
                    //               ),
                    //             );
                    //           },
                    //           icon: const Icon(Icons.add),
                    //         ),
                    //       ),

            //       ...List.generate(
            //         20,
            //         (index) => Container(
            //           height: 56.0,
            //           width: 56.0,
            //           margin: EdgeInsets.only(
            //             left: 30.0,
            //             right: index == 19 ? 30.0 : 0.0,
            //           ),
            //           alignment: Alignment.center,
            //           decoration: BoxDecoration(
            //             shape: BoxShape.circle,
            //             border: Border.all(
            //                 width: 2.0, color: Colors.purpleAccent),
            //             image: const DecorationImage(
            //               image:
            //                   NetworkImage('https://via.placeholder.com/150'),
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 50),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 300,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius:
                    BorderRadius.circular(20), // Adjust the value as needed
              ),
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

                                  const SizedBox(height: 10),

                                  // Posts or Media Content
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection(widget.userId)
                                          .where('userID',
                                              isEqualTo: widget.userId)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          return Center(
                                              child: Text(
                                                  'Error: ${snapshot.error}'));
                                        } else if (!snapshot.hasData ||
                                            snapshot.data!.docs.isEmpty) {
                                          return const Center(
                                              child: Text('No Posts found'));
                                        }

                                        // Create a local list to hold media
                                        List<Map<String, dynamic>> listOfMedia =
                                            [];
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

                                        Widget buildMediaUI(
                                            List<Map<String, dynamic>>
                                                mediaList) {
                                          return GridView.builder(
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  3, // Number of items per row
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                            ),
                                            itemCount: mediaList.length,
                                            itemBuilder: (context, index) {
                                              var media = mediaList[index];
                                              return Material(
                                                elevation:
                                                    5, // Add elevation for a modern card-like appearance
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                clipBehavior: Clip
                                                    .antiAlias, // Ensure content respects rounded edges
                                                child: Stack(
                                                  children: [
                                                    // Media content
                                                    media['type'] == 'image'
                                                        ? Image.network(
                                                            media['url'],
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                          )
                                                        : Container(
                                                            color:
                                                                Colors.black26,
                                                            child: const Center(
                                                              child: Icon(
                                                                Icons
                                                                    .play_circle_fill,
                                                                size: 50,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                    // Overlay for rounded edges
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                          border: Border.all(
                                                              color:
                                                                  Colors.white,
                                                              width: 3),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        }

                                        return Swiper(
                                          itemCount: listOfMedia.length,
                                          itemBuilder: (context, index) {
                                            var media = listOfMedia[index];
                                            return Material(
                                              elevation: 5,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              clipBehavior: Clip.antiAlias,
                                              child: media['type'] == 'video'
                                                  ? Chewie(
                                                      controller:
                                                          ChewieController(
                                                        videoPlayerController:
                                                            VideoPlayerController
                                                                .network(media[
                                                                    'url']),
                                                        aspectRatio: 16 / 9,
                                                        autoPlay: false,
                                                        looping: false,
                                                      ),
                                                    )
                                                  : ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      child: Image.network(
                                                        media['url'],
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                            );
                                          },
                                          pagination: const SwiperPagination(),
                                          control: const SwiperControl(),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // User Profile and Icons (Avatar + Username + Save + Calendar + Share)

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundImage: profileImageUrl != null &&
                                        profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : const AssetImage(
                                            'assets/default_avatar.png')
                                        as ImageProvider,
                                radius: 22,
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
                                  icon: const Icon(
                                      Icons.favorite_border_outlined,
                                      color: Colors.white),
                                  onPressed: () {}),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline,
                                    color: Colors.white),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.near_me,
                                    color: Colors.white),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  }),
            )
          ]),
        )));
  }
}
