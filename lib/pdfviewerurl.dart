import 'dart:io';

//import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'dart:typed_data';

//import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';

class PDFViewerFromUrl extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const PDFViewerFromUrl(
      {super.key, required this.pdfUrl, required this.fileName});

  @override
  State<PDFViewerFromUrl> createState() => _PDFViewerFromUrlState();
}

class _PDFViewerFromUrlState extends State<PDFViewerFromUrl> {
  Uint8List? _pdfData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        setState(() {
          _pdfData = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load PDF: ${response.statusCode}';
          _isLoading = false;
        });
        print('HTTP Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF: $e';
        _isLoading = false;
      });
      print('Error loading PDF: $e');
    }
  }

  Future<void> _downloadPdf(String firebaseUrl, String fileName) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Uri.parse(widget.fileName).pathSegments.last),
        actions: [
          IconButton(
            onPressed: _pdfData != null
                ? () => _downloadPdf(widget.pdfUrl, widget.fileName)
                : null,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _pdfData != null
                  ? PDFView(
                      pdfData: _pdfData!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageFling: false,
                      onError: (error) {
                        print('PDFView Error: $error');
                        setState(() {
                          _errorMessage = 'PDFView Error: $error';
                        });
                      },
                      onRender: (pages) {
                        Fluttertoast.showToast(
                          msg: 'Pdf rendered with $pages pages',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      },
                    )
                  : const Center(child: Text("Unknown Error")),
    );
  }
}

// Example usage:
