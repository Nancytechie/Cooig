// ignore_for_file: library_private_types_in_public_api, prefer_final_fields

import 'dart:io';
//import 'dart:io';
import 'package:cooig_firebase/PDFViewer.dart';
import 'package:cooig_firebase/audio.dart';
import 'package:cooig_firebase/home.dart';
import 'package:http/http.dart' as http;
//import 'package:http/http.dart' as http;
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
//import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:cooig_firebase/gif.dart';
//import 'package:cooig_firebase/home.dart';
import 'package:cooig_firebase/mapscreen.dart';
import 'package:cooig_firebase/poll.dart';
import 'package:cooig_firebase/postpage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
  GiphyGif? _selectedGif;

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
  List<GiphyGif> _selectedGifs = [];
  List<VideoPlayerController> _videoControllers = [];
  List<ChewieController> _chewieControllers = [];
  List<File> media = [];
  List<String> media2 = [];
  // List<Widget> _mediaWidgets = [];

  String _generatePostID() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<String> _uploadGifToFirebase(String gifUrl, String userId) async {
    try {
      // Download GIF from URL
      final response = await http.get(Uri.parse(gifUrl));
      if (response.statusCode == 200) {
        // Create a unique filename
        String fileName =
            'gifs/$userId/${DateTime.now().millisecondsSinceEpoch}.gif';

        // Upload to Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putData(
            response.bodyBytes, SettableMetadata(contentType: 'image/gif'));

        // Get the download URL
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        print("GIF uploaded: $downloadUrl");
        return downloadUrl;
      } else {
        throw Exception("Failed to download GIF");
      }
    } catch (e) {
      print("Error uploading GIF: $e");
      return "";
    }
  }

/*
  Future<String> _uploadGifToFirebase(String gifUrl, String userId) async {
    try {
      // Get temporary directory
      final tempDir = await DownloadsPath.downloadsDirectory();
      final tempFile = File('${tempDir?.path}/$gifUrl.gif');

      // Download GIF from URL
      final response = await http.get(Uri.parse(gifUrl));
      await tempFile.writeAsBytes(response.bodyBytes);

      // Upload to Firebase Storage
      String storagePath =
          'uploads/$userId/gifs/${DateTime.now().millisecondsSinceEpoch}.gif';
      UploadTask uploadTask =
          FirebaseStorage.instance.ref(storagePath).putFile(tempFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get Firebase URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading GIF: $e");
      throw e;
    }
  }
*/
  Future<File> _downloadGif(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final tempDir =
            await DownloadsPath.downloadsDirectory(); // Use safe directory
        final filePath =
            '${tempDir!.path}/selected_gif_${DateTime.now().millisecondsSinceEpoch}.gif';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return file;
      } else {
        throw Exception('Failed to download GIF');
      }
    } catch (e) {
      throw Exception('Error downloading GIF: $e');
    }
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
        media.addAll(_documentFiles);
      });

      // Navigate to the PDF viewer if only one file is selected and it's a PDF
      if (_documentFiles.length == 1 &&
          _documentFiles[0].path.endsWith('.pdf')) {
        Navigator.push(
          context as BuildContext,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(file: _documentFiles[0]),
          ),
        );
      }
    }
  }

