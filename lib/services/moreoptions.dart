import 'package:flutter/material.dart';

class MoreOptionsDialog extends StatelessWidget {
  final VoidCallback onClearChat;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const MoreOptionsDialog({
    super.key,
    required this.onClearChat,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 10,
          top: 10,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.delete,
                        color: Colors
                            .white), // Changed to delete icon for Clear Chat
                    title: Text('Clear Chat',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      onClearChat();
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.block, color: Colors.white),
                    title: Text('Block', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      onBlock();
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.report, color: Colors.white),
                    title:
                        Text('Report', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      onReport();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
