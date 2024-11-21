import 'package:flutter/material.dart';

class GroupChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF9752C5), // Purple color for navbar
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey), // Grey back button
          onPressed: () {
            Navigator.pop(context); // Navigate back to previous screen
          },
        ),
        title: Text(
          'Friends Group', // Group name
          style: TextStyle(
            color: Colors.white, // White text color
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.white), // Call icon
            onPressed: () {
              // Handle call action
            },
          ),
          IconButton(
            icon: Icon(Icons.video_call, color: Colors.white), // Video call icon
            onPressed: () {
              // Handle video call action
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white), // More options icon
            onPressed: () {
              // Handle more options action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(8.0),
              children: [
                // Sample messages
                _buildMessageBubble('Hey, how are you?', true),
                _buildMessageBubble('I am good, thanks for asking!', false),
                _buildMessageBubble('What’s up?', true),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildMessageBubble(String message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.0),
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFF9752C5) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Color(0xFF9752C5), // Purple color for input area
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.sticky_note_2, color: Colors.white), // Sticker icon
            onPressed: () {
              // Handle sticker action
            },
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: Colors.white), // Gallery icon
            onPressed: () {
              // Handle gallery action
            },
          ),
          IconButton(
            icon: Icon(Icons.mic, color: Colors.white), // Voice message icon
            onPressed: () {
              // Handle voice message action
            },
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white), // Send button
            onPressed: () {
              // Handle send action
            },
          ),
        ],
      ),
    );
  }
}
