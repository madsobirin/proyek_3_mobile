import 'dart:typed_data';
import 'pdf_downloader_web.dart'
    if (dart.library.io) 'pdf_downloader_stub.dart';

Future<void> downloadPdf(Uint8List bytes, String filename) =>
    saveOrDownloadPdf(bytes, filename);

Future<void> downloadPng(Uint8List bytes, String filename) =>
    saveOrDownloadPng(bytes, filename);
