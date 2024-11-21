import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// For image cropping
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:cooig_firebase/background.dart';
import 'package:path/path.dart';

class SellItemScreen extends StatefulWidget {
  const SellItemScreen({super.key});

  @override
  _SellItemScreenState createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
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
          FirebaseStorage.instance.ref().child('sellposts').child(fileName);
      final uploadTask = storageRef.putFile(_image!);

      // Track the progress
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
            // Handle paused case
            break;
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('sellposts').add({
        'itemName': _itemNameController.text,
        'category': _categoryController.text,
        'price': _priceController.text,
        'details': _detailsController.text,
        'contactDetails': _contactDetailsController.text,
        'imageUrl': downloadUrl,
        'username': 'User123', // Replace with actual username
        'timestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: "Post uploaded successfully");
      Navigator.pop(context as BuildContext);
    } catch (e) {
      print('Error uploading post: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(
            content: Text('Failed to upload post. Please try again.')),
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
          title: const Text(
            'Sell Items',
            style: TextStyle(
              color: Color.fromARGB(255, 254, 253, 255),
              fontSize: 26,
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
                const Text(
                  "Selling Item Details",
                  style: TextStyle(
                    color: Color.fromARGB(255, 171, 98, 220),
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(20.0),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Image of Sell Item',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                                    backgroundColor: const Color(0XFF9752C5),
                                  ),
                                  child: const Text('Select Image of Sell Item',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildTextField(
                            controller: _itemNameController,
                            label: 'Item Name',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildTextField(
                            controller: _categoryController,
                            label: 'Category',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price',
                            prefixText: '₹',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildTextField(
                            controller: _detailsController,
                            label: 'Details of Item',
                            maxLines: 5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildTextField(
                            controller: _contactDetailsController,
                            label: 'Contact Details',
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _uploadPost,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFF9752C5),
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
                ),
              ],
            ),
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
        labelStyle: const TextStyle(color: Colors.white),
        fillColor: const Color(0xFF252525),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: Colors.purple),
        ),
      ),
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
    );
  }
}
