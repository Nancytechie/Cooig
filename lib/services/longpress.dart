// import 'dart:ui'; // For BackdropFilter
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cooig/models/message.dart';

// class LongPressMessageWidget extends StatefulWidget {
//   final Message message;
//   final Function(Message) onMessageUpdated;

//   const LongPressMessageWidget({
//     Key? key,
//     required this.message,
//     required this.onMessageUpdated,
//   }) : super(key: key);

//   @override
//   _LongPressMessageWidgetState createState() => _LongPressMessageWidgetState();
// }

// class _LongPressMessageWidgetState extends State<LongPressMessageWidget> {
//   bool _isMenuVisible = false;
//   Offset _menuOffset = Offset.zero;
//   double _screenHeight = 0;
//   bool _isEditing = false;
//   String? _editingMessageId;
//   String? _editingMessageText;
//   final TextEditingController _textController = TextEditingController();

//   void _toggleMenu(Offset offset) {
//     setState(() {
//       _isMenuVisible = !_isMenuVisible;
//       _menuOffset = offset;
//       print("Menu visibility toggled: $_isMenuVisible"); // Debug print
//     });
//   }

//   Future<void> _saveEditedMessage() async {
//     if (_editingMessageId == null || _textController.text.isEmpty) return;

//     try {
//       await FirebaseFirestore.instance
//           .collection('messages')
//           .doc(_editingMessageId)
//           .update({
//         'msg': _textController.text.trim(),
//         'isEdited': true,
//         'editedAt': DateTime.now(),
//       });

//       setState(() {
//         _isEditing = false;
//         _editingMessageId = null;
//         _editingMessageText = null;
//         _textController.clear();
//       });

//       // Update the local message state
//       widget.onMessageUpdated(widget.message);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to edit message')),
//       );
//     }
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isEditing = false;
//       _editingMessageId = null;
//       _editingMessageText = null;
//       _textController.clear();
//     });
//   }

//   void _startEditing(Message message) {
//     setState(() {
//       _isEditing = true;
//       _editingMessageId = message.messageId;
//       _editingMessageText = message.msg;
//       _textController.text = message.msg;
//     });

//     _showEditDialog(context);
//   }

