import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cooig_firebase/background.dart';
import 'package:path/path.dart';

enum UploadStatus { idle, uploading, success, error }

class SellItemScreen extends StatefulWidget {
  final String userId;

  const SellItemScreen({super.key, required this.userId});

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
  UploadStatus _uploadStatus = UploadStatus.idle;

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
        _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields and select an image.')),
      );
      return;
    }

    setState(() {
      _uploadStatus = UploadStatus.uploading;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('sellposts').child(fileName);
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

      await FirebaseFirestore.instance.collection('sellposts').add({
        'itemName': _itemNameController.text,
        'category': _categoryController.text,
        'price': _priceController.text,
        'details': _detailsController.text,
        'imageUrl': downloadUrl,
        'username':
            userData['full_name'] ?? userData['societyName'] ?? 'Unknown',
        'profilepic': userData['profilepic'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'postedByUserId': widget.userId,
      });

      setState(() {
        _uploadStatus = UploadStatus.success;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context as BuildContext);
        }
      });
    } catch (e) {
      print('Error uploading post: $e');
      setState(() {
        _uploadStatus = UploadStatus.error;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _uploadStatus = UploadStatus.idle;
          });
        }
      });

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
      radius: 0.0,
      centerAlignment: Alignment.bottomRight,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text('Selling Item Details',
              style: GoogleFonts.ebGaramond(
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 254, 253, 255),
                  fontSize: 22,
                ),
              )),
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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _image != null
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
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: Icon(Icons.add, color: Colors.white),
                                    label: Text(
                                      'Upload Image',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF9752C5),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
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
                      const SizedBox(height: 20),
                      _uploadStatus == UploadStatus.uploading
                          ? const CircularProgressIndicator()
                          : _uploadStatus == UploadStatus.success
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 100,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Post Uploaded',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                )
                              : _uploadStatus == UploadStatus.error
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 100,
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          'Upload Failed',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ElevatedButton(
                                      onPressed: _uploadPost,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Upload',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                    ],
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
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.purple),
        ),
      ),
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
    );
  }
}
