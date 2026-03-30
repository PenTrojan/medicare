import 'package:url_launcher/url_launcher.dart';

enum DocumentType { image, pdf, other }

class VerificationFile {
  final String url;
  final String? displayName;

  const VerificationFile({required this.url, this.displayName});

  DocumentType get type {
    final normalized = url.toLowerCase().split('?').first.split('#').first;

    const imageExtensions = {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.heic',
      '.heif',
    };

    for (final ext in imageExtensions) {
      if (normalized.endsWith(ext)) {
        return DocumentType.image;
      }
    }

    if (normalized.endsWith('.pdf')) {
      return DocumentType.pdf;
    }

    return DocumentType.other;
  }

  Future<void> downloadFile() async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
