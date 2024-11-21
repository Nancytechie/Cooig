import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cooig_firebase/models/message.dart';

class SwipeableMessage extends StatelessWidget {
  final Message message;
  final VoidCallback onReply;
  final VoidCallback onSwipeLeft; // Handle delete action
  final Widget child;

  const SwipeableMessage({
    required this.message,
    required this.onReply,
    required this.onSwipeLeft,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: key,
      startActionPane: ActionPane(
        motion: const DrawerMotion(), // Use DrawerMotion for a sensitive swipe
        children: [
          SlidableAction(
            onPressed: (context) {
              onSwipeLeft(); // Handle delete action
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            flex: 1, // Ensure the delete button is prominent
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const StretchMotion(), // Keep StretchMotion for reply
        children: [
          SlidableAction(
            onPressed: (context) {
              onReply();
              Slidable.of(context)!.close(); // Close the Slidable after action
            },
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            icon: Icons.reply,
            label: 'Reply',
            flex: 1, // Ensure the reply button is prominent
          ),
        ],
      ),
      child: child,
    );
  }
}
