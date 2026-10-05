import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class KartuKesehatanExportService {
  /// Mengambil snapshot dari widget yang dibungkus RepaintBoundary menjadi byte PNG
  static Future<Uint8List?> captureWidgetToPng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // pixelRatio 3.0 menghasilkan gambar yang sangat tajam (retina quality)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Gagal capture kartu digital: $e");
      return null;
    }
  }
}
