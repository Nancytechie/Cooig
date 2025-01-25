import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecruitmentFormPage extends StatefulWidget {
  @override
  _RecruitmentFormPageState createState() => _RecruitmentFormPageState();
}

class _RecruitmentFormPageState extends State<RecruitmentFormPage> {
  final Map<String, dynamic> userResponses = {
    'Full Name': '',
    'Email': '',
    'Phone Number': '',
    'Skills': '',
    'Work Experience': '',
    'Role Applying For': '',
  };

  // Initialize Firestore instance for future data fetching
  @override
  void initState() {
    super.initState();
  }

  // Form submission handler
  void submitForm() {
    bool isValid = true;

    // Validate that all required fields are filled
    for (var key in userResponses.keys) {
      if (userResponses[key] == '' || userResponses[key] == null) {
        isValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all required fields')),
        );
        break;
      }
    }

    if (isValid) {
      FirebaseFirestore.instance.collection('responses').add({
        'formId': 'recruitmentForm',
        'responses': userResponses,
        'submittedAt': Timestamp.now(),
        'submittedBy': FirebaseAuth.instance.currentUser?.uid,
      }).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application submitted successfully')),
        );
        // Optionally, you can clear or navigate the form on success
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join the Team'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Full Name
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    userResponses['Full Name'] = value;
                  });
                },
              ),
            ),
            // Email
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    userResponses['Email'] = value;
                  });
                },
              ),
            ),
            // Phone Number
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  setState(() {
                    userResponses['Phone Number'] = value;
                  });
                },
              ),
            ),
            // Skills
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Skills',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    userResponses['Skills'] = value;
                  });
                },
              ),
            ),
            // Work Experience
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Work Experience',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    userResponses['Work Experience'] = value;
                  });
                },
              ),
            ),
            // Role Applying For
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Role Applying For',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    userResponses['Role Applying For'] = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: submitForm,
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.send),
      ),
    );
  }
}
