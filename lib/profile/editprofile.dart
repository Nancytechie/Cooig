import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  final dynamic userid;

  const EditProfilePage({super.key, required this.userid});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
//  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _bannerImage;
  File? _profilepic;
  String? bannerImageUrl;
  String? profilepic;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  String? username;
  String? bio;
  String? branch;
  String? year;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.userid).get();

    setState(() {
      username = userDoc['username'] ?? 'Username';
      bio = userDoc['bio'] ?? 'Bio goes here';
      branch = userDoc['branch'] ?? 'Branch';
      year = userDoc['year'] ?? 'Year';
      _usernameController.text = username ?? '';
      _bioController.text = bio ?? '';
      _yearController.text = year ?? '';
      _branchController.text = branch ?? '';
      bannerImageUrl = userDoc['bannerImageUrl'];
      profilepic = userDoc['profilepic'];
    });
  }

  Future<void> _uploadImageToFirebase(File imageFile, bool isBanner) async {
    try {
      String path = 'user_${widget.userid}/${isBanner ? "banner" : "profile"}';
      UploadTask uploadTask = _storage.ref(path).putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(widget.userid).update({
        isBanner ? 'bannerImageUrl' : 'profilepic': downloadUrl,
      });

      setState(() {
        if (isBanner) {
          bannerImageUrl = downloadUrl;
        } else {
          profilepic = downloadUrl;
        }
      });
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  Future<void> _saveChanges() async {
    try {
      await _firestore.collection('users').doc(widget.userid).update({
        'username': _usernameController.text,
        'bio': _bioController.text,
        'year': _yearController.text,
        'branch': _branchController.text,
      });
      Navigator.pop(context); // Navigate back after saving
    } catch (e) {
      print('Failed to update profile: $e');
    }
  }

  Future<void> _pickImage(bool isBanner) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _uploadImageToFirebase(imageFile, isBanner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.lexend()),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // Set text color to white
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Banner Image
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey[300],
                  child: bannerImageUrl != null
                      ? Image.network(bannerImageUrl!, fit: BoxFit.cover)
                      : Icon(Icons.camera_alt, color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20),

              // Profile Image
              Positioned(
                bottom: -50,
                child: GestureDetector(
                  onTap: () => _pickImage(false),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        profilepic != null ? NetworkImage(profilepic!) : null,
                    child: profilepic == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey[700])
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),

              TextField(
                controller: _usernameController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(
                      color: Colors.white), // Set label color to white
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _bioController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(
                      color: Colors.white), // Set label color to white
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) {
                      // Split the text into words
                      List<String> words = newValue.text.split(RegExp(r'\s+'));

                      // Limit to 7 words
                      if (words.length > 7) {
                        newValue = TextEditingValue(
                          text: words.sublist(0, 7).join(' '),
                          selection: TextSelection.collapsed(
                              offset: newValue.text.length),
                        );
                      }

                      return newValue;
                    },
                  ),
                ],
              ),

              SizedBox(height: 15),
              TextField(
                controller: _yearController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'Year',
                  labelStyle: TextStyle(
                      color: Colors.white), // Set label color to white
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _branchController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'Branch',
                  labelStyle: TextStyle(
                      color: Colors.white), // Set label color to white
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Save Changes Button
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style:
                      TextStyle(color: Colors.white), // Set text color to white
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
