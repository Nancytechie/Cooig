import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double textSize;
  final Widget? leading;

  final dynamic iconTheme;

  const CustomAppBar({
    super.key,
    required this.title,
    this.textSize = 30.0,
    this.leading,
    this.iconTheme,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      // Center the title
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: GoogleFonts.libreBodoni(
          textStyle: TextStyle(
            color: const Color(0XFF9752C5),
            fontSize: textSize, // White text for contrast
          ),
        ),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            // Navigate to notifications page
            // Navigator.push(
            // context,
            // MaterialPageRoute(builder: (context) => NotificationsPage()),
            // );
          },
        ),
        IconButton(
          icon: const Icon(Icons.chat, color: Colors.white),
          onPressed: () {
            // Navigate to chat page
            // Navigator.push(
            // context,
            // MaterialPageRoute(builder: (context) => ChatPage()),
            // );
          },
        ),
      ],
      backgroundColor: Colors.black, // Black app bar
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
