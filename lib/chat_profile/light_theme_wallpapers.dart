import 'package:flutter/material.dart';

class LightThemeWallpapers extends StatefulWidget {
  @override
  _LightThemeWallpapersState createState() => _LightThemeWallpapersState();
}

class _LightThemeWallpapersState extends State<LightThemeWallpapers> {
  String? selectedWallpaper;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Light Wallpapers'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(10.0),
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        children: [
          buildWallpaperItem(context, 'assets/images/light_wallpaper1.jpg'),
          buildWallpaperItem(context, 'assets/images/light_wallpaper2.jpg'),
          buildWallpaperItem(context, 'assets/images/light_wallpaper3.jpg'),
          buildWallpaperItem(context, 'assets/images/light_wallpaper4.jpg'),
        ],
      ),
      floatingActionButton: selectedWallpaper != null
          ? FloatingActionButton(
              onPressed: () {
                // Add your 'Next' button logic here
                print('Next button pressed');
              },
              child: Icon(Icons.arrow_forward_ios),
              backgroundColor: Colors.purple,
            )
          : null,
    );
  }

  Widget buildWallpaperItem(BuildContext context, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWallpaper = imagePath;
        });
      },
      child: Card(
        shape: selectedWallpaper == imagePath
            ? RoundedRectangleBorder(
                side: BorderSide(color: Colors.blue, width: 3))
            : null,
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}