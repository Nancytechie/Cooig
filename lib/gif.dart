import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';

class GifScreen extends StatefulWidget {
  const GifScreen({super.key});

  @override
  _GifScreenState createState() => _GifScreenState();
}

class _GifScreenState extends State<GifScreen> {
  GiphyGif? _selectedGif;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a GIF"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  // Debug log for button click
                  debugPrint("GIF button clicked");

                  // Open Giphy picker
                  GiphyGif? gif = await GiphyGet.getGif(
                    context: context,
                    apiKey: 'n2TYHzIqKZMO5Gz1LFROxFLjbxFiKF90', // Your API key
                    lang: GiphyLanguage.english,
                    modal: true, // Open as a modal
                  );

                  // Set selected GIF state
                  if (gif != null) {
                    setState(() {
                      _selectedGif = gif;
                    });

                    // Notify user about selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GIF selected!')),
                    );
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Button background color
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 15), // Padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded button
                ),
              ),
              child: const Text(
                "Choose GIF",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            // Display the selected GIF or placeholder text
            _selectedGif != null
                ? Column(
                    children: [
                      Image.network(
                        _selectedGif!.images!.original!.url,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 10),
                      //Text(
                      //"GIF URL: ${_selectedGif!.images!.original!.url}",
                      //style:
                      //  const TextStyle(fontSize: 12, color: Colors.grey),
                      //textAlign: TextAlign.center,
                      //),
                    ],
                  )
                : const Text(
                    "No GIF selected",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
          ],
        ),
      ),
    );
  }
}
