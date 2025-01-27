import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerScreen extends StatelessWidget {
  final File file;

  const PDFViewerScreen({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path.split('/').last),
      ),
      body: FutureBuilder(
        future: File(file.path).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.data!) {
            return const Center(child: Text('Failed to load PDF file.'));
          }
          return PDFView(
            filePath: file.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: false,
            onError: (error) {
              print('PDFView Error: $error');
            },
            onRender: (pages) {
              print('PDF Rendered with $pages pages');
            },
          );
        },
      ),
    );
  }
}
