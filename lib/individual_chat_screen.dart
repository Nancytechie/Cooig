import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:cooig_firebase/chat_profile/home.dart';
import 'package:cooig_firebase/chat_profile/solid_color_wallpapers.dart';
import 'package:cooig_firebase/forward.dart';
import 'package:cooig_firebase/models/message.dart';
import 'package:cooig_firebase/services/imagepreview.dart';
import 'package:cooig_firebase/services/imageview.dart';
import 'package:cooig_firebase/services/message_service.dart';
import 'package:cooig_firebase/services/multiimagepreview.dart';
import 'package:cooig_firebase/services/videocall.dart';
import 'package:cooig_firebase/services/voicecall.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:flutter_sound/public/util/flutter_sound_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class IndividualChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;
  final String fullName;
  final String image;
  final Color initialBackgroundColor;
  final Color backgroundColor;
  final String? duration; // Accept background color as a parameter

  const IndividualChatScreen({
    super.key,
    required this.currentUserId,
    required this.chatUserId,
    required this.fullName,
    required this.image,
    this.initialBackgroundColor = Colors.black,
    required this.backgroundColor,
    this.duration,
  });

  @override
  _IndividualChatScreenState createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final MessageService messageService = MessageService();
  String? conversationId;
  Stream<List<Message>>? messagesStream;
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;
  bool showEmojiPicker = false;
  bool isTypingOtherUser = false;
  Stream<DocumentSnapshot>? typingStream;
  Color backgroundColor = Colors.black;
  late FlutterSoundRecorder _recorder;
  bool isRecording = false;
  bool _isRecorderInitialized = false;
  String? recordedFilePath;
  DateTime? recordingStartTime; // To track when recording starts
  String recordingDuration = "00:00"; // To store calculated duration
  late FlutterSoundPlayer _audioPlayer;
  final bool _isPlaying = false;
  String? _currentAudioUrl;

  @override
  void initState() {
    super.initState();
    backgroundColor = widget.initialBackgroundColor;
    _recorder = FlutterSoundRecorder();
    initializeRecorder();
    _initializeChat().then((_) {
      if (conversationId != null) {
        _initializeMessageStream();
        _fetchBackgroundColor();
      }
    });

    _controller.addListener(() {
      setState(() {
        isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  Future<void> initializeRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException("Microphone permission not granted");
    }
    await _recorder.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) return;

    recordingStartTime = DateTime.now(); // Record the start time

    // Start the recording
    await _recorder.startRecorder(toFile: 'audio.aac');

    // Start a timer to update the UI
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isRecording) {
        timer.cancel(); // Stop updating if recording is not active
      } else {
        final elapsed = DateTime.now().difference(recordingStartTime!);
        setState(() {
          recordingDuration =
              "${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}";
        });
      }
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecorderInitialized) return;

    String? path = await _recorder.stopRecorder();
    if (path != null && recordingStartTime != null) {
      final totalDuration =
          DateTime.now().difference(recordingStartTime!).inSeconds;

      // Append the duration to the audio URL
      String audioUrl = await uploadFileToStorage(File(path), 'chat_audios');
      String audioUrlWithDuration =
          "$audioUrl?duration=${totalDuration.toString()}";

      sendAudioFile(audioUrlWithDuration); // Send the URL with duration
      setState(() {
        recordingDuration = "00:00"; // Reset after sending
      });
    }

    recordingStartTime = null; // Clear start time
  }

  void _initializeMessageStream() {
    if (conversationId != null) {
      setState(() {
        messagesStream = FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .orderBy('sent', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => Message.fromFirestore(doc))
                .where((message) =>
                    !(message.deletedFor?.contains(widget.currentUserId) ??
                        false))
                .toList());
      });
    }
  }

  Future<void> _initializeChat() async {
    try {
      conversationId = await messageService.getOrCreateConversation(
          widget.currentUserId, widget.chatUserId);

      setState(() {
        messagesStream = messageService.fetchMessages(conversationId!);
        typingStream = FirebaseFirestore.instance
            .collection('chats')
            .doc(conversationId)
            .snapshots();
      });
      _fetchBackgroundColor();
      typingStream?.listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            isTypingOtherUser = snapshot.get('isTyping') ?? false;
          });
        }
      });

      messagesStream?.listen((messages) {
        for (var message in messages) {
          if (!message.read && message.toId == widget.currentUserId) {
            _markMessageAsRead(message);
          }
        }
      });
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  Future<void> _fetchBackgroundColor() async {
    if (conversationId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (snapshot.exists) {
      setState(() {
        backgroundColor =
            Color(snapshot.data()?['backgroundColor'] ?? Colors.black.value);
      });
    }
  }

  void _selectBackgroundColor() async {
    final selectedColor = await Navigator.push<Color>(
      context,
      MaterialPageRoute(
        builder: (context) => SolidColorWallpapers(
          onColorSelected: (Color color) {
            Navigator.pop(context, color); // Pass the selected color back
          },
        ),
      ),
    );

    if (selectedColor != null) {
      _updateBackgroundColor(selectedColor);
    }
  }

  void _updateBackgroundColor(Color color) {
    setState(() {
      backgroundColor = color;
    });

    if (conversationId != null) {
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({'backgroundColor': color.value});
    }
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _updateConversationBackgroundColor(String conversationId, Color color) {
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .update({
      'backgroundColor': color.value, // Store the color value
    }).then((_) {
      print("Background color updated successfully");
    }).catchError((error) {
      print("Error updating background color: $error");
    });
  }

  Future<void> _selectAudio() async {
    try {
      // Open file picker to select an audio file
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.audio);

      if (result != null) {
        File audioFile =
            File(result.files.single.path!); // Get the selected file
        await _handleAudioUpload(audioFile); // Handle audio upload and sending
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No audio file selected')),
        );
      }
    } catch (e) {
      print("Error selecting audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error selecting audio file. Please try again.')),
      );
    }
  }

  Future<void> _handleAudioUpload(File audioFile) async {
    try {
      // Upload the audio file to Firebase Storage
      String audioUrl = await uploadFileToStorage(audioFile, 'chat_audios');

      // Send the audio message
      await _sendAudioMessage(audioUrl);
    } catch (e) {
      print("Error uploading audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error uploading audio file. Please try again.')),
      );
    }
  }

  Future<void> _sendAudioMessage(String audioUrl) async {
    if (conversationId == null) return;
    // add acircular loader being send to firebase
    // Create and send the audio message
    Message message = Message(
      fromId: widget.currentUserId,
      toId: widget.chatUserId,
      msg: audioUrl, // Store the audio URL as the message content
      type: 'audio',
      read: false,
      sent: DateTime.now(),
    );

    try {
      await messageService.sendMessage(conversationId!, message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio file sent successfully')),
      );
    } catch (e) {
      print("Error sending audio message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send audio file. Please try again.')),
      );
    }
  }

  void _selectColorFromPalette() async {
    // Navigate to the SolidColorWallpapers screen and get the selected color
    final selectedColor = await Navigator.push<Color>(
      context,
      MaterialPageRoute(
        builder: (context) => SolidColorWallpapers(
          onColorSelected: (Color color) {
            // This callback will be triggered with the selected color
            setState(() {
              backgroundColor = color; // Update the local background color
            });
            _updateConversationBackgroundColor(
                conversationId!, color); // Update Firestore with the new color
          },
        ),
      ),
    );

    // If a color was selected, update the background color
    if (selectedColor != null && conversationId != null) {
      setState(() {
        backgroundColor = selectedColor; // Set the new background color
      });
      _updateConversationBackgroundColor(conversationId!,
          selectedColor); // Update Firestore with the new color
    }
  }

  Widget _buildTypingIndicator() {
    return isTypingOtherUser
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        curve: Curves.easeInOut,
                        transform: Matrix4.translationValues(
                          0.0,
                          index % 2 == 0 ? 3.0 : -3.0,
                          0.0,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }

  void _showLongPressDialog(
      BuildContext context, Message message, Offset tapPosition) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final dialogWidth = screenWidth * 0.8;
    final dialogHeight = 180.0;

    final showAbove = tapPosition.dy > screenHeight * 0.7;

    // Calculate top position based on showAbove
    double topPosition;
    if (showAbove) {
      // Show above the message
      topPosition = tapPosition.dy - dialogHeight - 50;
      if (topPosition < 0) {
        topPosition = tapPosition.dy + 10; // Adjust if there's no space above
      }
    } else {
      // Show below the message
      topPosition = tapPosition.dy + 10;
      if (topPosition + dialogHeight > screenHeight) {
        topPosition =
            screenHeight - dialogHeight; // Adjust if it overflows below
      }
    }

    // Calculate left position and ensure it stays within the screen
    double leftPosition = tapPosition.dx - dialogWidth / 2;
    leftPosition = leftPosition.clamp(0.0, screenWidth - dialogWidth);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              top: topPosition,
              left: leftPosition,
              width: dialogWidth,
              child: Material(
                color: Colors.transparent,
                child: Align(
                  alignment:
                      showAbove ? Alignment.bottomCenter : Alignment.topCenter,
                  child: SizedBox(
                    width: dialogWidth,
                    child: AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(Icons.copy),
                            title: Text('Copy'),
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: message.msg));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Message copied to clipboard')),
                              );
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showEditMessageDialog(context, message);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.forward),
                            title: Text('Forward'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ForwardScreen(message: message),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              message.isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              color: message.isFavorite
                                  ? Colors.orangeAccent
                                  : Colors.grey,
                            ),
                            title: Text(
                              message.isFavorite
                                  ? 'Unmark as Favorite'
                                  : 'Mark as Favorite',
                            ),
                            onTap: () {
                              final newStatus = !message.isFavorite;
                              _updateMessageFavoriteStatus(message, newStatus);
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete'),
                            onTap: () async {
                              Navigator.of(context).pop(); // Close the dialog
                              bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Delete Message'),
                                    content: Text(
                                        'Are you sure you want to delete this message for yourself?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context)
                                            .pop(false), // Cancel
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context)
                                            .pop(true), // Confirm
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                await _deleteMessageForMe(
                                    message); // Delete for me functionality
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessageForMe(Message message) async {
    try {
      // Mark the message as deleted for the current user in Firestore
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(message.messageId)
          .update({
        'deletedFor': FieldValue.arrayUnion([widget.currentUserId]),
      });

      print("Message deleted for user successfully");
    } catch (e) {
      print("Error deleting message for user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message. Please try again.')),
      );
    }
  }

  void _showEditMessageDialog(BuildContext context, Message message) {
    final TextEditingController editController =
        TextEditingController(text: message.msg);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Message"),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              hintText: "Update your message",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty && newContent != message.msg) {
                  await MessageService().editMessage(
                    conversationId!,
                    message.messageId!,
                    newContent,
                  );
                }
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _selectColor(Color color) {
    setState(() {
      var initialBackgroundColor = color; // Update the local background color
    });
    _updateConversationBackgroundColor(
        conversationId!, color); // Update Firestore
  }

  // Future<void> _deleteMessage(Message message) async {
  //   try {
  //     // Delete the message from Firestore (assuming you store messages under 'messages' collection)
  //     await FirebaseFirestore.instance
  //         .collection('chats')
  //         .doc(conversationId)
  //         .collection('messages')
  //         .doc(message.messageId)
  //         .delete();

  //     print("Message deleted successfully");

  //     // Optionally, update the UI if needed (if using a stream)
  //     // For example, the stream will automatically update, but you can also manually update the list
  //   } catch (e) {
  //     print("Error deleting message: $e");
  //   }
  // }

  Future<void> sendAudioFile(String? audioFilePath) async {
    if (audioFilePath == null || conversationId == null) return;

    Message message = Message(
      fromId: widget.currentUserId,
      toId: widget.chatUserId,
      msg: audioFilePath, // Send the file path of the recorded audio
      type: 'audio', // Audio message type
      read: false,
      sent: DateTime.now(),
    );

    try {
      await messageService.sendMessage(conversationId!, message);
    } catch (e) {
      print('Error sending audio message: $e');
    }
  }

  Future<void> _markMessageAsRead(Message message) async {
    if (conversationId != null) {
      await messageService.updateMessageReadStatus(
          conversationId!, message.messageId!, true);
    }
  }

  Future<void> _sendMessage({String? repliedToMessageId}) async {
    if (_controller.text.trim().isEmpty || conversationId == null) return;

    Message message = Message(
      fromId: widget.currentUserId,
      toId: widget.chatUserId,
      msg: _controller.text.trim(),
      type: 'text',
      read: false,
      sent: DateTime.now(),
      repliedTo: repliedToMessageId, // Ensure this is not null when replying
    );

    try {
      await messageService.sendMessage(conversationId!, message);

      // Clear input and reply context
      _controller.clear();
      setState(() {
        replyingTo = null;
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Future<String> uploadFileToStorage(File file, String folderName) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
          FirebaseStorage.instance.ref().child(folderName).child(fileName);
      TaskSnapshot uploadTask = await reference.putFile(file);
      return await uploadTask.ref.getDownloadURL(); // Get the download URL
    } catch (e) {
      print("Error uploading file: $e");
      rethrow; // Rethrow the error to handle it later
    }
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
          FirebaseStorage.instance.ref().child('chat_images').child(fileName);
      TaskSnapshot uploadTask = await reference.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL(); // Get the download URL
    } catch (e) {
      print("Error uploading image: $e");
      rethrow; // Rethrow the error to handle it later
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        await _handleImageUpload([pickedFile]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image captured')),
        );
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        await _handleImageUpload(pickedFiles);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No images selected')),
        );
      }
    } catch (e) {
      print("Error selecting images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting images: $e')),
      );
    }
  }

  Future<void> _handleImageUpload(List<XFile> files) async {
    try {
      List<String> uploadedUrls = [];

      for (XFile file in files) {
        // Upload each file to Firebase Storage and retrieve the URL
        String url = await uploadImageToStorage(File(file.path));
        uploadedUrls.add(url);
      }

      // Check if we have a single URL or multiple URLs
      if (uploadedUrls.isNotEmpty) {
        // If only one image is selected, navigate to the image preview screen
        if (uploadedUrls.length == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewScreen(
                imageUrl: uploadedUrls.first,
                imageFiles:
                    files, // Send the original files for editing if needed
              ),
            ),
          );
        } else {
          // If multiple images are selected, show a multi-image preview
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiImagePreviewScreen(
                imageUrls: uploadedUrls,
                imageFiles:
                    files, // Send the original files for bulk actions if needed
              ),
            ),
          );
        }

        // Now send the message containing the image URLs
        _sendImageMessage(uploadedUrls);
      }
    } catch (e) {
      print("Error uploading images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    }
  }

  Future<void> _sendImageMessage(List<String> imageUrls) async {
    if (conversationId == null || imageUrls.isEmpty) return;

    // Create a message for each image URL
    for (String imageUrl in imageUrls) {
      Message message = Message(
        fromId: widget.currentUserId,
        toId: widget.chatUserId,
        msg: imageUrl, // Use the image URL as the message text
        type: 'image', // Set type as 'image'
        read: false,
        sent: DateTime.now(),
      );

      try {
        await messageService.sendMessage(conversationId!, message);
        print("Image message sent successfully");
      } catch (e) {
        print("Error sending image message: $e");
      }
    }
  }

  Future<String> uploadDocumentToStorage(File documentFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference = FirebaseStorage.instance
          .ref()
          .child('chat_documents')
          .child(fileName);
      TaskSnapshot uploadTask = await reference.putFile(documentFile);
      return await uploadTask.ref.getDownloadURL(); // Get the download URL
    } catch (e) {
      print("Error uploading document: $e");
      rethrow;
    }
  }

  Future<void> _selectDocument() async {
    try {
      // Open file picker to select document
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null) {
        File file = File(result.files.single.path!); // Get the selected file
        String documentUrl = await uploadDocumentToStorage(file);

        // Get the file name (this is the name saved by the user)
        String fileName = result.files.single.name;

        // Send the document name and URL as a message
        _sendDocumentMessage(fileName, documentUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No document selected')),
        );
      }
    } catch (e) {
      print("Error selecting document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting document: $e')),
      );
    }
  }

  Future<void> _sendDocumentMessage(String fileName, String documentUrl) async {
    if (conversationId == null || documentUrl.isEmpty) return;

    // Download the document for the receiver
    await _downloadDocument(documentUrl, fileName);

    Message message = Message(
      fromId: widget.currentUserId,
      toId: widget.chatUserId,
      msg: fileName, // Use the file name here
      type: 'document', // Set type as 'document'
      read: false,
      sent: DateTime.now(),
    );

    try {
      await messageService.sendMessage(conversationId!, message);
      print("Document message sent successfully");
    } catch (e) {
      print("Error sending document message: $e");
    }
  }

