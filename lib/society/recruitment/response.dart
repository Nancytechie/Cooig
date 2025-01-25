import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResponsesPage extends StatelessWidget {
  final String formId;

  ResponsesPage({required this.formId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Responses')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('responses')
            .where('formId', isEqualTo: formId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No responses yet.'));
          }

          final responses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: responses.length,
            itemBuilder: (context, index) {
              var response = responses[index];
              return ListTile(
                title: Text('Response ${index + 1}'),
                subtitle: Text(response['responses'].toString()),
              );
            },
          );
        },
      ),
    );
  }
}
