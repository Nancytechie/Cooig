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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Polls'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
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
              final poll = polls[index].data() as Map<String, dynamic>;
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
  final String userName;
  final String userImage;
  final String question;
  final List<String> options;
  final List<String> imageUrls;
  final bool isTextOption;

  const PollWidget({
    super.key,
    required this.userName,
    required this.userImage,
    required this.question,
    required this.options,
    required this.imageUrls,
    required this.isTextOption,
  });

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  String? selectedOption;
  Map<String, int> votes = {}; // To store votes per option
  int totalVotes = 0; // To store total votes

  void _handleVote(String option) {
    setState(() {
      if (selectedOption == null) {
        selectedOption = option;
        votes[option] = (votes[option] ?? 0) + 1;
        totalVotes += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(0),
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
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
                radius: 20,
              ),
              SizedBox(width: 10),
              Text(
                widget.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Iconsax.settings,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            widget.question,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          if (widget.isTextOption)
            ...widget.options.map((option) {
              double percentage =
                  totalVotes > 0 ? (votes[option] ?? 0) / totalVotes : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: selectedOption == null
                          ? () => _handleVote(option)
                          : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.white, width: 2),
                        ),
                        minimumSize: Size(400, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (selectedOption != null) ...[
                      SizedBox(height: 10),
                      LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 60,
                        lineHeight: 24.0,
                        percent: percentage,
                        backgroundColor: Colors.grey,
                        progressColor: Colors.purple,
                        center: Text(
                          "${(percentage * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
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
  }
}
