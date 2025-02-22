import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/models/message.dart';
import 'package:cooig_firebase/services/message_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:cooig_firebase/models/user.dart';

class SelectUserScreen extends StatefulWidget {
  final String postID;
  final String userName;
  final String userImage;
  final String text;
  final List<String> mediaUrls;
  final Timestamp timestamp;

  const SelectUserScreen({
    super.key,
    required this.postID,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.mediaUrls,
    required this.timestamp,
  });

  @override
  _SelectUserScreenState createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  List<User> users = [];
  List<User> selectedUsers = [];
  final MessageService _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        users = snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((user) {
      return user.full_name.toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: _buildSearchBar(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildPostPreview(),
          _buildUserList(filteredUsers),
        ],
      ),
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: _sharePost,
        backgroundColor: Color(0xFF9752C5),
        child: Icon(Icons.send, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Color(0xFF9752C5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(width: 8),
          Icon(Icons.search, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreview() {
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFF9752C5),
        borderRadius: BorderRadius.circular(12),
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
                radius: 22,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    _formatTimestamp(widget.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.text,
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<User> filteredUsers) {
    return Expanded(
      child: filteredUsers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isSelected = selectedUsers.contains(user);
                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: user.image.isNotEmpty
                        ? NetworkImage(user.image)
                        : NetworkImage('https://via.placeholder.com/150')
                            as ImageProvider,
                  ),
                  title: Text(
                    user.full_name,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    user.bio,
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  onTap: () => _onUserSelected(user, isSelected),
                );
              },
            ),
    );
  }

  void _onUserSelected(User user, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedUsers.remove(user);
      } else {
        if (selectedUsers.length < 5) {
          selectedUsers.add(user);
        } else {
          _showLimitDialog();
        }
      }
    });
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Limit Exceeded'),
          content: Text('You cannot share the post with more than 5 people.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sharePost() async {
    if (selectedUsers.isNotEmpty) {
      try {
        for (User user in selectedUsers) {
          // Create a conversation ID (or fetch an existing one)
          String conversationId = await _messageService.getOrCreateConversation(
              firebase_auth.FirebaseAuth.instance.currentUser!.uid, user.id);

          // Create a message with the post details
          Message message = Message(
            fromId: firebase_auth.FirebaseAuth.instance.currentUser!.uid,
            toId: user.id,
            msg: widget.text,
            type: 'post',
            read: false,
            sent: DateTime.now(),
            postId: widget.postID,
            userName: widget.userName,
            userImage: widget.userImage,
            mediaUrls: widget.mediaUrls,
          );

          // Send the message
          await _messageService.sendMessage(conversationId, message);
        }

        // Show success message
        String userNames =
            selectedUsers.map((user) => user.full_name).join(', ');
        if (userNames.length > 50) {
          userNames = '${userNames.substring(0, 50)}...';
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post shared with $userNames'),
          ),
        );
      } catch (e) {
        print("Error sharing post: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post. Please try again.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please select at least one user to share the post with.'),
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute}";
  }
}
