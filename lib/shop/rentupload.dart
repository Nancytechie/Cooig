import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
// For image cropping
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:cooig_firebase/background.dart';
import 'package:path/path.dart';

class Rentupload extends StatefulWidget {
  final String userId;
  const Rentupload({super.key, required this.userId});

  @override
  _RentuploadState createState() => _RentuploadState();
}

class _RentuploadState extends State<Rentupload> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _contactDetailsController =
      TextEditingController();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        Fluttertoast.showToast(msg: "Image successfully chosen");
      }
    } catch (e) {
      print('Error picking image: $e');
      Fluttertoast.showToast(msg: "Error picking image");
    }
  }

  Future<void> _uploadPost() async {
    if (_image == null ||
        _itemNameController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _detailsController.text.isEmpty ||
        _contactDetailsController.text.isEmpty) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields and select an image.')),
      );
      return;
    }

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('rentposts').child(fileName);
      final uploadTask = storageRef.putFile(_image!);

      uploadTask.snapshotEvents.listen((event) {
        switch (event.state) {
          case TaskState.running:
            print(
                'Upload is ${event.bytesTransferred / event.totalBytes * 100}% complete');
            break;
          case TaskState.success:
            print('Upload successful');
            break;
          case TaskState.canceled:
            print('Upload canceled');
            break;
          case TaskState.error:
            print('Upload error');
            break;
          case TaskState.paused:
            break;
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('rentposts').add({
        'itemName': _itemNameController.text,
        'category': _categoryController.text,
        'price': _priceController.text,
        'details': _detailsController.text,
        'imageUrl': downloadUrl,
        'contactDetails': _contactDetailsController.text,
        'username':
            userData['full_name'] ?? userData['societyName'] ?? 'Unknown',
        'profilepic': userData['profilepic'] ??
            '', // Replace with the actual username from your authentication
        'timestamp': FieldValue.serverTimestamp(),
        'postedByUserId':widget.userId,
      });

      Fluttertoast.showToast(msg: "Post uploaded successfully");
      Navigator.pop(context as BuildContext);
    } catch (e) {
      print('Error uploading post: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Failed to upload post. Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
      colors: const [
        Color(0XFF9752C5),
        Color(0xFF000000),
      ],
      radius: 0.8,
      centerAlignment: Alignment.bottomRight,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text(
            'Rent Item Details',
            style: GoogleFonts.ebGaramond(
              textStyle: TextStyle(
                color: Color.fromARGB(255, 254, 253, 255),
                fontSize: 30,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromARGB(255, 195, 106, 240),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _image != null
                            ? Column(
                                children: [
                                  SizedBox(
                                    height: 250,
                                    width: double.infinity,
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: ElevatedButton(
                                  onPressed: _pickImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0XFF9752C5), // Button color
                                  ),
                                  child: const Text('Select Image of Item',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _buildTextField(
                            controller: _itemNameController,
                            label: 'Item Name',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _buildTextField(
                            controller: _categoryController,
                            label: 'Category',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price',
                            prefixText: '₹',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _buildTextField(
                            controller: _detailsController,
                            label: 'Details of Item',
                            maxLines: 5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _buildTextField(
                            controller: _contactDetailsController,
                            label: 'Contact Details',
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _uploadPost,
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0XFF9752C5), // Button color
                              textStyle: const TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(255, 249, 249, 249))),
                          child: const Text('Upload',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle:
            const TextStyle(color: Colors.white), // White color for labels
        fillColor: const Color(0xFF252525),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
          borderSide: const BorderSide(
              color: Colors.purple), // Purple border when focused
        ),
      ),
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
    );
  }
}
