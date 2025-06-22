import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/notice/noticedetailscreen.dart';
import 'package:cooig_firebase/notice/noticeupload.dart';

import 'package:cooig_firebase/notice/starredpostsscreen.dart';
import 'package:cooig_firebase/notice/upcomingnotice.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cooig_firebase/background.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// import 'package:share/share.dart';
//import 'package:cooig_firebase/foundpage.dart';

class Noticeboard extends StatefulWidget {
  final dynamic userId;

  const Noticeboard({super.key, required this.userId, required int index});

  @override
  _NoticeboardState createState() => _NoticeboardState();
}

class _NoticeboardState extends State<Noticeboard> {
  String query = '';
  bool isFoundSelected = true;
  late Future<List<Map<String, dynamic>>> _noticesFuture;
  bool isSocietyRole = false;
  // Get the current user ID from Firebase Authentication
  // final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  get userId async => widget.userId;
  @override
  void initState() {
    super.initState();
    _noticesFuture = _fetchNotices();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      // Fetch the user's role from Firestore using their ID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Replace with your users collection name
          .doc(widget.userId) // User ID passed to the widget
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          isSocietyRole = userData['role'] == 'Society'; // Check the role
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotices() async {
    try {
      final now = DateTime.now().toUtc();

      // Calculate the start of today and the range from 15 days ago
      final startOfToday = DateTime(now.year, now.month, now.day).toUtc();
      final fifteenDaysAgo = startOfToday
          .subtract(const Duration(days: 15)); // Subtract 15 days from today
      final oneMonthFromNow = startOfToday.add(const Duration(days: 30));

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('noticeposts')
          .where('dateTime',
              isGreaterThanOrEqualTo:
                  fifteenDaysAgo) // Fetch posts from 15 days ago
          .where('dateTime',
              isLessThanOrEqualTo:
                  oneMonthFromNow) // To one month in the future
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Handle date field based on its type
        DateTime noticeDate;
        if (data['dateTime'] is Timestamp) {
          noticeDate = (data['dateTime'] as Timestamp).toDate().toUtc();
        } else if (data['dateTime'] is String) {
          noticeDate = DateTime.parse(data['dateTime'] as String).toUtc();
        } else {
          noticeDate = DateTime.now().toUtc(); // Default value
        }

        // Formatting the date for display
        String formattedDate = DateFormat('MMM dd, yyyy').format(noticeDate);

        return {
          'id': doc.id,
          'postedByUserId': data['postedByUserId'],
          'imageUrl': data['imageUrl'] as String? ??
              'https://example.com/default_profile.png',
          'heading': data['heading'] as String? ?? 'No Heading',
          'dateTime': formattedDate,
          'time': data['time'] as String? ?? 'No Time',
          'location': data['location'] as String? ?? 'No Location',
          'postedDate': data['timestamp'] as Timestamp?, // Posting date field
          'postedBy': data['username'] as String? ?? 'Unknown me ',
          'details': data['details'] as String,
          'starredBy': data['starredBy'] as List<dynamic>? ?? [],
          'profilepic': data['profilepic'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching notices: $e');
      return [];
    }
  }

  void _shareNotice(String heading, String imageUrl) {
    // final String shareContent = '$heading\n$imageUrl';
    // Share.share(shareContent);
  }

  Future<void> _deleteNotice(String noticeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('noticeposts')
          .doc(noticeId)
          .delete();
      setState(() {
        _noticesFuture = _fetchNotices();
      });
      Fluttertoast.showToast(
        msg: 'Notice deleted successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print('Error deleting notice: $e');
      Fluttertoast.showToast(
        msg: 'Error deleting notice',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _toggleStar(String postId, List<dynamic>? starredBy) async {
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('noticeposts').doc(postId);

    if (starredBy != null && starredBy.contains(userId)) {
      await postRef.update({
        'starredBy': FieldValue.arrayRemove([userId])
      });
    } else {
      await postRef.update({
        'starredBy': FieldValue.arrayUnion([userId])
      });
    }
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
                    _deleteNotice(noticeId);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _addToGoogleCalendar(String eventDate, String eventName) async {
    final url =
        'https://www.google.com/calendar/render?action=TEMPLATE&text=$eventName&dates=$eventDate/$eventDate';
    // If you want to open the URL, uncomment the following lines
    // if (await canLaunch(url)) {
    //   await launch(url);
    // } else {
    //   throw 'Could not launch $url';
    // }
  }

  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
      colors: const [Color(0XFF9752C5), Color(0xFF000000)],
      radius: 0.0,
      centerAlignment: Alignment.bottomCenter,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text(
            'NoticeBoard',
            style: GoogleFonts.libreBodoni(
              textStyle: const TextStyle(
                color: Color(0XFF9752C5),
                fontSize: 26,
              ),
            ),
          ),
          actions: [
            // IconButton(
            //   icon: const Icon(
            //     Icons.star, // Favorite star icon
            //     color: Colors.white, // You can customize this color
            //   ),
            //   onPressed: () {
            //     // Navigate to StarredPostsScreen when star icon is clicked
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => const StarredPostsScreen()),
            //     );
            //   },
            // ),
          ],
        ),
        backgroundColor: Colors.transparent,
        bottomNavigationBar: Nav(
          userId: widget.userId,
          index: 2,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 40.0, right: 40.0, top: 10.0, bottom: 20.0),
              // child: TextField(
              //   style: const TextStyle(color: Colors.white),
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
                                builder: (context) => Noticeboard(
                                      userId: widget.userId,
                                      index: 2,
                                    )),
                          );
                        },
                        child: Text(
                          'Recent',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 181, 166, 166),
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            decoration: !isFoundSelected
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationColor:
                                const Color.fromARGB(255, 179, 73, 211),
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        width: 20,
                        color: Colors.white,
                        thickness: 1,
                      ),
                      const SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          setState(() {
                            isFoundSelected = true;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => upcomingNotice(
                                      userId: widget.userId,
                                    )),
                          );
                        },
                        child: Text(
                          'Upcoming',
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
                      if (isSocietyRole) // Conditionally render the button
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NoticeUploadPage(
                                        userId: widget.userId,
                                      )),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Notice',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0XFF9752C5),
                            padding: const EdgeInsets.symmetric(
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
                future: _noticesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No notices found.'));
                  }

