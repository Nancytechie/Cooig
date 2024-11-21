import 'package:flutter/material.dart';

class SolidColorWallpapers extends StatefulWidget {
  final Function(Color) onColorSelected; // Callback for selected color

  SolidColorWallpapers({required this.onColorSelected});

  @override
  _SolidColorWallpapersState createState() => _SolidColorWallpapersState();
}

class _SolidColorWallpapersState extends State<SolidColorWallpapers> {
  Color? selectedColor; // Store the temporarily selected color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Solid Color'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 3, // Display 3 options per row
              padding: EdgeInsets.all(10.0),
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              children: _buildColorOptions(), // Build color options
            ),
          ),
          if (selectedColor !=
              null) // Show the tick icon only when a color is selected
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onColorSelected(selectedColor!); // Confirm selection
                  Navigator.pop(context); // Close the screen
                },
                icon: Icon(Icons.check),
                label: Text("Confirm"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: selectedColor, // Text color
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildColorOptions() {
    final colors = {
      Colors.black: 'Default',
      Colors.red: 'Red',
      Colors.blue: 'Blue',
      Colors.green: 'Green',
      Colors.yellow: 'Yellow',
      Colors.orange: 'Orange',
      Colors.purple: 'Purple',
      Colors.cyan: 'Cyan',
      Colors.pink: 'Pink',
      Colors.teal: 'Teal',
      Colors.indigo: 'Indigo',
      Colors.brown: 'Brown',
      Colors.grey: 'Grey',
    };

    return colors.entries.map((entry) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedColor = entry.key; // Temporarily store the selected color
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: entry.key,
            border: selectedColor == entry.key
                ? Border.all(
                    color: Colors.white, width: 3) // Highlight selected color
                : null,
          ),
          child: Center(
            child: Text(
              entry.value,
              style: TextStyle(
                color: entry.key == Colors.black ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
