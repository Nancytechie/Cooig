import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:cooig_firebase/appbar.dart';

import 'package:cooig_firebase/background.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/lostandfound/foundpage.dart';
import 'package:cooig_firebase/lostandfound/lostpostscreen.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

// import 'package:share/
class Lostpage extends StatefulWidget {
  final String userId;
  const Lostpage({super.key, required this.userId, required int index});

  @override
  _LostpageState createState() => _LostpageState();
}

class _LostpageState extends State<Lostpage> {
  String query = '';

  String selectedCategory = 'All';
  bool isFoundSelected = true;
  int _currentIndex = 0;

  late Future<List<Map<String, dynamic>>> _foundItemsFuture;

  @override
  void initState() {
    super.initState();
    _foundItemsFuture = _fetchFoundItems();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFoundItems() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('lostpost').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'postedByUserId': data['postedByUserId'],
          'image': data['image'] ?? '',
          'userProfileImage': data['profilepic'] ?? '',
          'username': data['username'] ?? 'Unknown User',
          'title': data['title'] ?? 'No Title',
          'description': data['description'] ?? 'No Description',
          'dateTime': data['dateTime'] != null
              ? (data['dateTime'] as Timestamp)
                  .toDate()
                  .toLocal()
                  .toString()
                  .split(' ')[0] // Extract only the date part
              : 'No Date',
          'location': data['location'] ?? 'No Location',
        };
      }).toList();
    } catch (e) {
      print('Error fetching found items: $e');
      return [];
    }
  }

/*
  void _sharePost(String title, String description, String imageUrl) {
    final String shareContent = '$title\n$description\n$imageUrl';
    Share.share(shareContent);
  }
*/
  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('lostpost')
          .doc(postId)
          .delete();
      setState(() {
        _foundItemsFuture = _fetchFoundItems();
      });
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex;
    return RadialGradientBackground(
      colors: [Color(0XFF9752C5), Color(0xFF000000)],
      radius: 0.0,
      centerAlignment: Alignment.bottomCenter,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SizedBox(
              height: 30,
              child: Center(
                child: AnimatedTextKit(
                  animatedTexts: [
                    FadeAnimatedText(
                      'Lost where?',
                      textStyle: GoogleFonts.ebGaramond(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 158, 162, 163),
                      ),
                    ),
                    FadeAnimatedText(
                      'Find here!',
                      textStyle: GoogleFonts.ebGaramond(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 158, 162, 163),
                      ),
                    ),
                  ],
                  repeatForever: true,
                  isRepeatingAnimation: true,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              // child: TextField(
              //   style: TextStyle(color: Colors.white),
              //   decoration: const InputDecoration(
              //     labelText: 'Search',
              //     enabledBorder: OutlineInputBorder(
              //       borderSide:
              //           BorderSide(color: Color.fromARGB(255, 96, 39, 146)),
              //       borderRadius: BorderRadius.horizontal(
              //         left: Radius.circular(27),
              //         right: Radius.circular(27),
              //       ),
              //     ),
              //   ),
              //   onChanged: (value) {
              //     setState(() {
              //       query = value;
              //     });
              //   },
              // ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            isFoundSelected = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Lostpage(
                                      userId: widget.userId,
                                      index: 3,
                                    )),
                          );
                        },
                        child: Text(
                          'Lost',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 181, 166, 166),
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            decoration: !isFoundSelected
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationColor: Color.fromARGB(255, 179, 73, 211),
                          ),
                        ),
                      ),
                      VerticalDivider(
                        width: 20,
                        color: Colors.white,
                        thickness: 1,
                      ),
                      SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          setState(() {
                            isFoundSelected = true;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Foundpage(
                                      userId: widget.userId,
                                    )),
                          );
                        },
                        child: Text(
                          'Found',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 181, 166, 166),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            decoration: isFoundSelected
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PostScreen(
                                      userId: widget.userId,
                                    )),
                          );
                        },
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        label: Text(
                          'Upload',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0XFF9752C5),
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _foundItemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No items found'));
                  }

                  final filteredItems = snapshot.data!.where((item) {
                    final matchesQuery = (item['title'] as String)
                        .toLowerCase()
                        .contains(query.toLowerCase());
                    final matchesCategory = selectedCategory == 'All' ||
                        (item['category'] as String).contains(selectedCategory);
                    return matchesQuery && matchesCategory;
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      var item = filteredItems[index];
                      return Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.all(8),
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    image: DecorationImage(
                                      image: NetworkImage(item['image']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.more_vert,
                                        color: Colors.white),
                                    onPressed: () {
                                      _showOptionsMenu(context, item['id'],
                                          item['postedByUserId']);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(item['userProfileImage']),
                                    radius: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['username'] as String? ??
                                              'Unknown User',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          item['title'] as String? ??
                                              'No Title',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          item['description'] as String? ??
                                              'No Description',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Lost on: ${item['dateTime'] ?? 'No Date'}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Location where lost: ${item['location'] as String? ?? 'No Location'}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 16.0, bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // IconButton(
                                  //   icon: Icon(Icons.chat_bubble_outline,
                                  //       color: Colors.white),
                                  //   onPressed: () {
                                  //     _showCommentSection(item['id']);
                                  //   },
                                  // ),
                                  // IconButton(
                                  //   icon: Icon(Icons.near_me,
                                  //       color: Colors.white),
                                  //   onPressed: () {
                                  //     //_sharePost(item['title'],
                                  //     // item['description'], item['image']);
                                  //   },
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Nav(
          userId: widget.userId,
          index: 3,
        ),
      ),
    );
  }

  void _showOptionsMenu(
      BuildContext context, String noticeId, String postedByUserId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (postedByUserId ==
                  widget
                      .userId) // Only show delete option if the current user is the poster
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost(noticeId);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deletePost(postId); // Delete the post
              },
            ),
          ],
        );
      },
    );
  }
}

class _showCommentSection {
  _showCommentSection(item);
}