                  final items = snapshot.data!.where((item) {
                    final heading = item['heading'].toString().toLowerCase();
                    final searchQuery = query.toLowerCase();
                    return heading.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NoticeDetailScreen(notice: item),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading with Event Date and Posting Date
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['heading'] ?? 'No Title Available',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Event Date: ${item['dateTime'] ?? 'No Event Date'}', // Concatenate "Event Date" with the actual date
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(0),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF635A8F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.more_horiz,
                                          color: Colors.white),
                                      onPressed: () {
                                        _showOptionsMenu(context, item['id'],
                                            item['postedByUserId']);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Image Section
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: item['imageUrl'] ?? '',
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.visibility,
                                            color: Color.fromARGB(
                                                255, 96, 96, 96)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item['views'] ?? '0'}',
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  153, 14, 14, 14)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // User Profile and Icons (Avatar + Username + Save + Calendar + Share)
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: item['profilepic'] != null
                                        ? NetworkImage(item['profilepic']!)
                                        : const AssetImage(
                                            'assets/default_avatar.png'),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['postedBy'] ?? 'Unknown User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (item['postedDate'] != null)
                                        Text(
                                          'Posted on: ${DateFormat('yyyy-MM-dd').format(item['postedDate']!.toDate())}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // IconButton(
                                      //   icon: Icon(
                                      //     item['starredBy'].contains(userId)
                                      //         ? Icons.star
                                      //         : Icons.star_border,
                                      //     color: Colors.yellow,
                                      //   ),
                                      //   onPressed: () {
                                      //     _toggleStar(
                                      //         item['id'], item['starredBy']);
                                      //   },
                                      // ),
                                      // IconButton(
                                      //   icon: const Icon(Icons.calendar_today,
                                      //       color: Colors.white),
                                      //   onPressed: () {
                                      //     _addToGoogleCalendar(
                                      //         item['dateTime'] ?? '',
                                      //         item['heading'] ?? '');
                                      //   },
                                      // ),
                                      // IconButton(
                                      //   icon: const Icon(Icons.share,
                                      //       color: Colors.white),
                                      //   onPressed: () {
                                      //     _shareNotice(
                                      //         item['heading'] ?? 'No Title',
                                      //         item['imageUrl'] ?? '');
                                      //   },
                                      // ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
