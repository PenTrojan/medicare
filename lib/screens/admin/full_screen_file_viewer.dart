import 'package:flutter/material.dart';

import '../../models/verification_file.dart';

class FullScreenFileViewer extends StatelessWidget {
  final VerificationFile file;

  const FullScreenFileViewer({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          file.displayName?.trim().isNotEmpty == true
              ? file.displayName!
              : 'File Viewer',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await file.downloadFile();
            },
            icon: const Icon(Icons.file_download),
            tooltip: 'Download',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (file.type) {
      case DocumentType.image:
        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: Image.network(
              file.url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Unable to load image.'));
              },
            ),
          ),
        );
      case DocumentType.pdf:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'PDF Preview Unavailable',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text('Please click the download button above to view.'),
              ],
            ),
          ),
        );
      case DocumentType.other:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file, size: 80, color: Colors.blueGrey),
                SizedBox(height: 16),
                Text(
                  'Preview Unavailable',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text('Please click the download button above to view.'),
              ],
            ),
          ),
        );
    }
  }
}
