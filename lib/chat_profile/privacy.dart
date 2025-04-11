import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  _PrivacyScreenState createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool readReceipts = true;
  bool typingIndicator = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    if (currentUserId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('userPrivacySettings')
        .doc(currentUserId)
        .get();

    if (doc.exists) {
      setState(() {
        readReceipts = doc.data()?['readReceipts'] ?? true;
        typingIndicator = doc.data()?['typingIndicator'] ?? true;
      });
    }
  }

  Future<void> _updatePrivacySettings() async {
    if (currentUserId == null) return;

    await FirebaseFirestore.instance
        .collection('userPrivacySettings')
        .doc(currentUserId)
        .set({
      'readReceipts': readReceipts,
      'typingIndicator': typingIndicator,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Safety and Control',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF9752C5),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildPrivacySection(
              'Interaction Control',
              [
                buildSwitchTile(
                  'Read Confirmations',
                  'Let others see when you\'ve read their messages.',
                  readReceipts,
                  (value) async {
                    setState(() => readReceipts = value);
                    await _updatePrivacySettings();
                    
                    // Update all conversations to reflect this change
                    await _updateReadReceiptsInConversations(value);
                  },
                ),
                buildSwitchTile(
                  'Typing Visibility',
                  'Show when you are typing a message.',
                  typingIndicator,
                  (value) async {
                    setState(() => typingIndicator = value);
                    await _updatePrivacySettings();
                  },
                ),
              ],
            ),
            buildPrivacySection(
              'Contact Restrictions and Support',
              [
                buildActionTile(
                  'Limit Interactions',
                  Icons.back_hand,
                  () {
                    // Logic for limit interactions
                  },
                ),
                buildActionTile(
                  'Block User',
                  Icons.cancel,
                  () {
                    // Block logic
                  },
                ),
                buildActionTile(
                  'Report Issues',
                  Icons.report,
                  () {
                    showReportIssuesDialog(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReadReceiptsInConversations(bool enabled) async {
    if (currentUserId == null) return;

    // Get all conversations where this user is a participant
    final conversations = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    // Update read receipts setting in each conversation
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in conversations.docs) {
      batch.update(doc.reference, {
        'readReceipts.$currentUserId': enabled,
      });
    }

    await batch.commit();
  }

  Widget buildPrivacySection(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 164, 145, 218),
              ),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 16)),
      leading: Icon(icon, color: Colors.purple),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
      onTap: onTap,
    );
  }

  void showReportIssuesDialog(BuildContext context) {
    final List<String> issues = [
      'Inappropriate Content',
      'Spam',
      'Impersonation',
      'Harassment or Bullying',
      'Intellectual Property Violations',
      'Self-Injury',
      'Technical Problems',
    ];

    String? selectedIssue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Report an Issue'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...issues.map((issue) {
                    return RadioListTile<String>(
                      title: Text(issue),
                      value: issue,
                      groupValue: selectedIssue,
                      onChanged: (value) {
                        setState(() {
                          selectedIssue = value;
                        });
                      },
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedIssue != null
                      ? () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$selectedIssue reported!')),);
                      }
                      : null,
                  child: Text('Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}