import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/home.dart';
import 'package:flutter/material.dart';
import 'package:cooig_firebase/models/user.dart';

//favourites  and media not fetched sender name not visible in messagaes
class HomeScreen extends StatefulWidget {
  final String currentUserId;

  HomeScreen({super.key, required this.currentUserId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Homepage(userId: widget.currentUserId)),
                );
              },
            ),
            Expanded(
              child: Container(
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
                    Text(
                      'Search',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Container(
            color: const Color.fromARGB(255, 0, 0, 0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Chats'),
                Tab(text: 'Groups'),
                Tab(text: 'Archived'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(context),
          _buildGroupsTab(context),
          _buildArchivedTab(context),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildChatTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final List<User> users = snapshot.data!.docs.map((doc) {
          return User.fromFirestore(doc);
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserTile(context, user, true);
          },
        );
      },
    );
  }

  Widget _buildGroupsTab(BuildContext context) {
    return Center(child: Text("Groups", style: TextStyle(color: Colors.white)));
  }

  Widget _buildArchivedTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('archived_users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final List<User> users = snapshot.data!.docs.map((doc) {
          return User.fromFirestore(doc);
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserTile(context, user, false);
          },
        );
      },
    );
  }

  Widget _buildUserTile(BuildContext context, User user, bool isInChats) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.currentUserId + "_" + user.id)
          .get(),
      builder: (context, snapshot) {
        Color backgroundColor = Colors.black; // Default background color

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('backgroundColor')) {
              backgroundColor = Color(data['backgroundColor']);
            }
          }
        }

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(user.image.isNotEmpty
                ? user.image
                : 'https://via.placeholder.com/150'),
          ),
          title: Text(user.full_name, style: TextStyle(color: Colors.white)),
          subtitle: Text(user.bio, style: TextStyle(color: Colors.white70)),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/individual_chat',
              arguments: {
                'currentUserId': widget.currentUserId,
                'chatUserId': user.id,
                'fullName': user.full_name,
                'image': user.image,
                'backgroundColor': backgroundColor, // Pass background color
              },
            );
          },
          onLongPress: () {
            if (isInChats) {
              _showChatOptions(context, user);
            } else {
              _showArchivedOptions(context, user);
            }
          },
        );
      },
    );
  }

  void _showChatOptions(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.archive),
              title: Text("Archive"),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('archived_users')
                    .doc(user.id)
                    .set(user.toMap());
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .delete();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text("Delete"),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .delete();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showArchivedOptions(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.unarchive),
              title: Text("Unarchive"),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .set(user.toMap());
                FirebaseFirestore.instance
                    .collection('archived_users')
                    .doc(user.id)
                    .delete();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text("Delete"),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('archived_users')
                    .doc(user.id)
                    .delete();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
