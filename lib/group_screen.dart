import 'package:flutter/material.dart';
import 'group_chat_screen.dart';

class GroupScreen extends StatefulWidget {
  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final List<Map<String, String>> groups = [
    {
      'name': 'Friends Group',
      'lastMessage': 'Alice: See you all at 5!',
      'time': '6:30',
      'image': 'https://randomuser.me/api/portraits/women/1.jpg',
    },
    {
      'name': 'Family Group',
      'lastMessage': 'Mom: Dinner is ready!',
      'time': '5:00',
      'image': 'https://randomuser.me/api/portraits/men/1.jpg',
    },
    {
      'name': 'Work Group',
      'lastMessage': 'Boss: Meeting at 9 AM',
      'time': 'Sun',
      'image': 'https://randomuser.me/api/portraits/men/2.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFF9752C5), // Purple color for search bar
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
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
            color: Color(0xFF2C2C2C), // Lightened vertical column
            child: Column(
              children: [
                IconButton(
                  icon: Icon(Icons.person, color: Colors.grey),
                  onPressed: () {
                    Navigator.pop(context); // Assuming home screen is the previous screen
                  },
                ),
                IconButton(
                  icon: Icon(Icons.group, color: Colors.blue), // Blue color for active group icon
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.archive, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.chat, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      if (index == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupChatScreen(),
                          ),
                        );
                      }
                    },
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(groups[index]['image']!),
                      radius: 30,
                    ),
                    title: Text(
                      groups[index]['name']!,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      groups[index]['lastMessage']!,
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      groups[index]['time']!,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
