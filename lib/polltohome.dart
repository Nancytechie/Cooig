import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Poll {
  final String question;
  final List<String> options;
  final List<int> votes;

  Poll({
    required this.question,
    required this.options,
    required this.votes,
  });

  factory Poll.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Poll(
      question: data['question'],
      options: List<String>.from(data['options']),
      votes: List<int>.from(data['votes']),
    );
  }
}

class PollWidget extends StatefulWidget {
  final Poll poll;

  const PollWidget({super.key, required this.poll});

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  int? selectedOption;

  void _submitVote() {
    if (selectedOption != null) {
      setState(() {
        widget.poll.votes[selectedOption!] += 1;
      });

      // Update votes in Firestore
      FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.poll.question)
          .update({
        'votes': widget.poll.votes,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.poll.question,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...List.generate(widget.poll.options.length, (index) {
              return RadioListTile(
                title: Text(widget.poll.options[index]),
                value: index,
                groupValue: selectedOption,
                onChanged: (int? value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              );
            }),
            ElevatedButton(
              onPressed: _submitVote,
              child: Text('Submit Vote'),
            ),
            SizedBox(height: 10),
            Text('Votes: ${widget.poll.votes.join(', ')}'),
          ],
        ),
      ),
    );
  }
}
