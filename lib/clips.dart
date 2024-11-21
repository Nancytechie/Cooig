import 'dart:typed_data';

import 'package:cooig_firebase/MusicSelectionScreen.dart';
import 'package:cooig_firebase/filters.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For json and utf8
import 'package:just_audio/just_audio.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class ClipsScreen extends StatefulWidget {
  final CameraLensDirection cameraLensDirection;

  const ClipsScreen({super.key, required this.cameraLensDirection});

  @override
  _ClipsScreenState createState() => _ClipsScreenState();
}

class _ClipsScreenState extends State<ClipsScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _text = '';
  final double _fontSize = 24.0;
  Color _textColor = Colors.white;
  Offset _textPosition = const Offset(100, 100);
  final double _scale = 1.0;
  String _selectedFont = 'Normal';
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _pictureTaken = false;
  final bool _showFilters = false; // Toggle for filter display
  int _selectedFilterIndex = 0;
  String? _selectedLayout;
  String? _selectedTrack; // Store the selected music track
  List<Map<String, dynamic>> _spotifyTracks = [];
  double _sliderFontSize = 24.0;
  bool _showTextCustomization = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  List<File?> _collageImages = [];
  final GlobalKey _collageKey = GlobalKey();
  bool _isCollageCaptured = false;
  File? _capturedCollage;
  Uint8List? _filteredImage;

