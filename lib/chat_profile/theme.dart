import 'package:flutter/material.dart';
import 'solid_color_wallpapers.dart'; // Import the Solid color theme screen

class ThemeSelectionScreen extends StatefulWidget {
  final Function(Color) onThemeSelected; // Callback to update the background color

  ThemeSelectionScreen({required this.onThemeSelected});

  @override
  _ThemeSelectionScreenState createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  Color _selectedColor = Colors.black; // Default color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Theme'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back without selecting a color
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(10.0),
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SolidColorWallpapers(
                          onColorSelected: (Color selectedColor) {
                            setState(() {
                              _selectedColor =
                                  selectedColor; // Update the local color
                            });
                            widget.onThemeSelected(selectedColor); // Notify parent
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.blue,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.color_lens, size: 50, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'Solid Colors',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Future: Add other options like gallery or light/dark theme.
              ],
            ),
          ),
        ],
      ),
      // backgroundColor: _selectedColor, // Apply the selected color as background
    );
  }
}