// local storage of phone not accessed permission handler to access storage
  /* Future<void> _downloadDocumentForReceiver(
      String fileName, String documentUrl) async {
    try {
      // Get the path to save the document
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/cooig/documents/$fileName';

      // Create the directory if it doesn't exist
      final fileDirectory = Directory('${directory.path}/cooig/documents/');
      if (!await fileDirectory.exists()) {
        await fileDirectory.create(recursive: true);
      }

      // Download the document
      var response = await Dio().download(documentUrl, filePath);

      // Check if the file was successfully downloaded
      if (response.statusCode == 200) {
        print('Document downloaded to: $filePath');
      } else {
        print('Failed to download document');
      }
    } catch (e) {
      print("Error downloading document: $e");
    }
  }
*/
// favourites not getting stored in favourites
  void _updateMessageFavoriteStatus(Message message, bool newStatus) async {
    try {
      // Update the 'isFavorite' field in Firestore
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(message.messageId)
          .update({'isFavorite': newStatus});

      setState(() {
        message.isFavorite = newStatus; // Update the local state
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'Message marked as favorite'
              : 'Message unmarked as favorite'),
        ),
      );
    } catch (e) {
      print('Error updating favorite status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status.')),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.insert_photo),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context); // Close the modal bottom sheet

                // Call the method to pick images from the gallery
                _selectFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.file_copy),
              title: Text('Document'),
              onTap: () {
                Navigator.pop(context);
                // Handle document selection
                _selectDocument();
              },
            ),
            ListTile(
              leading: Icon(Icons.audiotrack), // Icon for audio files
              title: Text('Audio'),
              onTap: () {
                Navigator.pop(context);
                _selectAudio(); // Call the audio picker function
              },
            ),
          ],
        );
      },
    );
  }

  Timer? _timer;

