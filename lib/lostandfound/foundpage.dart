import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/background.dart';
import 'package:cooig_firebase/lostandfound/foundupload.dart';
import 'package:cooig_firebase/lostandfound/lostpage.dart';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
// import 'package:share/share.dart';

class Foundpage extends StatefulWidget {
  const Foundpage({super.key});

  @override
  _FoundpageState createState() => _FoundpageState();
}

class _FoundpageState extends State<Foundpage> {
  String query = '';
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
          await FirebaseFirestore.instance.collection('foundposts').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id, // Add the document ID for deletion purposes
          'images': (data['images'] as List<dynamic>?)?.isNotEmpty == true
              ? List<String>.from(data['images'] as List<dynamic>)
              : [
                  'https://example.com/image_unavailable.png'
                ], // URL of the "image unavailable" placeholder
          'userProfileImage': data['userProfileImage'] as String? ??
              'https://example.com/default_profile.png',
          'username': data['username'] as String? ?? 'Unknown User',
          'title': data['title'] as String? ?? 'No Title',
          'description': data['description'] as String? ?? 'No Description',
          'date': data['dateTime'] != null
              ? (data['dateTime'] as Timestamp)
                  .toDate()
                  .toLocal()
                  .toString()
                  .split(' ')[0] // Extract only the date part
              : 'No Date',
          'location': data['location'] as String? ?? 'No Location',
          'postedBy': data['postedBy'] as String? ??
              'Unknown', // Add the user ID who posted the item
        };
      }).toList();
    } catch (e) {
      print('Error fetching found items: $e');
      return [];
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('foundposts')
          .doc(postId)
          .delete();
      setState(() {
        _foundItemsFuture = _fetchFoundItems(); // Refresh the list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post')),
      );
    }
  }

  void _showOptionsMenu(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                onTap: () {
                  Navigator.pop(context); // Close the options menu
                  _deletePost(postId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
        colors: [Color(0XFF9752C5), Color(0xFF000000)],
        radius: 0.0,
        centerAlignment: Alignment.bottomCenter,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: Colors.black,
              title: Text(
                'Cooig',
                style: GoogleFonts.libreBodoni(
                  textStyle: TextStyle(
                    color: Color(0XFF9752C5),
                    fontSize: 26,
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                SizedBox(
                  height: 40, // Adjust this height as per your design
                  child: Center(
                    child: AnimatedTextKit(
                      animatedTexts: [
                        FadeAnimatedText(
                          'Found where?',
                          textStyle: GoogleFonts.ebGaramond(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 158, 162, 163),
                          ),
                        ),
                        FadeAnimatedText(
                          'Write here!',
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
                  padding: const EdgeInsets.only(
                      left: 40.0, right: 40.0, top: 20.0, bottom: 20.0),
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 96, 39, 146)),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(27),
                          right: Radius.circular(27),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        query = value;
                      });
                    },
                  ),
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
                                    builder: (context) =>
                                        Lostpage()), // Ensure this route exists
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
                                decorationColor:
                                    Color.fromARGB(255, 179, 73, 211),
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
                                    builder: (context) => Foundpage()),
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
                                    builder: (context) =>
                                        FoundItemScreen()), // Ensure this route exists
                              );
                            },
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            label: Text(
                              'Upload',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Color(0XFF9752C5),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
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
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No items found.'));
                      }

                      final items = snapshot.data!;

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                  30), // Circular border radius
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(30)),
                                      child: Image.network(
                                        item['images'][0],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 150,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.more_vert,
                                            color: Colors.white),
                                        onPressed: () {
                                          _showOptionsMenu(context, item['id']);
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
                                        backgroundImage: NetworkImage(
                                            item['userProfileImage']),
                                        radius: 20, // Circular profile image
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
                                              ),
                                            ),
                                            Text(
                                              item['description'] as String? ??
                                                  'No Description',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            Text(
                                              'Date when Found: ${item['date'] as String? ?? 'No Date'}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            Text(
                                              'Location where Found: ${item['location'] as String? ?? 'No Location'}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.chat_bubble_outline,
                                          color: Colors.white),
                                      onPressed: () {
                                        // Navigate to comments screen
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(builder: (context) => CommentsScreen(postId: item['id'])),
                                        // );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.near_me,
                                          color: Colors.white),
                                      onPressed: () {},
                                    ),
                                  ],
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
            )));
  }
}
