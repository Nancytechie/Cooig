import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:cooig_firebase/models/user.dart';
import 'package:cooig_firebase/models/message.dart';
import 'package:cooig_firebase/services/message_service.dart';

class ForwardScreen extends StatefulWidget {
  final Message message;

  ForwardScreen({required this.message});

  @override
  _ForwardScreenState createState() => _ForwardScreenState();
}

class _ForwardScreenState extends State<ForwardScreen> {
  TextEditingController _searchController = TextEditingController();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          _buildMessagePreview(),
          _buildUserList(filteredUsers),
        ],
      ),
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
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

  Widget _buildMessagePreview() {
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFF9752C5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (widget.message.type == 'image') ...[
            Icon(Icons.image, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Forwarding Image',
                style: TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else if (widget.message.type == 'document') ...[
            Icon(Icons.insert_drive_file, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.message.fileType ?? 'Forwarding Document',
                style: TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                widget.message.msg.length > 50
                    ? "${widget.message.msg.substring(0, 50)}..."
                    : widget.message.msg,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
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
          content:
              Text('You cannot forward the message to more than 5 people.'),
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

  Future<void> _sendMessage() async {
    if (selectedUsers.isNotEmpty) {
      try {
        for (User user in selectedUsers) {
          String conversationId = await _messageService.getOrCreateConversation(
              firebase_auth.FirebaseAuth.instance.currentUser!.uid, user.id);

          Message forwardedMessage = Message(
            msg: widget.message.msg,
            fromId: firebase_auth.FirebaseAuth.instance.currentUser!.uid,
            toId: user.id,
            sent: DateTime.now(),
            isForwarded: true,
            type: widget.message.type,
            read: false,
            fileType: widget.message.fileType,
            fileUrl: widget.message.fileUrl,
          );

          await _messageService.sendMessage(conversationId, forwardedMessage);
        }

        // Build the user names string
        String userNames =
            selectedUsers.map((user) => user.full_name).join(', ');

        // Truncate if too long
        if (userNames.length > 50) {
          userNames = '${userNames.substring(0, 50)}...';
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message forwarded to $userNames'),
          ),
        );
      } catch (e) {
        print("Error forwarding message: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to forward message. Please try again.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please select at least one user to forward the message.'),
        ),
      );
    }
  }
}