//   void _showEditDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Edit Message'),
//           content: TextField(
//             controller: _textController,
//             decoration: InputDecoration(hintText: "Edit your message"),
//             autofocus: true,
//           ),
//           actions: [
//             TextButton(
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(18.0),
//                 ),
//               ),
//               child: Text('Cancel', style: TextStyle(color: Colors.black)),
//               onPressed: _cancelEditing,
//             ),
//             TextButton(
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(18.0),
//                 ),
//               ),
//               child: Text('Save', style: TextStyle(color: Colors.white)),
//               onPressed: () {
//                 _saveEditedMessage();
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _forwardMessage(BuildContext context) {
//     print('Forwarding message: ${widget.message.msg}'); // Debug print
//     // Implement the logic to forward the message to other users
//   }

//   void _showLongPressDialog(
//       BuildContext context, Message message, Offset tapPosition) {
//     final screenSize = MediaQuery.of(context).size;
//     final screenWidth = screenSize.width;
//     final screenHeight = screenSize.height;
//     final dialogWidth = screenWidth * 0.8; // Adjust width as needed
//     final dialogHeight = 150.0; // Adjust height as needed

//     // Determine if dialog should appear above or below the tap position
//     final showAbove = tapPosition.dy < screenHeight * 0.7;

//     // Calculate the top position based on whether the dialog should appear above or below
//     double topPosition;
//     if (showAbove) {
//       topPosition = tapPosition.dy - dialogHeight;
//       if (topPosition < 0) {
//         topPosition =
//             tapPosition.dy + 10; // Fallback to below the message if above is out of bounds
//       }
//     } else {
//       topPosition = tapPosition.dy + 10; // Add some space below the tap position
//     }

//     // Ensure the dialog stays within the screen's vertical bounds
//     topPosition = topPosition.clamp(0.0, screenHeight - dialogHeight);

//     // Calculate the left position to ensure it's within the screen bounds
//     double leftPosition = tapPosition.dx - dialogWidth / 2;
//     leftPosition = leftPosition.clamp(0.0, screenWidth - dialogWidth);

//     // Ensure that the dialog is fully visible within the screen height
//     if (!showAbove && (topPosition + dialogHeight > screenHeight)) {
//       topPosition = screenHeight - dialogHeight;
//     }

//     showDialog(
//       context: context,
//       barrierColor: Colors.black.withOpacity(0.5), // Dimmed background
//       barrierDismissible: true, // Dismiss on tapping outside
//       builder: (BuildContext context) {
//         return Stack(
//           children: [
//             // BackdropFilter to apply blur effect to the background
//             Positioned.fill(
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//                 child: Container(color: Colors.black.withOpacity(0.5)),
//               ),
//             ),
//             Positioned(
//               top: topPosition,
//               left: leftPosition,
//               width: dialogWidth,
//               child: Material(
//                 color: Colors.transparent,
//                 child: Align(
//                   alignment:
//                       showAbove ? Alignment.topCenter : Alignment.bottomCenter,
//                   child: Container(
//                     width: dialogWidth,
//                     child: AlertDialog(
//                       contentPadding: EdgeInsets.zero,
//                       content: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ListTile(
//                             leading: Icon(Icons.copy),
//                             title: Text('Copy'),
//                             onTap: () {
//                               Clipboard.setData(
//                                   ClipboardData(text: message.msg));
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                     content:
//                                         Text('Message copied to clipboard')),
//                               );
//                               Navigator.of(context).pop();
//                             },
//                           ),
//                           ListTile(
//                             leading: Icon(Icons.edit),
//                             title: Text('Edit'),
//                             onTap: () {
//                               Navigator.of(context).pop();
//                               _startEditing(message);
//                             },
//                           ),
//                           ListTile(
//                             leading: Icon(Icons.forward),
//                             title: Text('Forward'),
//                             onTap: () {
//                               Navigator.of(context).pop();
//                               _forwardMessage(context);
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     _screenHeight = MediaQuery.of(context).size.height;

//     return GestureDetector(
//       onLongPressStart: (details) {
//         print("Long press detected"); // Debug print
//         double screenHeightThreshold = _screenHeight * 0.7; // 70% of screen height
//         double messagePositionY = details.globalPosition.dy;

//         Offset newMenuOffset;
//         if (messagePositionY > screenHeightThreshold) {
//           // Show menu above the message if it is below 70% of the screen
//           newMenuOffset =
//               Offset(details.globalPosition.dx, messagePositionY - 60);
//         } else {
//           // Show menu below the message
//           newMenuOffset =
//               Offset(details.globalPosition.dx, messagePositionY + 20);
//         }

//         _toggleMenu(newMenuOffset);
//       },
//       child: Stack(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8.0),
//             decoration: BoxDecoration(
//               color: Colors.transparent,
//               borderRadius: BorderRadius.circular(8.0),
//             ),
//             child: Text(widget.message.msg),
//           ),
//           if (_isMenuVisible)
//             Positioned(
//               left: _menuOffset.dx,
//               top: _menuOffset.dy,
//               child: Material(
//                 elevation: 4.0,
//                 color: Colors.white,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     ListTile(
//                       leading: Icon(Icons.copy),
//                       title: Text('Copy'),
//                       onTap: () {
//                         Clipboard.setData(
//                             ClipboardData(text: widget.message.msg));
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Message copied to clipboard')),
//                         );
//                         _toggleMenu(Offset.zero);
//                       },
//                     ),
//                     ListTile(
//                       leading: Icon(Icons.edit),
//                       title: Text('Edit'),
//                       onTap: () {
//                         _startEditing(widget.message);
//                         _toggleMenu(Offset.zero);
//                       },
//                     ),
//                     ListTile(
//                       leading: Icon(Icons.forward),
//                       title: Text('Forward'),
//                       onTap: () {
//                         _forwardMessage(context);
//                         _toggleMenu(Offset.zero);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
