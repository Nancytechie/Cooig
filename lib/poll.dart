import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/pollpage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class MyPollPage extends StatefulWidget {
  final String userId;
  const MyPollPage({super.key, required this.userId});

  @override
  State<MyPollPage> createState() => PollPage();
}

class PollPage extends State<MyPollPage> {
  final TextEditingController _textController = TextEditingController();
  List<String> pollOptions = ["", ""];
  bool isTextOption = true;
  List<File?> pollImages = List.generate(5, (index) => null);
  final picker = ImagePicker();
  Future<void> getImageGallery(int index) async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    setState(() {
      if (pickedFile != null) {
        pollImages[index] = File(pickedFile.path);
      } else {
        return;
      }
    });
  }

  Future<void> _onPostButtonClick() async {
    String question = _textController.text;
    List<String> options = [];
    List<String> imageUrls = [];

    // Upload images to Firebase Storage and get URLs
    for (int i = 0; i < pollOptions.length; i++) {
      if (isTextOption) {
        options.add(pollOptions[i]);
      } else if (pollImages[i] != null) {
        String fileName = basename(pollImages[i]!.path);
        Reference firebaseStorageRef =
            FirebaseStorage.instance.ref().child('pollImages/$fileName');
        UploadTask uploadTask = firebaseStorageRef.putFile(pollImages[i]!);
        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }
    Map<String, dynamic> pollData = {
      'question': question,
      'userID': widget.userId,
      'options': isTextOption ? options : null,
      'imageUrls': !isTextOption ? imageUrls : null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Save to Firestore
    await FirebaseFirestore.instance.collection('polls').add(pollData);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _textController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Ask your question .....",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.text_fields),
          color: Colors.white,
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.photo_size_select_actual_outlined),
          color: Colors.white,
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.video_library_outlined),
          color: Colors.white,
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.gif_box_outlined),
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildPollSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Poll Options",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ToggleButtons(
                isSelected: [isTextOption, !isTextOption],
                onPressed: (index) {
                  setState(() {
                    isTextOption = index == 0; // Toggle between text and image
                  });
                },
                selectedBorderColor:
                    Colors.purple, // Border color of the selected button
                selectedColor:
                    Colors.purple, // Icon color of the selected button
                fillColor: Colors.purple.withOpacity(0.2),
                children: const [
                  Icon(Icons.text_fields, color: Colors.white), // Text icon
                  Icon(Icons.image, color: Colors.white), // Image icon
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true, // Use shrinkWrap to avoid scrolling issues
            itemCount: pollOptions.length,

            itemBuilder: (context, index) {
              return Row(
                children: [
                  Radio(
                    value: index,
                    groupValue: null,
                    onChanged: (value) {
                      // Handle radio selection if needed
                    },
                  ),
                  Expanded(
                    child: isTextOption
                        ? TextField(
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              pollOptions[index] = value;
                            },
                            decoration: InputDecoration(
                              hintText: "Option ${index + 1}",
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              getImageGallery(index);
                            },
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: pollImages[index] != null
                                  ? Image.file(
                                      pollImages[index]!.absolute,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: pollOptions[index].isEmpty
                                          ? const Text("Tap to select image")
                                          : Image.network(pollOptions[
                                              index]), // Display selected image
                                    ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                pollOptions.add(""); // Add a new empty option
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            const Text('Ask a Question', style: TextStyle(color: Colors.white)),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_sharp),
            color: Colors.white),
        actions: [
          ElevatedButton(
            onPressed: () {
              _onPostButtonClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PollScreen(
                        userId: 'gklD4of1KLed1Y0lWmA9hRhW6cp1')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF635A8F), // Background color
              shape: const StadiumBorder(), // Pill-shaped button
            ),
            child: const Text('Post', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          // Add some spacing between the button and the right edge
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(),
              const SizedBox(height: 20),
              _buildDescriptionRow(),
              const SizedBox(height: 20),
              _buildPollSection(),
            ],
          ),
        ),
      ),
    );
  }
}
