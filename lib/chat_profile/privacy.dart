import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  @override
  _PrivacyScreenState createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool messageDisappear = false;
  bool readReceipts = true;
  bool typingIndicator = true;
  bool lastSeen = true;

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
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildPrivacySection(
              'Manage Message Visibility',
              [
                buildSwitchTile(
                  'Auto-Disappear Messages',
                  'Messages will vanish when the chat is closed.',
                  messageDisappear,
                  (value) {
                    setState(() {
                      messageDisappear = value;
                    });
                  },
                ),
                buildStaticTile(
                  'End-to-End Encryption',
                  'Messages are encrypted for your privacy.',
                ),
              ],
            ),
            buildPrivacySection(
              'Interaction Control',
              [
                buildSwitchTile(
                  'Read Confirmations',
                  'Let others see when you\'ve read their messages.',
                  readReceipts,
                  (value) {
                    setState(() {
                      readReceipts = value;
                    });
                  },
                ),
                buildSwitchTile(
                  'Typing Visibility',
                  'Show when you are typing a message.',
                  typingIndicator,
                  (value) {
                    setState(() {
                      typingIndicator = value;
                    });
                  },
                ),
                buildSwitchTile(
                  'Last Online Status',
                  'Display your last active status.',
                  lastSeen,
                  (value) {
                    setState(() {
                      lastSeen = value;
                    });
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

  Widget buildStaticTile(String title, String subtitle) {
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

    String? selectedIssue; // Variable to hold the selected issue

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
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedIssue != null
                      ? () {
                          // Handle reporting logic here
                          Navigator.pop(context); // Close the dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$selectedIssue reported!'),
                            ),
                          );
                        }
                      : null, // Disable button if no issue is selected
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
