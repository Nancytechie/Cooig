import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EditSocietyprofile extends StatefulWidget {
  final dynamic userid;

  const EditSocietyprofile({super.key, required this.userid});

  @override
  State<EditSocietyprofile> createState() => _EditSocietyprofileState();
}

class _EditSocietyprofileState extends State<EditSocietyprofile> {
//  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? bannerImageUrl;
  String? profilepic;
  TextEditingController _societyNameController = TextEditingController();
  TextEditingController _aboutController = TextEditingController();
  TextEditingController _establishedYearController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _statusController = TextEditingController();
  final _LinkController = TextEditingController();

  String? societyName;
  String? about;
  String? category;
  String? establishedYear;
  String? status;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }
   

  Future<void> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.userid).get();

    setState(() {
      societyName = userDoc['societyName'] ?? 'societyName';
      about = userDoc['about'] ?? 'about goes here';
      category = userDoc['category'] ?? 'category';
      establishedYear = userDoc['establishedYear'] ?? 'establishedYear';
      status = userDoc['status'] ?? 'Non-Recruiting';
      _societyNameController.text = societyName ?? '';
      _aboutController.text = about ?? '';
      _establishedYearController.text = establishedYear ?? '';
      _categoryController.text = category ?? '';
      _statusController.text = status!;
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
        'societyName': _societyNameController.text,
        'about': _aboutController.text,
        'establishedYear': _establishedYearController.text,
        'category': _categoryController.text,
        'status': _statusController.text,
        "role": "Society",
        'Link': _LinkController.text,
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
                controller: _societyNameController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'Society Name',
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
                controller: _aboutController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'About',
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
                controller: _establishedYearController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'Established Year',
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
                controller: _categoryController,
                style:
                    TextStyle(color: Colors.white), // Set text color to white
                decoration: InputDecoration(
                  labelText: 'Category',
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.check_circle),
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 247, 245, 245),
                  ),
                ),
                value: status, // Bind status value to display the current one
                items: ['Recruiting', 'Non-Recruiting']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    status = value;
                    _statusController.text =
                        value!; // Update controller's text when dropdown value changes
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a status';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
                dropdownColor: Colors.black,
              ),
              const SizedBox(height: 16),

              // Notes Link Input Field
              TextFormField(
                controller: _LinkController,
                decoration: InputDecoration(
                  labelText: 'Recruitment Form Link',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Enter the link (Google Form recommended)',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Google Drive link';
                  }
                },
              ),

              SizedBox(height: 30),

              // Save Changes Button
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text(
                  'Save Changes',
                  style:
                      TextStyle(color: Colors.white), // Set text color to white
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
