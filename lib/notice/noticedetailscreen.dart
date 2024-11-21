import 'package:cooig_firebase/background.dart'; // Assuming background.dart contains the RadialGradientBackground widget
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart'; // For zoomable image

class NoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // App bar with a back button but no text
        appBar: AppBar(
          backgroundColor: Colors.black, // Make the app bar transparent
          elevation: 0, // Remove shadow
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0XFF9752C5)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        // Radial Gradient background
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
              // Making the entire content scrollable if necessary
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top half of the screen contains the full image
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewScreen(
                                imageUrl: notice['imageUrl'] ?? ''),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: notice['imageUrl'] ??
                            'https://example.com/default_image.png',
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

                    // Bottom half of the screen contains the notice details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice['heading'] ?? 'No Title',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.date_range, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Event Date: ${notice['dateTime'] ?? 'No Date'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Time: ${notice['time'] ?? 'No Time'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Location: ${notice['location'] ?? 'No Location'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Displaying notice details in a large container with heading and icon
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
                                        color:
                                            Colors.white), // Icon for details
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
                                  notice['details'] ??
                                      'No additional details available.',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Posted By: ${notice['postedBy'] ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          if (notice['postedDate'] != null)
                            Text(
                              'Posted on: ${DateFormat('yyyy-MM-dd').format(notice['postedDate'].toDate())}',
                              style: const TextStyle(color: Colors.grey),
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
