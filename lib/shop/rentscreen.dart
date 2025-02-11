import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cooig_firebase/shop/shopscreen.dart';
import 'package:cooig_firebase/shop/rentupload.dart';
import 'package:flutter/material.dart';
import 'package:cooig_firebase/appbar.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:path/path.dart';

class rentscreen extends StatefulWidget {
  final dynamic userId;

  const rentscreen({super.key, required this.userId});

  @override
  State<rentscreen> createState() => _rentscreenState();
}

class _rentscreenState extends State<rentscreen> {
  String query = '';
  bool isFoundSelected = true;
  String selectedCategory = 'All';
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(0XFF9752C5),
            Color(0xFF000000),
          ],
          radius: 0.8,
          center: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Cooig',
          textSize: 30.0,
        ),
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 40.0, right: 40.0, top: 20.0, bottom: 20.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
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
                                builder: (context) => Shopscreen(
                                      userId: widget.userId,
                                      index: 1,
                                    )), // Ensure this route exists
                          );
                        },
                        child: Text(
                          'Sell',
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
                                builder: (context) => rentscreen(
                                      userId: widget.userId,
                                    )),
                          );
                        },
                        child: Text(
                          'Rent',
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
                                builder: (context) => Rentupload(
                                      userId: widget.userId,
                                    )), // Ensure this route exists
                          );
                        },
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text(
                          'Rent',
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
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery().snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('An error occurred'));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data?.docs.isEmpty == true) {
                    return const Center(child: Text('No items found'));
                  }

                  final documents = snapshot.data!.docs;

                  final filteredPosts = documents.where((doc) {
                    final title = doc['itemName'] as String;
                    return title.contains(query);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final doc = filteredPosts[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(15)),
                                    child: Image.network(
                                      doc['imageUrl'],
                                      width: MediaQuery.of(context).size.width *
                                          0.4, // 40% of the width
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  doc['itemName'],
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black),
                                                ),
                                                SizedBox(
                                                  width: 100,
                                                ),
                                                PopupMenuButton<String>(
                                                  onSelected: (value) {
                                                    if (value == 'delete') {
                                                      _deletePost(doc.id);
                                                    }
                                                  },
                                                  itemBuilder: (context) {
                                                    // Only show delete option if the post belongs to the current user
                                                    return [
                                                      if (doc['postedByUserId'] ==
                                                          widget.userId)
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Text('Delete'),
                                                        ),
                                                    ];
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              '₹${doc['price']}',
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              doc['details'],
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700]),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 90.0,
                                                            right: 0.0,
                                                            top: 0.0,
                                                            bottom: 1.0),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        // Navigate to message section with seller
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0XFF9752C5),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                      ),
                                                      child: const Text('Rent',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ]),
                                    ),
                                  )
                                ],
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: NetworkImage(
                                        doc['profilepic'] as String? ??
                                            '', // Replace with dynamic profile image URL
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      doc['username'], // Replace with dynamic username
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color.fromARGB(
                                              255, 127, 124, 124)),
                                    ),
                                  ],
                                ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // _showFilterDialog();
          },
          backgroundColor: const Color(0XFF9752C5),
          child: const Icon(Icons.filter_list),
        ),
      ),
    );
  }

  Query _buildQuery() {
    final collection = FirebaseFirestore.instance.collection('rentposts');
    Query query = collection;

    if (selectedCategory != 'All') {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    if (selectedDate != null) {
      final startOfDay =
          DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      final endOfDay = DateTime(selectedDate!.year, selectedDate!.month,
          selectedDate!.day, 23, 59, 59);
      query = query.where('date',
          isGreaterThanOrEqualTo: startOfDay, isLessThanOrEqualTo: endOfDay);
    }

    return query;
  }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Filter'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DropdownButtonFormField<String>(
//                 value: selectedCategory,
//                 items: ['All', 'Electronics', 'Clothing', 'Books', 'Other']
//                     .map((category) => DropdownMenuItem<String>(
//                           value: category,
//                           child: Text(category),
//                         ))
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     selectedCategory = value!;
//                   });
//                 },
//               ),
//               TextButton(
//                 onPressed: () async {
//                   final pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: DateTime.now(),
//                     firstDate: DateTime(2020),
//                     lastDate: DateTime(2030),
//                   );
//                   setState(() {
//                     selectedDate = pickedDate;
//                   });
//                 },
//                 child: Text(selectedDate == null
//                     ? 'Select Date'
//                     : selectedDate!.toString()),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Apply'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('rentposts')
          .doc(postId)
          .delete();
      ScaffoldMessenger.of(Context as BuildContext).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }
}
