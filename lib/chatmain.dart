import 'dart:io';
import 'package:cooig_firebase/notice/noticeboard.dart';
import 'package:cooig_firebase/services/camera.dart';
import 'package:cooig_firebase/services/imagepreview.dart';
import 'package:cooig_firebase/services/videopreview.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'individual_chat_screen.dart';
import 'group_screen.dart';
import 'group_chat_screen.dart';
//import 'noticeboard.dart';
//import 'firebase_options.dart';

// ignore: camel_cas

class mainChat extends StatefulWidget {
  final String currentUserId;

  const mainChat({super.key, required this.currentUserId});

  @override
  State<mainChat> createState() => _mainChatState();
}

class _mainChatState extends State<mainChat> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Application',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF9752C5),
        // Removed global scaffoldBackgroundColor to allow screen-specific colors
        appBarTheme: AppBarTheme(
          color: Color(0xFF9752C5),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF9752C5),
          hintStyle: TextStyle(color: Colors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(
            currentUserId: widget.currentUserId), // Pass currentUserId
        '/individual_chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic>) {
            return IndividualChatScreen(
              currentUserId: args['currentUserId'] ?? 'default_user_id',
              chatUserId: args['chatUserId'] ?? 'default_chat_user_id',
              fullName: args['fullName'],
              image: args['image'],
              backgroundColor: args['backgroundColor'] ?? Colors.black,
            );
          } else {
            throw Exception("Invalid arguments for IndividualChatScreen");
          }
        },
        '/group_screen': (context) => GroupScreen(),
        '/group_chat': (context) => GroupChatScreen(),
        '/noticeboard': (context) => Noticeboard(),
        '/camera': (context) => CameraScreen(),
        '/imageOptions': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic>) {
            return ImagePreviewScreen(
              imageUrl: args['imageUrl'] ?? '',
              imageFiles: args['imageFiles'] ?? [],
            );
          } else {
            throw Exception("Invalid arguments for ImagePreviewScreen");
          }
        },
        '/videoOptions': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic> && args['videoFile'] is File) {
            return VideoPreviewScreen(videoFile: args['videoFile'] as File);
          } else {
            throw Exception("Invalid arguments for VideoPreviewScreen");
          }
        },
      },
    );
  }
}
