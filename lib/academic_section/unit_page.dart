import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/academic_section/material_upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure this is imported

class UnitPage extends StatefulWidget {
  final String branch;
  final int year;
  final String subject;
  final String unitName;

  const UnitPage({
    super.key,
    required this.branch,
    required this.year,
    required this.subject,
    required this.unitName,
  });

  @override
  _UnitPageState createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  // Track like state for each note by its ID
  Map<String, bool> likedNotes = {};

  Future<void> _handleLike(String noteId, String userId) async {
    final String yearString = widget.year.toString();
    DocumentReference noteRef = FirebaseFirestore.instance
        .collection('branches')
        .doc(widget.branch)
        .collection('years')
        .doc(yearString)
        .collection('subjects')
        .doc(widget.subject)
        .collection('units')
        .doc(widget.unitName)
        .collection('notes')
        .doc(noteId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot noteSnapshot = await transaction.get(noteRef);
      if (noteSnapshot.exists) {
        int currentLikes = noteSnapshot['likes'] ?? 0;
        if (likedNotes[noteId] ?? false) {
          transaction.update(noteRef, {'likes': currentLikes + 1});
        } else {
          transaction.update(noteRef, {'likes': currentLikes - 1});
        }
      }
    });

    // Create a notification for the like
    if (!(likedNotes[noteId] ?? false)) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'like notes', // Ensure the type is 'like notes'
        'fromUserID': FirebaseAuth.instance.currentUser!.uid,
        'toUserID': userId,
        'noteId': noteId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      likedNotes[noteId] = !(likedNotes[noteId] ?? false);
    });
  }

  Future<void> _openLink(BuildContext context, String url) async {
    if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme == true) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Handle the error where the URL can't be launched
          throw 'Could not open the link';
        }
      } catch (e) {
        // Handle any exception thrown during the launch
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    } else {
      // Handle invalid URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String yearString = widget.year.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes for ${widget.unitName}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Row(
              children: [
                Icon(Icons.add, color: const Color.fromARGB(255, 146, 226, 85)),
                SizedBox(width: 4),
                Text(
                  'Add Yours',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaterialUpload(
                    branch: widget.branch,
                    year: widget.year,
                    subject: widget.subject,
                    unitName: widget.unitName,
                  ),
                ),
              ).then((_) {
                (context as Element).markNeedsBuild();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('branches')
            .doc(widget.branch)
            .collection('years')
            .doc(yearString)
            .collection('subjects')
            .doc(widget.subject)
            .collection('units')
            .doc(widget.unitName)
            .collection('notes')
            .orderBy('timestamp', descending: true)
            .orderBy('likes', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error fetching data: ${snapshot.error}");
            return Center(
              child: Text(
                'Error fetching data: ${snapshot.error}',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notes available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String noteId = doc.id;
              String notesLink = data['notesLink'] ?? '';
              String userId = data['userId'] ?? '';

              return GestureDetector(
                onTap: () {
                  _openLink(context, notesLink);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomRight,
                      radius: 1.5,
                      colors: [
                        Color(0XFF9752C5),
                        const Color.fromARGB(255, 132, 92, 241),
                      ],
                      stops: [2.0, 3.0],
                    ),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              data['userProfilePic'] ??
                                  'https://example.com/defaultProfilePic.jpg',
                            ),
                            radius: 20,
                          ),
                          const SizedBox(width: 8.0),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Untitled',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'By ${data['userName'] ?? 'Unknown'}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.favorite,
                                  color: likedNotes[noteId] ?? false
                                      ? Colors.red
                                      : Colors.white,
                                ),
                                onPressed: () => _handleLike(noteId, userId),
                              ),
                              Text(
                                '${data['likes'] ?? 0} Likes',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10.0),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.near_me, color: Colors.white),
                                onPressed: () => _handleLike(noteId, userId),
                              ),
                              // Text(
                              //   'Share',
                              //   style: TextStyle(
                              //       fontSize: 13, color: Colors.white70),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }
}
