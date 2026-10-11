import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveOrDownloadPdf(Uint8List bytes, String filename) async {
  try {
    File? savedFile;
    // 1. Coba simpan ke folder Downloads publik Android
    if (Platform.isAndroid) {
      try {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (publicDownload.existsSync()) {
          final target = File('${publicDownload.path}/$filename');
          await target.writeAsBytes(bytes, flush: true);
          savedFile = target;
        }
      } catch (e) {
        debugPrint('Direct write to /storage/emulated/0/Download failed: $e');
      }
    }

    // 2. Fallback ke getDownloadsDirectory atau getApplicationDocumentsDirectory
    if (savedFile == null) {
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {}
      dir ??= await getApplicationDocumentsDirectory();
      final target = File('${dir.path}/$filename');
      await target.writeAsBytes(bytes, flush: true);
      savedFile = target;
    }

    debugPrint('PDF berhasil disimpan di: ${savedFile.path}');

    // 3. Tampilkan sistem Share sheet agar user bisa langsung membuka/menyimpan file
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(savedFile.path, mimeType: 'application/pdf', name: filename),
            ],
            text: 'Laporan Riwayat BMI FitLife',
          ),
        );
      } catch (e) {
        debugPrint('Share sheet error: $e');
      }
    }
  } catch (e) {
    debugPrint('Gagal menyimpan PDF di platform mobile/desktop: $e');
    rethrow;
  }
}

Future<void> saveOrDownloadPng(Uint8List bytes, String filename) async {
  try {
    File? savedFile;
    // 1. Coba simpan ke folder Downloads publik Android
    if (Platform.isAndroid) {
      try {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (publicDownload.existsSync()) {
          final target = File('${publicDownload.path}/$filename');
          await target.writeAsBytes(bytes, flush: true);
          savedFile = target;
        }
      } catch (e) {
        debugPrint('Direct write to /storage/emulated/0/Download failed: $e');
      }
    }

    // 2. Fallback ke getDownloadsDirectory atau getApplicationDocumentsDirectory
    if (savedFile == null) {
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {}
      dir ??= await getApplicationDocumentsDirectory();
      final target = File('${dir.path}/$filename');
      await target.writeAsBytes(bytes, flush: true);
      savedFile = target;
    }

    debugPrint('PNG berhasil disimpan di: ${savedFile.path}');

    // 3. Tampilkan sistem Share sheet agar user bisa langsung membuka/menyimpan ke galeri
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(savedFile.path, mimeType: 'image/png', name: filename),
            ],
            text: 'Kartu Riwayat BMI FitLife',
          ),
        );
      } catch (e) {
        debugPrint('Share sheet error: $e');
      }
    }
  } catch (e) {
    debugPrint('Gagal menyimpan PNG di platform mobile/desktop: $e');
    rethrow;
  }
}
