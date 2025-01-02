// ignore_for_file: library_private_types_in_public_api, prefer_final_fields

import 'dart:io';

//import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooig_firebase/gif.dart';
//import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/mapscreen.dart';
import 'package:cooig_firebase/poll.dart';
import 'package:cooig_firebase/postpage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class PostScreen extends StatefulWidget {
  final String userId;
  const PostScreen({super.key, required this.userId});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final ImagePicker _picker = ImagePicker();
  final player = AudioPlayer();
  final TextEditingController _postController = TextEditingController();
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double sliderValue = 0.0;

  String fileNameWithoutExtension(String filePath) {
    var fileName = filePath.split('/').last; // Get the last part of the path
    var parts = fileName.split('.'); // Split by dot
    if (parts.length > 1) {
      parts.removeLast(); // Remove the extension
    }
    return parts.join('.'); // Join the remaining parts
  }

  @override
  void initState() {
    super.initState();
    player.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          position = pos;
          sliderValue = position.inSeconds.toDouble();
        });
      }
    });
    player.durationStream.listen((dur) {
      if (mounted) {
        setState(() {
          duration = dur ?? Duration.zero;
          if (duration != Duration.zero) {
            sliderValue = position.inSeconds.toDouble();
          }
        });
      }
    });
  }

  void _togglePlayPause() async {
    if (isPlaying) {
      await player.pause();
    } else {
      await player.seek(Duration(seconds: sliderValue.toInt()));
      await player.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _seek(double value) {
    player.seek(Duration(seconds: value.toInt()));
    setState(() {
      sliderValue = value;
    });
  }

  @override
  void dispose() {
    player.dispose();
    for (var controller in _videoControllers) {
      controller.dispose();
    }

    for (var controller in _chewieControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  List<XFile> _cameraImages = [];
  List<File> _galleryFiles = [];
  List<File> _documentFiles = [];
  List<File> _audioFiles = [];
  List<VideoPlayerController> _videoControllers = [];
  List<ChewieController> _chewieControllers = [];
  List<File> media = [];
  // List<Widget> _mediaWidgets = [];

  String _generatePostID() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<bool> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      return true; // Permission granted
    } else if (status.isDenied) {
      // Permission denied
      return false;
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, open app settings
      await openAppSettings();
      return false;
    }
    return false;
  }

  Future<String> _uploadFile(File file, String userID) async {
    try {
      // Get a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();

      // Create a reference to the location where the file will be stored
      final fileRef = storageRef.child('$userID/${basename(file.path)}');

      // Upload the file
      await fileRef.putFile(file);

      // Get the file's download URL
      return await fileRef.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('File upload failed');
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.camera);
    File imageFile = File(pickedImage!.path);

    setState(() {
      _cameraImages.add(pickedImage);
      media.add(imageFile);
    });

    // Replace 'userID' with the actual user's ID from authentication
  }

  Future<void> _pickFilesFromGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: true,
    );

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      // Clear existing video controllers
      for (var controller in _videoControllers) {
        controller.dispose();
      }
      _videoControllers.clear();
      for (var controller in _chewieControllers) {
        controller.dispose();
      }
      _chewieControllers.clear();

      // Add new gallery files
      setState(() {
        _galleryFiles.addAll(files);
        media.addAll(files);
      });
      for (var file in files) {
        if (file.path.endsWith('.mp4')) {
          VideoPlayerController videoController =
              VideoPlayerController.file(file);
          await videoController.initialize();
          ChewieController chewieController = ChewieController(
            videoPlayerController: videoController,
            aspectRatio: videoController.value.aspectRatio,
            autoPlay: true,
            looping: false,
          );
          setState(() {
            _videoControllers.add(videoController);
            _chewieControllers.add(chewieController);
          });
        }
      }
    }
  }

  Future<void> _pickAllFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _documentFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  Future<void> _pickaudioFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      await player.setFilePath(filePath);
      duration = player.duration ?? Duration.zero;
      if (mounted) {
        setState(() {
          _audioFiles = result.paths.map((path) => File(path!)).toList();

          sliderValue = 0.0;
          position = Duration.zero;
          isPlaying = false;
        });
      }
    }
  }

  Future<void> _onPostButtonClick() async {
    String postID = _generatePostID();
    List<String> mediaUrls = [];
    String posttext = _postController.text.trim();
    try {
      // Upload all media files and get their URLs
      for (var file in media) {
        String downloadUrl = await _uploadFile(file, widget.userId);
        mediaUrls.add(downloadUrl); // Collect the download URLs
      }

      // Save the post data to Firestore
      await FirebaseFirestore.instance
          .collection('posts_upload')
          .doc(postID)
          .set({
        'postID': postID,
        'userID': widget.userId,
        //'username': widget.username, // Replace with the actual username
        'timestamp': FieldValue.serverTimestamp(),
        'media': mediaUrls, // List of uploaded media URLs
        'text': posttext,
      });

      // Clear media and reset state after successful upload
      setState(() {
        media.clear();
        _cameraImages.clear();
        _galleryFiles.clear();
        _audioFiles.clear();
        _postController.clear();
      });

      Fluttertoast.showToast(msg: "Post uploaded successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error uploading post: $e");
      print(e);
    }
  }

  void _showLocationPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://via.placeholder.com/150'),
                    radius: 40,
                  ),
                  SizedBox(width: 20),
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://via.placeholder.com/150'),
                    radius: 40,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Allow access only this time'),
                    onTap: () async {
                      bool hasPermission = await _requestLocationPermission();
                      if (hasPermission) {
                        Navigator.pop(context); // Close the dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MapScreen()),
                        );
                      } else {
                        // Show some error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Location permission is required to access this feature.')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Always allow access'),
                    onTap: () {
                      // Handle access
                    },
                  ),
                  ListTile(
                    title: const Text('Don\'t allow access'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveToDrafts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save text
    await prefs.setString('draft_post_text', _postController.text);

    // Convert file paths to a string and save
    List<String> imagePaths = _cameraImages.map((file) => file.path).toList();
    List<String> galleryPaths = _galleryFiles.map((file) => file.path).toList();
    List<String> documentPaths =
        _documentFiles.map((file) => file.path).toList();
    List<String> audioPaths = _audioFiles.map((file) => file.path).toList();

    await prefs.setStringList('draft_camera_images', imagePaths);
    await prefs.setStringList('draft_gallery_files', galleryPaths);
    await prefs.setStringList('draft_document_files', documentPaths);
    await prefs.setStringList('draft_audio_files', audioPaths);
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Post'),
          content: const Text(
              'Would you like to save this post as a draft or delete it?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Save to Drafts'),
              onPressed: () async {
                await _saveToDrafts();
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double aspectRatio = 1.91 / 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            _showCancelDialog(context);
          },
          icon: const Icon(Icons.cancel_outlined),
          color: Colors.white,
        ),
        backgroundColor: Colors.black,
        actions: [
          ElevatedButton(
            onPressed: () {
              _onPostButtonClick();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostPage(userid: widget.userId)),
                );
              }
              //Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF635A8F), // Background color
              shape: const StadiumBorder(), // Pill-shaped button
            ),
            child: const Text('Post', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          // Add some spacing between the button and the right edge
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://via.placeholder.com/150'),
                    // Replace with user's profile picture
                    radius: 25,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: " What's on your mind ?",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _cameraImages.isNotEmpty
                  ? Wrap(
                      children: _cameraImages.map((image) {
                        return Container(
                          padding: const EdgeInsets.all(5),
                          child: AspectRatio(
                            aspectRatio: aspectRatio,
                            child: Image.file(
                              File(image.path),
                              width: screenWidth,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : Container(),
              _galleryFiles.isNotEmpty
                  ? Wrap(
                      children: _galleryFiles.map((file) {
                        if (file.path.endsWith('.mp4')) {
                          int index = _galleryFiles.indexOf(file);
                          if (index < _chewieControllers.length) {
                            return Container(
                              padding: const EdgeInsets.all(5),
                              child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: Chewie(
                                  controller: _chewieControllers[index],
                                ),
                              ),
                            );
                          }
                        } else if (file.path.endsWith('.jpg') ||
                            file.path.endsWith('.png')) {
                          return Container(
                            padding: const EdgeInsets.all(5),
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: Image.file(
                                file,
                                width: screenWidth,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        }
                        return Container(); // Handle other file types or skip
                      }).toList(),
                    )
                  : Container(),
              /*
              _galleryFiles.isNotEmpty
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _galleryFiles.map((file) {
                          if (file.path.endsWith('.mp4')) {
                            int index = _galleryFiles.indexOf(file);
                            if (index < _chewieControllers.length) {
                              return Container(
                                padding: const EdgeInsets.all(5),
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: Chewie(
                                    controller: _chewieControllers[index],
                                  ),
                                ),
                              );
                            }
                          } else if (file.path.endsWith('.jpg') ||
                              file.path.endsWith('.png')) {
                            return Container(
                              padding: const EdgeInsets.all(5),
                              child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: Image.file(
                                  file,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          }
                          return Container(); // Handle other file types or skip
                        }).toList(),
                      ),
                    )
                  : Container(),
              _documentFiles.isNotEmpty
                  ? Wrap(
                      children: _documentFiles.map((file) {
                        return Container(
                          padding: const EdgeInsets.all(5),
                          child: file.path.endsWith('.pdf') ||
                                  file.path.endsWith('.docx')
                              ? const Icon(Icons.picture_as_pdf,
                                  size: 20, color: Colors.red)
                              : file.path.endsWith('.mp4')
                                  ? const Icon(Icons.videocam,
                                      size: 100, color: Colors.grey)
                                  : Image.file(
                                      file,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                        );
                      }).toList(),
                    )
                  : Container(),*/
              _audioFiles.isNotEmpty
                  ? Wrap(
                      children: _audioFiles.map((file) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(5, 8, 5, 5),
                          height: 150,
                          width: 350,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(66, 247, 244, 248),
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(fileNameWithoutExtension(file.path)),
                              Slider(
                                min: 0.0,
                                value: sliderValue.clamp(
                                    0.0, duration.inSeconds.toDouble()),
                                max: duration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  _seek(value);
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatDuration(position)),
                                  Text(formatDuration(duration)),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow),
                                onPressed: _togglePlayPause,
                                color: const Color(0xFF635A8F),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black, // Set the background color of the FAB
        splashColor: Colors.blue,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                color: Colors.black, // Background color of the bottom sheet
                height: 200,
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildOptionIcon(
                        Icons.camera_alt, 'Camera', _pickImageFromCamera),
                    _buildOptionIcon(
                        Icons.photo, 'Gallery', _pickFilesFromGallery),
                    _buildOptionIcon(
                        Icons.insert_drive_file, 'Document', _pickAllFiles),
                    _buildOptionIcon(
                        Icons.audiotrack, 'Audio', _pickaudioFiles),
                    _buildOptionIcon(Icons.location_on, 'Location',
                        () => _showLocationPermissionsDialog(context)), //
                    _buildOptionIcon(Icons.poll, 'Poll', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyPollPage(
                                  userId: widget.userId,
                                )),
                      );
                    }),
                    _buildOptionIcon(Icons.mic, 'Voice', () {}),
                    _buildOptionIcon(Icons.gif, 'Gif', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GifScreen()),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
        child:
            const Icon(Iconsax.arrow_circle_up, color: Colors.white, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildOptionIcon(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black, // Set color to grey
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF635A8F)),
          ),
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }
}
