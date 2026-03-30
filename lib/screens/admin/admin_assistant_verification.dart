import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/assistant.dart';
import '../../models/verification_file.dart';
import 'full_screen_file_viewer.dart';

class AdminAssistantVerificationPage extends StatelessWidget {
  final String uid;

  const AdminAssistantVerificationPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Verification Documents')),
            body: const Center(child: Text('Assistant not found')),
          );
        }

        final assistant = Assistant.fromFirestore(snapshot.data!);
        final assistantName = assistant.displayName ?? 'Unknown Assistant';

        return Scaffold(
          appBar: AppBar(title: Text('Verification Documents: $assistantName')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NIC / Identity Proof',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1.8,
                  child: _buildDocumentCard(
                    context,
                    file: VerificationFile(
                      url: assistant.nicProofImageUrl ?? '',
                      displayName: 'NIC / Identity Proof',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Other Certificates / Proofs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (assistant.proofDocumentsUrls.isEmpty)
                  const Text('No additional verification documents found.')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: assistant.proofDocumentsUrls.length,
                    itemBuilder: (context, index) {
                      final file = VerificationFile(
                        url: assistant.proofDocumentsUrls[index],
                        displayName: 'Supporting Document ${index + 1}',
                      );
                      return _buildDocumentCard(context, file: file);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(
    BuildContext context, {
    required VerificationFile file,
  }) {
    final title = file.displayName?.trim().isNotEmpty == true
        ? file.displayName!
        : 'Verification File';

    final bottomIcon = switch (file.type) {
      DocumentType.image => Icons.image,
      DocumentType.pdf => Icons.picture_as_pdf,
      DocumentType.other => Icons.insert_drive_file,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: file.url.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenFileViewer(file: file),
                  ),
                );
              },
        child: Column(
          children: [
            Expanded(
              child: file.url.isEmpty
                  ? Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: const Text('No document uploaded'),
                    )
                  : file.type == DocumentType.image
                  ? Image.network(
                      file.url,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 32,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Preview unavailable',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            file.type == DocumentType.pdf
                                ? Icons.picture_as_pdf
                                : Icons.insert_drive_file,
                            size: 40,
                            color: file.type == DocumentType.pdf
                                ? Colors.red
                                : Colors.grey,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Preview unavailable',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(bottomIcon, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
