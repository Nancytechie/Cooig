import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FormCreatePage extends StatefulWidget {
  @override
  _FormCreatePageState createState() => _FormCreatePageState();
}

class _FormCreatePageState extends State<FormCreatePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();

  // List to store form fields dynamically
  List<Map<String, dynamic>> formFields = [];

  // Function to add new field
  void addField() {
    setState(() {
      formFields.add({
        'type': 'text',
        'label': 'New Field',
        'options': []
      });
    });
  }

  // Function to remove field
  void removeField(int index) {
    setState(() {
      formFields.removeAt(index);
    });
  }

  // Function to save the form to Firestore
  void createForm() {
    FirebaseFirestore.instance.collection('forms').add({
      'formTitle': titleController.text,
      'fields': formFields,
      'creator': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': Timestamp.now()
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Form created successfully')));
      Navigator.pop(context);
    });
  }

  // Building the field UI dynamically
  Widget buildFormField(int index) {
    Map<String, dynamic> field = formFields[index];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: field['label'],
              decoration: InputDecoration(labelText: 'Field Label'),
              onChanged: (value) {
                setState(() {
                  field['label'] = value;
                });
              },
            ),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: field['type'],
              decoration: InputDecoration(labelText: 'Field Type'),
              items: ['text', 'email', 'multiple_choice'].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  field['type'] = value!;
                });
              },
            ),
            if (field['type'] == 'multiple_choice') 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    ...List.generate(field['options'].length, (i) {
                      return TextFormField(
                        initialValue: field['options'][i],
                        decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                        onChanged: (value) {
                          setState(() {
                            field['options'][i] = value;
                          });
                        },
                      );
                    }),
                    SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          field['options'].add('');
                        });
                      },
                      child: Text('Add Option'),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () => removeField(index),
              child: Text('Remove Field'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Recruitment Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Form Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Expanded(
                child: ListView.builder(
                  itemCount: formFields.length,
                  itemBuilder: (context, index) {
                    return buildFormField(index);
                  },
                ),
              ),
              ElevatedButton(
                onPressed: addField,
                child: Text('Add New Field'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: createForm,
                child: Text('Save Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
