import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/bar.dart';
import 'package:cooig_firebase/individual_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cooig_firebase/shop/rentupload.dart'; // Import your Rent upload screen
import 'package:cooig_firebase/shop/sellitemupload.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart'; // For zoomable image
import 'package:cooig_firebase/background.dart'; // Assuming background.dart contains the RadialGradientBackground widget
// Import your Sell upload screen

class Shopscreen extends StatefulWidget {
  final String userId; // Ensure userId is passed correctly

  const Shopscreen({super.key, required this.userId, required int index});

  @override
  State<Shopscreen> createState() => _ShopscreenState();
}

class _ShopscreenState extends State<Shopscreen> {
  String query = '';
  int _selectedIndex = 0; // 0 for Sell/Buy, 1 for Rent

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0XFF9752C5), Color(0xFF000000)],
          radius: 0.0,
          center: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: Nav(
          userId: widget.userId,
          index: 1,
        ),
        body: Column(
          children: [
            // Sell/Buy and Rent Tabs
            Padding(
              padding: const EdgeInsets.only(top: 65, bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sell/Buy Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Sell/Buy',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _selectedIndex == 0
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                        if (_selectedIndex == 0)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            height: 2,
                            width: 80,
                            color: Colors.purple,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Rent Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Rent',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _selectedIndex == 1
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                        if (_selectedIndex == 1)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            height: 2,
                            width: 80,
                            color: Colors.purple,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Item List
            Expanded(
              child: _selectedIndex == 0
                  ? _buildItemList('sellposts') // Sell/Buy items
                  : _buildItemList('rentposts'), // Rent items
            ),
          ],
        ),
        // Floating Action Button for Upload
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to the appropriate upload page
            if (_selectedIndex == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellItemScreen(
                    userId: widget.userId, // Pass userId to SellItemScreen
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Rentupload(
                    userId: widget.userId, // Pass userId to Rentupload
                  ),
                ),
              );
            }
          },
          backgroundColor: const Color(0XFF9752C5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedIndex == 0 ? Icons.sell : Icons.sell_outlined,
                size: 24,
              ), // Icon
              const SizedBox(height: 4), // Space between icon and text
              Text(
                _selectedIndex == 0 ? 'Sell' : 'Rent', // Text
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the item list
  Widget _buildItemList(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('An error occurred'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No items found'));
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final userIdFromDoc = doc['postedByUserId'] ??
                'unknown'; // Get userId from the document
            final isCurrentUserPost = userIdFromDoc ==
                widget.userId; // Check if it's the current user's post

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailsPage(
                      itemName: doc['itemName'],
                      price: doc['price'],
                      details: doc['details'],
                      imageUrl: doc['imageUrl'],
                    ),
                  ),
                );
              },
              child: Padding(
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
                  child: Row(
                    children: [
                      // Item Image
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(15)),
                        child: Stack(
                          children: [
                            Image.network(
                              doc['imageUrl'],
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundImage: NetworkImage(
                                      doc['profilepic'] as String? ?? '',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    doc['username'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color.fromARGB(255, 118, 113, 113),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Item Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    doc['itemName'],
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  if (isCurrentUserPost)
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Confirm Delete"),
                                              content: Text(
                                                  "Are you sure you want to delete this post?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog
                                                  },
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    // Delete the post
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            collectionName)
                                                        .doc(doc.id)
                                                        .delete();
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog
                                                  },
                                                  child: Text("Delete",
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
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
                                    fontSize: 14, color: Colors.grey[700]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              // Buy/Rent Button
                              ElevatedButton(
                                onPressed: () {
                                  // Handle buy/rent action
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => IndividualChatScreen(
                                            currentUserId: widget.userId,
                                            chatUserId: doc['postedByUserId'],
                                            fullName:
                                                doc['username'] ?? 'Unknown',
                                            image: doc["profilepic"] ??
                                                'https://via.placeholder.com/150',
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 74, 72, 72))),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0XFF9752C5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  _selectedIndex == 0 ? 'BUY' : 'RENT',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Item Details Page

class ItemDetailsPage extends StatelessWidget {
  final String itemName;
  final String price;
  final String details;
  final String imageUrl;

  const ItemDetailsPage({
    required this.itemName,
    required this.price,
    required this.details,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // Transparent AppBar with back button
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0XFF9752C5)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Colors.black,

        // Radial Gradient Background
        body: RadialGradientBackground(
          colors: const [Color(0XFF9752C5), Color(0xFF000000)],
          radius: 0.0,
          centerAlignment: Alignment.bottomCenter,
          child: Center(
            child: Container(
              width: 360,
              height: 670,
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(20.86),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFCACACA),
                    blurRadius: 9.24,
                    offset: Offset(2.77, 2.77),
                  ),
                  BoxShadow(
                    color: Color(0xFFC9C9C9),
                    blurRadius: 9.24,
                    offset: Offset(-2.77, -2.77),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Image Section
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewScreen(imageUrl: imageUrl),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 335,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Name
                          Text(
                            itemName,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Row(
                            children: [
                              const Icon(Icons.currency_rupee,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Price: ₹$price',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Details Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.description,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Details',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  details,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Zoomable full-screen image viewer
class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF9752C5),
        title: const Text('Image'),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
      ),
    );
  }
}
