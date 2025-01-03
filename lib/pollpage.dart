import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class PollScreen extends StatefulWidget {
  final String userId; // Replace with your method to get the userId

  const PollScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _PollScreenState createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  Map<String, String?> selectedOptions = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Polls'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls') // Make sure the collection name matches
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final polls = snapshot.data!.docs;

          return ListView.builder(
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final pollDoc = polls[index];
              final poll = pollDoc.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(poll['userID'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final user =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = user['full_name'] ?? 'Unknown';
                  final userImage = user['image'] ?? '';

                  return PollWidget(
                    pollId: pollDoc.id, // Pass the document ID as pollId
                    userName: userName,
                    userImage: userImage,
                    question: poll['question'] ?? '',
                    options: poll['options'] != null
                        ? poll['options'].cast<String>()
                        : [],
                    imageUrls: poll['imageUrls'] != null
                        ? poll['imageUrls'].cast<String>()
                        : [],
                    isTextOption: poll['options'] != null,
                    selectedOption: selectedOptions[pollDoc.id],
                    onOptionSelected: (String option) {
                      setState(() {
                        selectedOptions[pollDoc.id] = option;
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PollWidget extends StatefulWidget {
  final String pollId; // Pass poll ID from Firestore
  final String userName;
  final String userImage;
  final String question;
  final List<String> options;
  final List<String> imageUrls;
  final bool isTextOption;
  final String? selectedOption;
  final void Function(String option) onOptionSelected;
  const PollWidget({
    Key? key,
    required this.pollId,
    required this.userName,
    required this.userImage,
    required this.question,
    required this.options,
    required this.imageUrls,
    required this.isTextOption,
    required this.selectedOption,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  void _handleVote(String option) async {
    if (widget.selectedOption != null) return;

    widget.onOptionSelected(option);

    final pollRef =
        FirebaseFirestore.instance.collection('polls').doc(widget.pollId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final pollSnapshot = await transaction.get(pollRef);
      if (!pollSnapshot.exists) return;

      final pollData = pollSnapshot.data() as Map<String, dynamic>;
      final votes = Map<String, int>.from(pollData['votes'] ?? {});

      votes[option] = (votes[option] ?? 0) + 1;

      transaction.update(pollRef, {'votes': votes});
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
            .doc(widget.pollId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const CircularProgressIndicator();
          }

          final pollData = snapshot.data!.data() as Map<String, dynamic>;
          final votes = Map<String, int>.from(pollData['votes'] ?? {});
          final totalVotes = votes.values.fold(0, (sum, count) => sum + count);

          return Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.userImage.isNotEmpty
                          ? NetworkImage(widget.userImage)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.question,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ...widget.options.map((option) {
                  final voteCount = votes[option] ?? 0;
                  final percentage =
                      totalVotes > 0 ? voteCount / totalVotes : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Stack(
                      children: [
                        // The button itself
                        ElevatedButton(
                          onPressed: widget.selectedOption == null
                              ? () => _handleVote(option)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: widget.selectedOption == option
                                  ? const BorderSide(
                                      color: Colors.blue, width: 2)
                                  : const BorderSide(
                                      color: Colors.white, width: 2),
                            ),
                            minimumSize: const Size(400, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                          ),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        // Progress indicator and percentage text
                        if (widget.selectedOption != null &&
                            widget.selectedOption == option)
                          Positioned(
                            top: 2, // Start from the top of the button
                            left: 0, // Start from the left edge
                            right: 0, // Match the width of the button
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 400 *
                                      percentage, // Match length to percentage
                                  height: 35, // Thickness of the indicator
                                  color: const Color.fromRGBO(128, 0, 128,
                                      0.3), // Color of the progress
                                ),
                                const SizedBox(
                                    height:
                                        0), // Space between indicator and text
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10), // Align text slightly inward
                                  child: Text(
                                    '${(percentage * 100).toStringAsFixed(1)}% ($voteCount votes)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        });
  }
}













































/*
              ...widget.options.map((option) {
                final voteCount = votes[option] ?? 0;
                final percentage =
                    totalVotes > 0 ? voteCount / totalVotes : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: widget.selectedOption == null
                            ? () => _handleVote(option)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: widget.selectedOption == option
                                ? const BorderSide(color: Colors.blue, width: 2)
                                : const BorderSide(
                                    color: Colors.white, width: 2),
                          ),
                          minimumSize: const Size(400, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (widget.selectedOption != null &&
                          widget.selectedOption == option) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey,
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}% ($voteCount votes)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
*/