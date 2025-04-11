import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/profile/otherprofile.dart';
import 'package:cooig_firebase/profile/profi.dart';
import 'package:cooig_firebase/society/societyprofile/othersociety.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MySearchPage extends StatefulWidget {
  dynamic userId;
  MySearchPage({super.key, required this.userId});

  @override
  State<MySearchPage> createState() => _MySearchPageState();
}

class _MySearchPageState extends State<MySearchPage> {
  final TextEditingController _searchController =
      TextEditingController(); // Text editing controller for search bar
  var searchName = "";

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Cooig',
          style: GoogleFonts.libreBodoni(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 23, // White text for contrast
            ),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFF635A8F),
                border: Border.all(
                  color: const Color(0xFF635A8F),
                  width: 1.4,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: ' Search',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchName = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('full_name')
              .startAt([searchName]).endAt(["$searchName\uf8ff"]).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // Show error message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Something went wrong'),
                    backgroundColor: Colors.red,
                  ),
                );
              });

              return Container(); // Return an empty container as the UI.
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: data['profilepic'] != null &&
                              data['profilepic'].isNotEmpty
                          ? NetworkImage(data['profilepic'])
                          : const NetworkImage(
                              'https://via.placeholder.com/150'),
                    ),
                    title: Text(
                      data['full_name'],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    // Navigate to ProfilePage on tap
                    // jiya yeh mt htana
                    onTap: () {
                      if (data['role'] == "Student") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Otherprofile(
                              otheruserid: data.id, userId: widget.userId,

                              // Pass the user ID to ProfilePage
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Othersociety(
                              otheruserid: data.id,
                              userId: widget
                                  .userId, // Pass the user ID to ProfilePage
                            ),
                          ),
                        );
                      }
                    },
                  );
                });
          }),
    );
  }
}