// Start the recording and dynamically update the duration
  void _startTimer() {
    _timer?.cancel(); // Ensure no previous timer is running
    int seconds = 0;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
        int minutes = seconds ~/ 60;
        int remainingSeconds = seconds % 60;
        recordingDuration =
            "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
      });
    });
  }

// Stop the timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null; // Cleanup
  }

  Widget _buildEmojiPicker() {
    return Container(
      color: Colors.purple,
      child: SizedBox(
        height: 250,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            _controller.text += emoji.emoji;
          },
        ),
      ),
    );
  }

  Message? replyingTo; // Track the message being replied to
  // ask location storage notifications phone
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (ModalRoute.of(context)?.settings.name != '/home') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    userid: widget.currentUserId,
                    fullName: widget.fullName,
                    image: widget.image,
                    conversationId: conversationId ?? '',
                    currentUserId: widget.currentUserId,
                    //userid: widget.currentUserId,
                  ),
                ),
              );
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.image),
              ),
              SizedBox(width: 10),
              Text(widget.fullName),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VoiceCallScreen(
                    userId: widget.chatUserId,
                    userName: widget.fullName,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(
                    userId: widget.chatUserId,
                    userName: widget.fullName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesStream == null
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Message>>(
                    stream: messagesStream?.map((messages) => messages
                        .where((message) => !(message.deletedFor
                                ?.contains(widget.currentUserId) ??
                            false))
                        .toList()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error loading messages"));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No messages yet"));
                      }

                      final messages = snapshot.data!;
                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isSentByCurrentUser =
                              message.fromId == widget.currentUserId;

                          bool showDateHeader = false;
                          if (index == messages.length - 1 ||
                              (index + 1 < messages.length &&
                                  !isSameDate(message.sent,
                                      messages[index + 1].sent))) {
                            showDateHeader = true;
                          }

                          return Column(
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 12, 12, 12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        DateFormat('MMMM dd, yyyy')
                                            .format(message.sent),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color.fromARGB(
                                              255, 255, 251, 251),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              SwipeableContainer(
                                message: message,
                                isSentByCurrentUser: isSentByCurrentUser,
                                onSwipeReply: (String replyPreview) {
                                  setState(() {
                                    replyingTo = message;
                                  });
                                },
                                child: GestureDetector(
                                  onLongPressStart:
                                      (LongPressStartDetails details) {
                                    _showLongPressDialog(context, message,
                                        details.globalPosition);
                                  },
                                  child: MessageBubble(
                                    message: message,
                                    isSentByCurrentUser: isSentByCurrentUser,
                                    conversationId: conversationId ?? "",
                                    onFavoriteToggled: (updatedMessage) {
                                      _updateMessageFavoriteStatus(
                                          updatedMessage, !message.isFavorite);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),
          if (replyingTo != null)
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 56, 37, 52),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replyingTo!.fromId == widget.currentUserId
                              ? "You"
                              : widget.fullName, // toId get username
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(221, 255, 255, 255),
                          ),
                        ),
                        Text(
                          replyingTo!.type == 'text'
                              ? replyingTo!.msg
                              : replyingTo!.type == 'image'
                                  ? "Replying to image"
                                  : replyingTo!.type == 'audio'
                                      ? "Replying to audio"
                                      : "Replying...",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color.fromARGB(137, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        replyingTo = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (showEmojiPicker) _buildEmojiPicker(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (!isRecording) ...[
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.grey),
                    onPressed: _showMoreOptions,
                  ),
                  IconButton(
                    icon: Icon(Icons.emoji_emotions, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        showEmojiPicker = !showEmojiPicker;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (value) {
                        setState(() {
                          isTyping = value.isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  if (isTyping)
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.green),
                      onPressed: () {
                        _sendMessage(repliedToMessageId: replyingTo?.messageId);
                        setState(() {
                          replyingTo = null;
                          isTyping = false;
                        });
                      },
                    )
                  else ...[
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.grey),
                      onPressed: _pickImage,
                    ),
                    GestureDetector(
                      onLongPress: () async {
                        setState(() {
                          isRecording = true;
                        });
                        await startRecording();
                      },
                      onLongPressUp: () async {
                        setState(() {
                          isRecording = false;
                        });
                        await stopRecording();
                      },
                      child: Icon(
                        Icons.mic,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
                  ],
                ] else ...[
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          recordingDuration,
                          style: TextStyle(fontSize: 16),
                        ),
                        Expanded(
                          child: WaveWidget(),
                        ),
                        IconButton(
                          icon: Icon(Icons.stop, color: Colors.red),
                          onPressed: () async {
                            setState(() {
                              isRecording = false;
                            });
                            await stopRecording();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveWidget extends StatefulWidget {
  const WaveWidget({super.key});

  @override
  _WaveWidgetState createState() => _WaveWidgetState();
}

class _WaveWidgetState extends State<WaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          children: List.generate(5, (index) {
            final height =
                (index % 2 == 0 ? _animation.value : 1 - _animation.value) * 20;
            return Container(
              width: 5,
              height: height,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

// For date formatting
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isSentByCurrentUser;
  final Function(Message) onFavoriteToggled;
  final String conversationId;
  final Color? backgroundColor;
  final bool isTypingIndicator;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSentByCurrentUser,
    required this.onFavoriteToggled,
    required this.conversationId,
    this.backgroundColor,
    this.isTypingIndicator = false,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  late FlutterSoundPlayer _audioPlayer;
  bool _isPlaying = false;
  String? _currentAudioUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer = FlutterSoundPlayer();
    _initializeAudioPlayer();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      await _audioPlayer.openPlayer();
    } catch (e) {
      print("Error initializing audio player: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer().catchError((e) {
      print("Error closing audio player: $e");
    });
    super.dispose();
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentAudioUrl = null;
      });
    } catch (e) {
      print("Error stopping audio: $e");
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    if (_isPlaying && _currentAudioUrl == audioUrl) {
      await _stopAudio();
      return;
    }

    try {
      await _audioPlayer.startPlayer(
        fromURI: audioUrl,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _currentAudioUrl = null;
          });
        },
      );
      setState(() {
        _isPlaying = true;
        _currentAudioUrl = audioUrl;
      });
    } catch (e) {
      print("Error playing audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to play audio. Check the file URL.")),
      );
    }
  }

  Widget _buildRepliedToMessage() {
    if (widget.message.repliedTo == null) return SizedBox.shrink();
    //reciever id
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(widget.message.repliedTo)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox.shrink();
        }

        final repliedMessage = Message.fromFirestore(snapshot.data!);

        String replyPreview;
        if (repliedMessage.type == 'text') {
          replyPreview = repliedMessage.msg;
        } else if (repliedMessage.type == 'image') {
          replyPreview = 'Replying to image';
        } else if (repliedMessage.type == 'audio') {
          replyPreview = 'Replying to audio';
        } else if (repliedMessage.type == 'document') {
          replyPreview =
              'Replying to document: ${repliedMessage.msg.split('/').last}';
        } else {
          replyPreview = repliedMessage.msg;
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 100, 57, 90),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              minWidth: 50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repliedMessage.fromId == widget.message.fromId
                      ? "You"
                      : " sendername",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
                Text(
                  replyPreview,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.backgroundColor ??
        (widget.isSentByCurrentUser
            ? const Color(0xFF9752C5)
            : const Color.fromARGB(255, 245, 245, 245));

    final alignment = widget.isSentByCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final textAlign =
        widget.isSentByCurrentUser ? TextAlign.right : TextAlign.left;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft:
          widget.isSentByCurrentUser ? Radius.circular(12) : Radius.circular(0),
      bottomRight:
          widget.isSentByCurrentUser ? Radius.circular(0) : Radius.circular(12),
    );

    final crossAxisAlignment = widget.isSentByCurrentUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              if (widget.message.repliedTo != null) _buildRepliedToMessage(),
              if (widget.message.type == 'text')
                Text(
                  widget.message.msg,
                  textAlign: textAlign,
                  style: TextStyle(
                    color: widget.isSentByCurrentUser
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                  ),
                ),
              if (widget.message.type == 'image')
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ImageViewScreen(imageUrl: widget.message.msg),
                      ),
                    );
                  },
                  child: Image.network(
                    widget.message.msg,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              if (widget.message.type == 'audio')
                Row(
                  children: [
                    // Play/Pause Button
                    GestureDetector(
                      onTap: () async {
                        if (_isPlaying &&
                            _currentAudioUrl == widget.message.msg) {
                          await _stopAudio();
                        } else {
                          await _playAudio(widget.message.msg);
                        }
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(
                          _isPlaying && _currentAudioUrl == widget.message.msg
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Conditional Wave Animation
                    Expanded(
                      child: SizedBox(
                        height: 20,
                        child: Row(
                          children: List.generate(
                            20,
                            (index) => _isPlaying &&
                                    _currentAudioUrl == widget.message.msg
                                ? AnimatedWaveBar(
                                    index: index) // Moving waves when playing
                                : StaticWaveBar(
                                    index:
                                        index), // Static waves when not playing
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (widget.message.type == 'document')
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          String localDocumentPath =
                              await _getLocalDocumentPath(widget
                                  .message.msg); //flutter toast t show download
                          bool fileExists =
                              await File(localDocumentPath).exists();
                          if (!fileExists) {
                            await _downloadDocument(
                                localDocumentPath, widget.message.msg);
                          }
                          final result = await OpenFile.open(localDocumentPath);
                          if (result.message != 'File not found') {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Unable to open the document")));
                          }
                        },
                        child: Text(
                          widget.message.msg.split('/').last,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      widget.onFavoriteToggled(widget.message);
                    },
                    child: Icon(
                      widget.message.isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      color: widget.message
                              .isFavorite //recieved messages star icon white in color
                          ? Colors.orange
                          : const Color(0xFF9752C5),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat.jm().format(widget.message.sent),
                    style: TextStyle(
                      color: widget.isSentByCurrentUser
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  if (widget.isSentByCurrentUser) const SizedBox(width: 5),
                  if (widget.isSentByCurrentUser)
                    Icon(
                      widget.message.read ? Icons.done_all : Icons.check,
                      size: 16,
                      color: widget.message.read ? Colors.blue : Colors.black54,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Method to get the local path where the document will be stored
Future<String> _getLocalDocumentPath(String documentUrl) async {
  // Get the file name from the URL
  String fileName = documentUrl.split('/').last;

  // Get the directory to store the document
  final directory = await getApplicationDocumentsDirectory();
  String filePath = '${directory.path}/cooig/documents/$fileName';

  return filePath;
}

//permissions for storage
// Method to download the document from Firebase Storage
Future<void> _downloadDocument(String firebaseUrl, String fileName) async {
  try {
    // Fetch the PDF from the provided URL

    final response = await http.get(Uri.parse(firebaseUrl));

    if (response.statusCode == 200) {
      // Get the Downloads directory
      final directory = await DownloadsPath.downloadsDirectory();

      if (directory != null) {
        // Construct the full file path in the Downloads directory
        final filePath = '${directory.path}/$fileName';

        // Write the downloaded file bytes to the specified path
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        Fluttertoast.showToast(
          msg: 'PDF saved successfully to Downloads: $filePath',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Downloads directory is not accessible.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to download PDF . Try Again ',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  } catch (e) {
    Fluttertoast.showToast(
      msg: 'Failed to download PDF . Try Again ',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}

/*
Future<void> _downloadDocument(String documentUrl, String localPath) async {
  try {
    var response = await Dio().download(documentUrl, localPath);

    if (response.statusCode == 200) {
      print('Document downloaded to: $localPath');
    } else {
      print('Failed to download document');
    }
  } catch (e) {
    print("Error downloading document: $e");
  }
}
*/
class AnimatedDot extends StatefulWidget {
  const AnimatedDot({super.key});

  @override
  _AnimatedDotState createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.grey,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AudioMessageWidget extends StatefulWidget {
  final String audioFilePath;
  final bool isSentByCurrentUser;
  final String duration; // Added: Accept pre-calculated duration

  const AudioMessageWidget({
    super.key,
    required this.audioFilePath,
    required this.isSentByCurrentUser,
    required this.duration, // Pass the pre-calculated duration here
  });

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  double _currentPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

//dynamically fetch duration of recorded audio // not imp
  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _playAudio() async {
    if (_isPlaying) {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentPosition = 0.0;
      });
    } else {
      await _player.startPlayer(
        fromURI: widget.audioFilePath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _currentPosition = 0.0;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isSentByCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        decoration: BoxDecoration(
          color:
              widget.isSentByCurrentUser ? Colors.black : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isSentByCurrentUser ? Colors.white : Colors.black,
              ),
              onPressed: _playAudio,
            ),
            SizedBox(width: 8.0),
            Text(
              widget.duration, // Use the passed duration directly
              style: TextStyle(
                color: widget.isSentByCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SwipeableContainer extends StatefulWidget {
  final Widget child;
  final bool isSentByCurrentUser;
  final Function(String replyPreview) onSwipeReply;
  final Message message; // Pass the message object

  const SwipeableContainer({
    super.key,
    required this.child,
    required this.isSentByCurrentUser,
    required this.onSwipeReply,
    required this.message, // Include message object
  });

  @override
  _SwipeableContainerState createState() => _SwipeableContainerState();
}

class _SwipeableContainerState extends State<SwipeableContainer> {
  double swipeOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Reply Icon Overlay
        if (swipeOffset > 0 && !widget.isSentByCurrentUser) // Received Message
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Icon(Icons.reply, color: Colors.grey),
          ),
        if (swipeOffset < 0 && widget.isSentByCurrentUser) // Sent Message
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Icon(Icons.reply, color: Colors.grey),
          ),

        // Gesture Detector Around MessageBubble
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              swipeOffset += details.delta.dx;
            });
          },
          onHorizontalDragEnd: (details) {
            if (swipeOffset.abs() > 50) {
              String replyPreview =
                  _getReplyPreview(widget.message); // Generate preview
              widget.onSwipeReply(replyPreview); // Trigger callback
            }
            setState(() {
              swipeOffset = 0.0; // Reset swipe offset
            });
          },
          child: Transform.translate(
            offset: Offset(swipeOffset, 0), // Translate the message bubble
            child: widget.child,
          ),
        ),
      ],
    );
  }

  String _getReplyPreview(Message message) {
    // Logic to generate reply preview text based on the message type
    switch (message.type) {
      case 'image':
        return 'Replying to image';
      case 'audio':
        return 'Replying to audio';
      case 'document':
        return 'Replying to document: ${message.msg}'; // Show file name
      default:
        return message.msg; // For text or other types
    }
  }
}

class AnimatedWaveBar extends StatefulWidget {
  final int index;

  const AnimatedWaveBar({super.key, required this.index});

  @override
  _AnimatedWaveBarState createState() => _AnimatedWaveBarState();
}

class _AnimatedWaveBarState extends State<AnimatedWaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 5, end: 15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height:
              widget.index.isEven ? _animation.value : _animation.value / 1.5,
          decoration: BoxDecoration(
            color: Colors.blueAccent, // Moving wave color
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

class StaticWaveBar extends StatelessWidget {
  final int index;

  const StaticWaveBar({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 3,
      height: 10 + (index % 5).toDouble(), // Static height
      decoration: BoxDecoration(
        color: Colors.grey.shade400, // Lighter color for static waves
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
