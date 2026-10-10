import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/analisis_kesehatan_model.dart';
import '../../../services/kartu_kesehatan_export_service.dart';
import 'digital_health_card.dart';

class KartuKesehatanModal {
  static void show(
    BuildContext context,
    AnalisisKesehatan data, {
    bool isLoggedIn = false,
  }) {
    final GlobalKey cardKey = GlobalKey();
    bool isExporting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final maxHeight = MediaQuery.of(context).size.height * 0.90;

          // Helper: tampilkan snackbar jika belum login
          void _requireLogin() {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Silakan login terlebih dahulu untuk mengunduh kartu kesehatan.',
                ),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 3),
              ),
            );
          }

          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: const BoxDecoration(
              color: Color(0xFF111815),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Center(
                      child: RepaintBoundary(
                        key: cardKey,
                        child: DigitalHealthCard(data: data),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Baris tombol ──
                Row(
                  children: [
                    // ── Tombol Export PNG ──
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isExporting
                            ? null
                            : () async {
                                if (!isLoggedIn) {
                                  _requireLogin();
                                  return;
                                }
                                setModalState(() => isExporting = true);
                                final bytes =
                                    await KartuKesehatanExportService.captureWidgetToPng(
                                      cardKey,
                                    );
                                setModalState(() => isExporting = false);

                                if (bytes != null && context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kartu Digital (PNG) berhasil diambil!',
                                      ),
                                      backgroundColor: Color(0xFF1AB673),
                                    ),
                                  );
                                }
                              },
                        icon: isExporting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.image_outlined, size: 16),
                        label: Text(
                          'Export PNG',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── Tombol Export PDF ──
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
                                if (!isLoggedIn) {
                                  _requireLogin();
                                  return;
                                }
                                setModalState(() => isExporting = true);
                                final ok =
                                    await KartuKesehatanExportService.exportCardToPdf(
                                      data,
                                      filename:
                                          'Kartu-Kesehatan-${data.bmiDisplay}.pdf',
                                    );
                                setModalState(() => isExporting = false);

                                if (context.mounted) {
                                  if (ok) Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Dokumen PDF berhasil diunduh!'
                                            : 'Gagal membuat PDF. Coba lagi.',
                                      ),
                                      backgroundColor: ok
                                          ? const Color(0xFF1AB673)
                                          : Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                        icon: isExporting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 16,
                              ),
                        label: Text(
                          'Export PDF',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── Tombol Tutup ──
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
