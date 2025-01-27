import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MaterialUpload extends StatefulWidget {
  final String branch;
  final int year; // Assuming year is passed as int
  final String subject;
  final String unitName;

  const MaterialUpload({
    super.key,
    required this.branch,
    required this.year,
    required this.subject,
    required this.unitName,
  });

  @override
  _MaterialUploadState createState() => _MaterialUploadState();
}

class _MaterialUploadState extends State<MaterialUpload> {
  final _titleController = TextEditingController();
  final _notesLinkController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Form validation

  Future<void> _uploadMaterial() async {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text;
      final notesLink = _notesLinkController.text;

      final yearString = widget.year.toString(); // Convert year to String
      final branch = widget.branch;
      final subject = widget.subject;
      final unitName = widget.unitName;

      try {
        // Reference to the Firestore collection for storing the note
        final noteRef = FirebaseFirestore.instance
            .collection('branches')
            .doc(branch)
            .collection('years')
            .doc(yearString) // Use yearString in the Firestore path
            .collection('subjects')
            .doc(subject)
            .collection('units')
            .doc(unitName)
            .collection('notes')
            .doc();

        // Set the data for the new note
        await noteRef.set({
          'title': title,
          'notesLink': notesLink,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': 0, // Initial likes count
          'userName':
              'Anonymous', // Replace this with actual user name if needed
        });

        Fluttertoast.showToast(msg: 'Material uploaded successfully');
        Navigator.pop(context); // Go back to the previous page
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to upload material');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Material',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Color(0XFF9752C5),
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Form key to validate the form
          child: ListView(
            children: [
              // Title Input Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Material Title',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Enter the title of the material',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes Link Input Field
              TextFormField(
                controller: _notesLinkController,
                decoration: InputDecoration(
                  labelText: 'Google Drive Link',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Enter the link to the notes (Google Drive)',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Google Drive link';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Upload Button
              ElevatedButton(
                onPressed: _uploadMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Upload',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
