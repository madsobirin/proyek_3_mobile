import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/analisis_kesehatan_model.dart';
import '../../../services/kartu_kesehatan_export_service.dart';
import 'digital_health_card.dart';

class KartuKesehatanModal {
  static void show(BuildContext context, AnalisisKesehatan data) {
    final GlobalKey cardKey = GlobalKey();
    bool isExporting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111815),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SingleChildScrollView(
                  child: RepaintBoundary(
                    key: cardKey,
                    child: DigitalHealthCard(data: data),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF7F),
                          foregroundColor: const Color(0xFF090E0C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isExporting
                            ? null
                            : () async {
                                setModalState(() => isExporting = true);
                                final bytes = await KartuKesehatanExportService.captureWidgetToPng(cardKey);
                                setModalState(() => isExporting = false);

                                if (bytes != null && context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kartu Digital berhasil disimpan!'),
                                      backgroundColor: Color(0xFF1AB673),
                                    ),
                                  );
                                }
                              },
                        icon: isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.download_rounded, size: 20),
                        label: Text(
                          isExporting ? 'Memproses...' : 'Unduh Kartu (PNG)',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