// To store the captured collage image

  // Add FocusNode

  // Default font size for slider control

  // FlutterSoundPlayer instance
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false; // Holds the fetched Spotify tracks
  final List<String> _fonts = ['Normal', 'Elegant', 'Cute', 'Handwriting'];

  // List of filters
  final List<String> _filters = [
    'Smile',
    'Sunglasses',
    'Funny Face',
    'Sad',
    'Cool'
  ];

  @override
  void initState() {
    super.initState();
    _collageImages = List<File?>.filled(4, null);
    _initializeCamera();
    _fetchSpotifyMusic();
    _textController.text = ''; // Initialize the text as empty

    // Add a listener to dynamically handle the placeholder
    _textController.addListener(() {
      if (_textController.text.isEmpty && !_textFocusNode.hasFocus) {
        setState(() {
          _textController.text = 'Enter your text...';
          _textController.selection = const TextSelection.collapsed(offset: 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _player.dispose();
    _textController.dispose(); // Dispose the text controller
    _textFocusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    CameraDescription cameraDescription;

    if (widget.cameraLensDirection == CameraLensDirection.front) {
      cameraDescription = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);
    } else {
      cameraDescription = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back);
    }

    _cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    await _cameraController?.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _fetchSpotifyMusic() async {
    const String clientId = '5ad3ac6e91e64df59f6949998235db4e';
    const String clientSecret = 'cef0d6e7823e40bbacc5e335cf1afeb7';
    const String tokenUrl = 'https://accounts.spotify.com/api/token';

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final String accessToken = jsonResponse['access_token'];

      final tracksResponse = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M/tracks'), // Replace with your playlist
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (tracksResponse.statusCode == 200) {
        final tracksJson = json.decode(tracksResponse.body);
        setState(() {
          _spotifyTracks =
              (tracksJson['items'] as List).map<Map<String, dynamic>>((item) {
            return {
              'name': item['track']['name'],
              'artist': item['track']['artists'][0]['name'],
              'albumArtUrl': item['track']['album']['images'][0]['url'],
              'previewUrl': item['track']
                  ['preview_url'], // This is the URL for the preview
            };
          }).toList();
        });
      } else {
        print('Failed to fetch Spotify tracks: ${tracksResponse.statusCode}');
      }
    } else {
      print('Failed to get Spotify access token: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedLayout != null) {
          setState(() {
            _selectedLayout = null;
          });
          _showCollageOptions();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Create a Clip"),
          backgroundColor: Colors.purple,
        ),
        body: _pictureTaken ? _postClipScreen() : _clipCreationScreen(),
      ),
    );
  }

  // Clip creation screen with camera preview and filter options
  Widget _clipCreationScreen() {
    return Stack(
      children: [
        Positioned.fill(
          child: _isCameraInitialized
              ? Transform(
                  alignment: Alignment.center,
                  transform:
                      widget.cameraLensDirection == CameraLensDirection.front
                          ? (Matrix4.identity()..rotateY(math.pi))
                          : Matrix4.identity(),
                  child: CameraPreview(_cameraController!),
                )
              : Container(color: Colors.black),
        ),
        if (_selectedLayout != null)
          Positioned.fill(
            child: RepaintBoundary(
              key: _collageKey, // Assign the key
              child: _buildCollageGrid(), // Collage grid
            ),
          ),
        if (!_isCollageCaptured)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _cameraIcon(),
          ),
        if (_isCollageCaptured)
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _onDonePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: const Text("Done", style: TextStyle(fontSize: 18)),
            ),
          ),
        Positioned(
          top: 120,
          right: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _featureIcon(Icons.photo_library, "Gallery", _openGallery),
              _featureIcon(Icons.grid_on, "Collage", _showCollageOptions),
              _featureIcon(Icons.switch_camera, "Reverse", _reverseCamera),
              _featureIcon(
                  Icons.emoji_emotions, "AR Emoji", _openFiltersScreen),
            ],
          ),
        ),
        if (_showFilters)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _cameraAndFilters(),
          )
        else
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _cameraIcon(),
          ),
      ],
    );
  }

  void _onDonePressed() {
    if (_capturedCollage != null) {
      // Process the captured collage (e.g., save it, share it, or upload it)
      print('Collage finalized: ${_capturedCollage!.path}');
    }

    // Reset the state or navigate back
    setState(() {
      _isCollageCaptured = false;
      _selectedLayout = null;
      _capturedCollage = null;
    });
  }

  // A helper function to create a grid with dynamic rows and columns
  Widget _buildGridLayout(int rows, int columns) {
    return Positioned.fill(
      child: Column(
        children: List.generate(rows, (rowIndex) {
          return Expanded(
            child: Row(
              children: List.generate(columns, (colIndex) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  // Collage layout options with custom images and adjusted size
  void _showCollageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250, // Reduced height for the options
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Select Collage Layout",
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10), // Add some spacing
              Expanded(
                child: SingleChildScrollView(
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable GridView scroll
                    childAspectRatio:
                        1.2, // Adjust the size of the grid items (1.2 for smaller)
                    padding: const EdgeInsets.all(10),
                    children: [
                      _collageOption('assets/images/layout1.png', 'layout1',
                          9), // 3x3 grid
                      _collageOption('assets/images/layout2.png', 'layout2',
                          4), // 2x2 grid
                      _collageOption(
                          'assets/images/layout3.png', 'layout3', 6), // Custom
                      _collageOption(
                          'assets/images/layout4.png', 'layout4', 5), // Custom
                      _collageOption(
                          'assets/images/layout5.png', 'layout5', 4), // Custom
                      _collageOption(
                          'assets/images/layout6.png', 'layout6', 2), // Custom
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Collage option widget with image
  void _setCollageLayout(String layout, int numberOfBlocks) {
    setState(() {
      _selectedLayout = layout;

      // Dynamically adjust the collage image list size
      _collageImages = List<File?>.filled(numberOfBlocks, null);
    });
  }

  Widget _collageOption(String imagePath, String layout, int numberOfBlocks) {
    return GestureDetector(
      onTap: () {
        _setCollageLayout(layout, numberOfBlocks); // Set the selected layout
        Navigator.pop(context); // Close the modal
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Image.asset(
              imagePath, // Load the custom image
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // Build collage grid layout based on selected option
  Widget _buildCollageGrid() {
    int blockIndex = 0; // Track the current block index
    switch (_selectedLayout) {
      case 'layout1':
        // A 3x3 grid (9 small squares)
        return _buildCustomGrid([
          [1, 1, 1],
          [1, 1, 1],
          [1, 1, 1],
        ]);

      case 'layout2':
        // A 2x2 grid (4 equal squares)
        return _buildCustomGrid([
          [1, 1],
          [1, 1],
        ]);

      case 'layout3':
        // Left block takes 2/3 of the width, right side splits vertically
        return Row(
          children: [
            Expanded(
              flex: 2, // Left block takes 2/3 of the width
              child: GestureDetector(
                onTap: () async {
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _collageImages[0] =
                          File(image.path); // Assign to left block
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    image: _collageImages[0] != null
                        ? DecorationImage(
                            image: FileImage(_collageImages[0]!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border:
                        Border.all(color: Colors.white, width: 0), // No gaps
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1, // Right side takes 1/3 of the width
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _collageImages[1] =
                                File(image.path); // Top-right block
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          image: _collageImages[1] != null
                              ? DecorationImage(
                                  image: FileImage(_collageImages[1]!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                              color: Colors.white, width: 0), // No gaps
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _collageImages[2] =
                                File(image.path); // Bottom-right block
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          image: _collageImages[2] != null
                              ? DecorationImage(
                                  image: FileImage(_collageImages[2]!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                              color: Colors.white, width: 0), // No gaps
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'layout4':
        // Top block takes 75% of the height, bottom row splits into two blocks
        return Column(
          children: [
            Expanded(
              flex: 3, // Top block takes 75% of the height
              child: GestureDetector(
                onTap: () async {
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _collageImages[0] =
                          File(image.path); // Assign to top block
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    image: _collageImages[0] != null
                        ? DecorationImage(
                            image: FileImage(_collageImages[0]!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border:
                        Border.all(color: Colors.white, width: 0), // No gaps
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1, // Bottom row takes 25% of the height
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _collageImages[1] =
                                File(image.path); // Bottom-left block
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          image: _collageImages[1] != null
                              ? DecorationImage(
                                  image: FileImage(_collageImages[1]!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                              color: Colors.white, width: 0), // No gaps
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _collageImages[2] =
                                File(image.path); // Bottom-right block
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          image: _collageImages[2] != null
                              ? DecorationImage(
                                  image: FileImage(_collageImages[2]!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                              color: Colors.white, width: 0), // No gaps
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'layout5':
        // Two 50-50 blocks horizontally
        return _buildCustomGrid([
          [1],
          [1],
        ]);

      case 'layout6':
        // Two 50-50 blocks vertically
        return _buildCustomGrid([
          [1, 1],
        ]);

      default:
        return Container(); // Default case when no layout is selected
    }
  }

  // Custom Grid layout function with dynamic image placeholder support
  Widget _buildCustomGrid(List<List<int>> gridStructure) {
    int blockIndex = 0; // Keep track of the current block index
    return Column(
      children: gridStructure.map((rowStructure) {
        return Expanded(
          child: Row(
            children: rowStructure.map((colSpan) {
              if (blockIndex >= _collageImages.length) return Container();
              int currentIndex = blockIndex++;
              return Expanded(
                flex: colSpan,
                child: GestureDetector(
                  onTap: () async {
                    final XFile? image =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        _collageImages[currentIndex] = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      image: _collageImages[currentIndex] != null
                          ? DecorationImage(
                              image: FileImage(_collageImages[currentIndex]!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border:
                          Border.all(color: Colors.white, width: 0), // No gaps
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // Display the selected layout full-screen after user selects a layout
  Widget _displaySelectedCollageLayout() {
    if (_selectedLayout != null) {
      return Scaffold(
        body: Stack(
          children: [
            _buildCollageGrid(), // Show grid based on the selected layout
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  // Action to finalize the collage
                  _saveCollage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
                child: const Text("Done", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      );
    }
    return Container(); // Return empty if no layout is selected
  }

  // Function to save collage or proceed with further action
  void _saveCollage() {
    // Handle saving or processing the final collage
  }

  // Camera icon with a purple ring
  Widget _cameraIcon() {
    return Center(
      child: GestureDetector(
        onTap: _captureImage,
        child: const CircleAvatar(
          radius: 47, // Outer purple ring size (Reduced size)
          backgroundColor: Colors.purple,
          child: CircleAvatar(
            radius: 43, // Slimmer inner white circle
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  // Camera and filter options in a slidable manner
  Widget _cameraAndFilters() {
    PageController pageController = PageController(viewportFraction: 0.3);

    return SizedBox(
      height: 100, // Reduced height for smaller filters
      child: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length + 1, // +1 for the camera
        itemBuilder: (context, index) {
          bool isSelected = index == _selectedFilterIndex;
          if (index == 0) {
            // Camera
            return _buildCamera(isSelected);
          } else {
            // Filters
            return _buildFilterIcon(_filters[index - 1], isSelected);
          }
        },
        onPageChanged: (index) {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
      ),
    );
  }

  // Camera icon for sliding with filters
  Widget _buildCamera(bool isSelected) {
    return GestureDetector(
      onTap: _captureImage,
      child: Transform.scale(
        scale: isSelected ? 1 : 0.8, // Scale the selected item
        child: const CircleAvatar(
          radius: 0.1, // Outer purple ring size
          backgroundColor: Colors.purple,
          child: CircleAvatar(
            radius: 43, // Thinner inner white circle size
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  // Filter icon widget
  Widget _buildFilterIcon(String filter, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = _filters.indexOf(filter) + 1; // +1 for camera
        });
      },
      child: Transform.scale(
        scale: isSelected ? 1 : 0.8, // Scale the selected item
        child: const CircleAvatar(
          radius: 20, // Smaller radius for filters
          backgroundColor: Colors.purpleAccent,
          child: Icon(Icons.emoji_emotions,
              color: Colors.white, size: 18), // Reduced icon size
        ),
      ),
    );
  }

  // Collage feature with three layout options

  // Post creation screen after capturing an image
  void _addTextFeature() {
    setState(() {
      _showTextCustomization = true; // Show text customization options
      _textFocusNode.requestFocus(); // Focus on the text field
    });
  }

  Widget _postClipScreen() {
    final trashBinPosition = Offset(
      MediaQuery.of(context).size.width - 40, // Center X of trash bin
      MediaQuery.of(context).size.height - 40, // Center Y of trash bin
    );
    const proximityThreshold = 10.0; // 1cm equivalent in Flutter logical pixels

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: _selectedImage == null
              ? Container(color: Colors.black)
              : Image.file(_selectedImage!, fit: BoxFit.cover),
        ),

        // Feature icons on the right
        Positioned(
          top: 120,
          right: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _featureIcon(Icons.music_note, "Music", _addMusic),
              _featureIcon(Icons.text_fields, "Text", _addTextFeature),
              _featureIcon(Icons.emoji_emotions, "Stickers", _addStickers),
              _featureIcon(Icons.location_on, "Location", _addLocation),
            ],
          ),
        ),

        // Movable and Editable Text
        if (_showTextCustomization)
          Stack(
            children: [
              // Draggable Text
              Positioned(
                left: _textPosition.dx,
                top: _textPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _textPosition += details.delta; // Update text position

                      // Check if text is near the trash bin
                      final distance =
                          (_textPosition - trashBinPosition).distance;
                      if (distance < proximityThreshold) {
                        _text = ''; // Delete text
                        _showTextCustomization = false; // Hide customization
                      }
                    });
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textController.text.isEmpty
                            ? Colors.grey
                            : _textColor,
                        fontSize: _sliderFontSize,
                        fontFamily: _selectedFont == 'Elegant'
                            ? 'Cursive'
                            : _selectedFont == 'Cute'
                                ? 'Pacifico'
                                : _selectedFont == 'Handwriting'
                                    ? 'Itim'
                                    : null,
                        fontStyle: _textController.text.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter your text...',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _text = value; // Update the text dynamically
                        });
                      },
                    ),
                  ),
                ),
              ),

              // Trash Bin
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4.0)
                    ],
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),

        // Text Customization Options
        if (_showTextCustomization)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Color Picker
                IconButton(
                  icon: Icon(Icons.color_lens, color: _textColor),
                  onPressed: () async {
                    Color? color = await _pickColor(context);
                    if (color != null) {
                      setState(() {
                        _textColor = color;
                      });
                    }
                  },
                ),

                // Font Selection
                DropdownButton<String>(
                  value: _selectedFont,
                  items: _fonts.map((font) {
                    return DropdownMenuItem(
                      value: font,
                      child: Text(font),
                    );
                  }).toList(),
                  onChanged: (font) {
                    setState(() {
                      _selectedFont = font!;
                    });
                  },
                ),

                // Font Size Slider
                Expanded(
                  child: Slider(
                    min: 12.0,
                    max: 72.0,
                    value: _sliderFontSize,
                    onChanged: (newValue) {
                      setState(() {
                        _sliderFontSize = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<Color?> _pickColor(BuildContext context) async {
    Color tempColor = _textColor;
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _textColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              showLabel: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                Navigator.of(context).pop(tempColor);
              },
            ),
          ],
        );
      },
    );
  }

  void _addMusic() {
    if (_selectedImage != null) {
      // Ensure you have an image to pass
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MusicSelectionScreen(
            spotifyTracks: _spotifyTracks,
            onMusicSelected: (String previewUrl, Map<String, dynamic> track) {
              setState(() {
                _selectedTrack = previewUrl;
                print('Selected Track: $_selectedTrack');
                _toggleMusicPlayback();
              });
            },
            capturedImage: _selectedImage!, // Pass the captured image file here
          ),
        ),
      );
    } else {
      print('No image selected to add music.');
      // You can show a message or prompt the user to capture/select an image
    }
  }

  void _toggleMusicPlayback() async {
    if (_selectedTrack != null) {
      if (_isPlaying) {
        await _player.stop();
      } else {
        await _player.setUrl(_selectedTrack!);
        await _player.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  // Capture the image when the camera or filter circle is clicked
  // Capture the image when the camera icon is clicked
  void _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        // Capture the image and save it as a file
        XFile image = await _cameraController!.takePicture();

        // Check if the camera is front-facing
        if (widget.cameraLensDirection == CameraLensDirection.front) {
          // Flip the image horizontally
          final originalImage = await File(image.path).readAsBytes();
          final decodedImage = img.decodeImage(originalImage);
          final flippedImage = img.flipHorizontal(decodedImage!);

          // Save the flipped image
          final flippedImagePath =
              '${(await getTemporaryDirectory()).path}/flipped_${DateTime.now().millisecondsSinceEpoch}.png';
          final flippedImageFile = File(flippedImagePath);
          await flippedImageFile.writeAsBytes(img.encodePng(flippedImage));

          setState(() {
            _selectedImage = flippedImageFile; // Save the flipped image
          });
        } else {
          // Save the captured image as it is for the back camera
          setState(() {
            _selectedImage = File(image.path); // Save the captured image
          });
        }

        setState(() {
          _pictureTaken = true; // Update to show the post clip screen
        });
      } catch (e) {
        print('Error capturing image: $e');
      }
    }
  }

  // Reverse camera functionality
  void _reverseCamera() {
    if (_cameraController != null) {
      CameraLensDirection newDirection =
          widget.cameraLensDirection == CameraLensDirection.front
              ? CameraLensDirection.back
              : CameraLensDirection.front;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClipsScreen(cameraLensDirection: newDirection),
        ),
      );
    }
  }

  // Show AR filters when the AR Emoji button is clicked
  void _openFiltersScreen() {
    if (_selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FiltersScreen(
            selectedImage: _selectedImage!,
            onFilterApplied: (Uint8List filteredImage) {
              setState(() {
                _filteredImage = filteredImage;
                _pictureTaken = true;
              });
            },
          ),
        ),
      );
    } else {
      print("No image available to apply filters.");
    }
  }

  // Placeholder functions for features
  void _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _addText() {
    // Implement text addition with font and color options (Placeholder)
  }

  void _addStickers() {
    // Implement stickers and GIFs addition (Placeholder)
  }

  void _addLocation() {
    // Implement location tag addition (Placeholder)
  }

  // Feature icon widget
  Widget _featureIcon(IconData icon, String label, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
