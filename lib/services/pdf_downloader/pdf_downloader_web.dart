import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveOrDownloadPdf(Uint8List bytes, String filename) async {
  _download(bytes, filename, 'application/pdf');
}

Future<void> saveOrDownloadPng(Uint8List bytes, String filename) async {
  _download(bytes, filename, 'image/png');
}

void _download(Uint8List bytes, String filename, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