/*
  Future<void> _pickGif(BuildContext context) async {
    try {
      debugPrint("GIF button clicked");
      List<GiphyGif> selectedGifs = [];
      bool addingGifs = true;

      while (addingGifs) {
        GiphyGif? gif = await GiphyGet.getGif(
          context: context,
          apiKey: 'n2TYHzIqKZMO5Gz1LFROxFLjbxFiKF90',
          lang: GiphyLanguage.english,
          modal: true,
        );

        if (gif != null) {
          selectedGifs.add(gif); // Add selected GIF to the list
        } else {
          addingGifs = false; // Stop adding if no GIF is selected
        }
      }

      if (!mounted) return; // Ensure widget is still mounted

      if (selectedGifs.isNotEmpty) {
        List<File> gifFiles = [];
        //List<String> gifUrls = [];

        for (var gif in selectedGifs) {
          String? gifUrl = gif.images?.original?.url;
          if (gifUrl != null) {
            // Download the GIF and save as a File
            File gifFile = await _downloadGif(gifUrl);
            gifFiles.add(gifFile);

            // Upload the GIF file to Firebase
          }
        }

        setState(() {
          media.addAll(gifFiles); // Add local GIF files to media list
          //media2.addAll(gifUrls); // Add uploaded URLs to media2 list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${selectedGifs.length} GIF(s) added to media!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No GIFs selected')),
        );
      }
    } catch (error) {
      debugPrint("Error selecting GIF: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
  */
  Future<void> _pickGif(BuildContext context) async {
    try {
      debugPrint("GIF button clicked");

      // Open Giphy GIF picker
      GiphyGif? selectedGif = await GiphyGet.getGif(
        context: context,
        apiKey: 'n2TYHzIqKZMO5Gz1LFROxFLjbxFiKF90',
        lang: GiphyLanguage.english,
        modal: true,
      );

      if (!mounted) return; // Ensure widget is still active

      if (selectedGif != null) {
        setState(() {
          _selectedGif = selectedGif; // Display selected GIF immediately
        });

        String? gifUrl = selectedGif.images?.original?.url;

        if (gifUrl != null) {
          // Download and store GIF as a file
          //File gifFile = await _downloadGif(gifUrl);
          print("The GIF Url : $gifUrl");
          setState(() {
            media2.add(gifUrl); // Add downloaded file to media list
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GIF added to media!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No GIF selected')),
        );
      }
    } catch (error) {
      debugPrint("Error selecting GIF: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
/*
  Future<void> _pickGif(BuildContext context) async {
    try {
      debugPrint("GIF button clicked");

      // Allow selection of only one GIF
      GiphyGif? selectedGif = await GiphyGet.getGif(
        context: context,
        apiKey: 'n2TYHzIqKZMO5Gz1LFROxFLjbxFiKF90',
        lang: GiphyLanguage.english,
        modal: true,
      );

      if (!mounted) return; // Ensure widget is still mounted

      if (selectedGif != null) {
        String? gifUrl = selectedGif.images?.original?.url;

        if (gifUrl != null) {
          // Optionally download and upload GIF to Firebase (if needed)
          File gifFile = await _downloadGif(gifUrl);

          setState(() {
            media.add(gifFile); // Add local GIF file to media list
            // Or directly store the URL if Firebase upload is not needed
            // media2.add(gifUrl);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GIF added to media!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to retrieve GIF URL')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No GIF selected')),
        );
      }
    } catch (error) {
      debugPrint("Error selecting GIF: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
*/
  /*
Future<void> _pickGif(BuildContext context) async {
  try {
    debugPrint("GIF button clicked");
    List<GiphyGif> selectedGifs = [];
    bool addingGifs = true;

    while (addingGifs) {
      GiphyGif? gif = await GiphyGet.getGif(
        context: context,
        apiKey: 'n2TYHzIqKZMO5Gz1LFROxFLjbxFiKF90',
        lang: GiphyLanguage.english,
        modal: true,
      );

      if (gif != null) {
        selectedGifs.add(gif); // Add selected GIF to the list
      } else {
        addingGifs = false; // Stop adding if no GIF is selected
      }
    }

    if (!mounted) return; // Ensure widget is still mounted

    if (selectedGifs.isNotEmpty) {
      List<File> gifFiles = [];

      for (var gif in selectedGifs) {
        String? gifUrl = gif.images?.original?.url;
        if (gifUrl != null) {
          File gifFile = await _downloadGif(gifUrl);
          gifFiles.add(gifFile); // Add the downloaded GIF file to the list
        }
      }

      setState(() {
        media.addAll(gifFiles); // Add GIF files to the media list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${selectedGifs.length} GIF(s) added to media!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No GIFs selected')),
      );
    }
  } catch (error) {
    debugPrint("Error selecting GIF: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }
}
*/

/*
  Future<void> _pickGif(BuildContext context) async {
  try {
    debugPrint("GIF button clicked");
    List<GiphyGif> selectedGifs = [];
    bool addingGifs = true;

    while (addingGifs) {
      GiphyGif? gif = await GiphyGet.getGif(
        context: context,
        apiKey: 'n2TYHzIqKZMO5Gz1LFROxFLjbxFiKF90',
        lang: GiphyLanguage.english,
        modal: true,
      );

      if (gif != null) {
        selectedGifs.add(gif);
      } else {
        addingGifs = false;
      }
    }

    if (!mounted) return;

    if (selectedGifs.isNotEmpty) {
      setState(() {
        for (var gif in selectedGifs) {
          media.add(gif.images!.original!.url); // Add GIF URL
          //gif!.images!.original!.url
          //_selectedGif!.images!.original!.url
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedGifs.length} GIF(s) selected!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No GIFs selected')),
      );
    }
  } catch (error) {
    debugPrint("Error selecting GIF: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }
}
*/
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
      for (String gifUrl in media2) {
        String gifFirebaseUrl =
            await _uploadGifToFirebase(gifUrl, widget.userId);
        mediaUrls.add(gifFirebaseUrl);
      }
      /*for (String i in media2) {
        //String downloadUrl = await _uploadFile(i, widget.userId);
        mediaUrls.add(i);
      }*/
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
        media2.clear();
        _selectedGif = null;
        _selectedGifs.clear();
        _cameraImages.clear();
        _galleryFiles.clear();
        _audioFiles.clear();
        _postController.clear();
        _documentFiles.clear();
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
                      builder: (context) => Homepage(userId: widget.userId)),
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
              _selectedGifs.isNotEmpty
                  ? Wrap(
                      children: _selectedGifs.map((gif) {
                        return Container(
                          padding: const EdgeInsets.all(5),
                          child: AspectRatio(
                            aspectRatio: aspectRatio,
                            child: Image.network(
                              gif.images?.original?.url ?? '',
                              width: screenWidth,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : Container(),*/
              _selectedGif != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(
                        _selectedGif!.images!.original!.url!,
                        width: screenWidth,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Text('Failed to load GIF'));
                        },
                      ),
                    )
                  : Container(),
              _documentFiles.isNotEmpty
                  ? Wrap(
                      children: _documentFiles.map((file) {
                        return GestureDetector(
                          onTap: () {
                            if (file.path.endsWith('.pdf')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PDFViewerScreen(file: file),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Cannot preview non-PDF files!')),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            width: 120,
                            height: 150,
                            child: file.path.endsWith('.pdf')
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.picture_as_pdf,
                                          size: 40, color: Colors.red),
                                      const SizedBox(height: 8),
                                      Text(
                                        file.path.split('/').last,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.description,
                                    size: 40,
                                    color:
                                        Colors.blue), // Placeholder for non-PDF
                          ),
                        );
                      }).toList(),
                    )
                  : Container(),
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
                    _buildOptionIcon(Icons.mic, 'Voice', () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => MicScreen()));
                    }),
                    _buildOptionIcon(Icons.gif, 'Gif', () => _pickGif(context)),
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