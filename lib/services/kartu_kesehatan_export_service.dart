import 'dart:typed_data';
import 'dart:ui' as ui;
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/analisis_kesehatan_model.dart';
import '../models/perhitungan_model.dart';
import 'pdf_downloader/pdf_downloader.dart';

// ── Palet Warna Resmi FitLife ──
const _primary = PdfColor.fromInt(0xFF00C864);
const _primaryDark = PdfColor.fromInt(0xFF00964B);
const _bgDark = PdfColor.fromInt(0xFF0F1714);
const _textDark = PdfColor.fromInt(0xFF1E1E1E);
const _textMuted = PdfColor.fromInt(0xFF787878);
const _borderLight = PdfColor.fromInt(0xFFDCDCDC);
const _bgLight = PdfColor.fromInt(0xFFF6FCF9);
const _white = PdfColors.white;

/// Mengunduh dokumen PDF secara langsung tanpa dialog print printer
Future<void> _openPdf(Uint8List pdfBytes, String filename) async {
  await downloadPdf(pdfBytes, filename);
}

class KartuKesehatanExportService {
  // ─────────────────────────────────────────────────────────
  // 1. CAPTURE PNG dari RepaintBoundary (tetap tersedia)
  // ─────────────────────────────────────────────────────────
  static Future<Uint8List?> captureWidgetToPng(GlobalKey boundaryKey) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Gagal capture PNG: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 2. EXPORT RIWAYAT → PNG via GlobalKey (isi = RiwayatHealthCard)
  //    Caller must embed an invisible RepaintBoundary in the widget tree
  // ─────────────────────────────────────────────────────────
  static Future<bool> captureAndDownloadPng(
    GlobalKey boundaryKey, {
    String filename = 'Riwayat-BMI-FitLife.png',
  }) async {
    try {
      final bytes = await captureWidgetToPng(boundaryKey);
      if (bytes == null) return false;
      await downloadPng(bytes, filename);
      return true;
    } catch (e) {
      debugPrint('Gagal unduh PNG: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 3. EXPORT KARTU INDIVIDUAL → PDF TABEL RESMI (PERSIS WEB)
  // ─────────────────────────────────────────────────────────
  static Future<bool> exportCardToPdf(
    AnalisisKesehatan data, {
    String filename = 'Kartu-Kesehatan-FitLife.pdf',
  }) async {
    try {
      final item = PerhitunganModel(
        tinggiBadan: data.tinggiBadan,
        beratBadan: data.beratBadan,
        bmi: data.bmi,
        status: data.status,
        gender: data.gender,
        usia: data.usia,
        aktivitas: data.aktivitas,
        bmr: data.bmr,
        tdee: data.tdee,
        targetKalori: data.tdee,
        beratMin: data.beratMin,
        beratMax: data.beratMax,
        protein: data.protein,
        karbohidrat: data.karbohidrat,
        lemak: data.lemak,
        createdAt: DateTime.now(),
      );

      return await exportRiwayatToPdf([item], filename: filename);
    } catch (e) {
      debugPrint('Gagal export kartu ke PDF: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 3. EXPORT RIWAYAT LENGKAP → PDF TABEL MULTI-PAGE
  //    100% IDENTIK DENGAN VERSI WEB (jsPDF + autoTable)
  // ─────────────────────────────────────────────────────────
  static Future<bool> exportRiwayatToPdf(
    List<PerhitunganModel> history, {
    String filename = 'Riwayat-BMI-FitLife.pdf',
  }) async {
    if (history.isEmpty) return false;

    try {
      final pdf = pw.Document();

      // Palet warna persis kode website (jsPDF)
      const primaryColor = PdfColor.fromInt(0xFF00C864); // [0, 200, 100]
      const primaryDarkColor = PdfColor.fromInt(0xFF00964B); // [0, 150, 75]
      const bgDarkColor = PdfColor.fromInt(0xFF0F1714); // [15, 23, 20]
      const textDarkColor = PdfColor.fromInt(0xFF1E1E1E); // [30, 30, 30]
      const textMutedColor = PdfColor.fromInt(0xFF787878); // [120, 120, 120]
      const borderLightColor = PdfColor.fromInt(0xFFDCDCDC); // [220, 220, 220]
      const bgLightColor = PdfColor.fromInt(0xFFF6FCF9); // [246, 252, 249]

      const monthNames = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      const monthShortNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      final sortedChrono = List<PerhitunganModel>.from(history)
        ..sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );

      final first = sortedChrono.isNotEmpty ? sortedChrono.first : null;
      final last = sortedChrono.isNotEmpty ? sortedChrono.last : null;
      final deltaBerat = (first != null && last != null)
          ? double.parse(
              (last.beratBadan - first.beratBadan).toStringAsFixed(1),
            )
          : 0.0;
      final avgBmi = sortedChrono.isNotEmpty
          ? double.parse(
              (sortedChrono.map((e) => e.bmi).reduce((a, b) => a + b) /
                      sortedChrono.length)
                  .toStringAsFixed(1),
            )
          : 0.0;

      final now = DateTime.now();
      final todayFormatted =
          '${now.day} ${monthNames[now.month - 1]} ${now.year}';

      // Baris tabel (terbaru di atas, sama seperti reverse() di web)
      final reversedItems = sortedChrono.reversed.toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw
              .EdgeInsets
              .zero, // Zero margin untuk full-width header & footer
          header: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. BANNER GELAP FULL WIDTH (32mm)
                pw.Container(
                  width: double.infinity,
                  height: 32 * PdfPageFormat.mm,
                  color: bgDarkColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14 * PdfPageFormat.mm,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Kiri: Judul & Subtitle
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Riwayat Perhitungan BMI',
                            style: pw.TextStyle(
                              color: _white,
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Laporan progres berat badan & indeks massa tubuh',
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFFB4C8BE),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      // Kanan: Dicetak & Total
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Dicetak: $todayFormatted',
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFFC8DCD2),
                              fontSize: 8,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Total: ${history.length} catatan',
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFFC8DCD2),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 2. GARIS AKSEN HIJAU (1.5mm)
                pw.Container(
                  width: double.infinity,
                  height: 1.5 * PdfPageFormat.mm,
                  color: primaryColor,
                ),
                pw.SizedBox(height: 8 * PdfPageFormat.mm),
              ],
            );
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              margin: const pw.EdgeInsets.symmetric(
                horizontal: 14 * PdfPageFormat.mm,
              ),
              padding: const pw.EdgeInsets.only(
                top: 5 * PdfPageFormat.mm,
                bottom: 7 * PdfPageFormat.mm,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: borderLightColor, width: 0.3),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dibuat dengan Kalkulator BMI | Konsultasikan dengan dokter untuk hasil yang lebih akurat',
                    style: const pw.TextStyle(
                      color: textMutedColor,
                      fontSize: 7.5,
                    ),
                  ),
                  pw.Text(
                    'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                    style: const pw.TextStyle(
                      color: textMutedColor,
                      fontSize: 7.5,
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14 * PdfPageFormat.mm,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // ── 3. TABEL RIWAYAT (Persis autoTable web) ──
                    pw.Table(
                      border: pw.TableBorder.all(
                        color: borderLightColor,
                        width: 0.1,
                      ),
                      columnWidths: const {
                        0: pw.FixedColumnWidth(12 * PdfPageFormat.mm),
                        1: pw.FixedColumnWidth(30 * PdfPageFormat.mm),
                        2: pw.FixedColumnWidth(22 * PdfPageFormat.mm),
                        3: pw.FixedColumnWidth(22 * PdfPageFormat.mm),
                        4: pw.FixedColumnWidth(18 * PdfPageFormat.mm),
                        5: pw.FixedColumnWidth(26 * PdfPageFormat.mm),
                        6: pw.FixedColumnWidth(24 * PdfPageFormat.mm),
                        7: pw.FixedColumnWidth(24 * PdfPageFormat.mm),
                      },
                      children: [
                        // Header Tabel
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: primaryColor,
                          ),
                          children: [
                            _webHeaderCell('No'),
                            _webHeaderCell('Tanggal'),
                            _webHeaderCell('Tinggi (cm)'),
                            _webHeaderCell('Berat (kg)'),
                            _webHeaderCell('BMI'),
                            _webHeaderCell('Status'),
                            _webHeaderCell('BMR'),
                            _webHeaderCell('TDEE'),
                          ],
                        ),
                        // Isi Tabel
                        ...reversedItems.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final item = entry.value;
                          final isOdd = entry.key % 2 == 1;

                          String dateStr = '-';
                          if (item.createdAt != null) {
                            final d = item.createdAt!;
                            final day = d.day.toString().padLeft(2, '0');
                            final month = monthShortNames[d.month - 1];
                            dateStr = '$day $month ${d.year}';
                          }

                          // Warna status sesuai website:
                          // Normal: [0, 150, 75]
                          // Kurus: [200, 150, 0]
                          // Berlebih: [220, 100, 50]
                          // Obesitas: [200, 50, 50]
                          PdfColor statusColor = textDarkColor;
                          if (item.status == 'Normal') {
                            statusColor = primaryDarkColor;
                          } else if (item.status == 'Kurus') {
                            statusColor = const PdfColor.fromInt(0xFFC89600);
                          } else if (item.status == 'Berlebih') {
                            statusColor = const PdfColor.fromInt(0xFFDC6432);
                          } else if (item.status == 'Obesitas') {
                            statusColor = const PdfColor.fromInt(0xFFC83232);
                          }

                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: isOdd ? bgLightColor : _white,
                            ),
                            children: [
                              _webBodyCell(
                                idx.toString(),
                                isBold: true,
                                color: textMutedColor,
                              ),
                              _webBodyCell(dateStr),
                              _webBodyCell(item.tinggiBadan.toStringAsFixed(0)),
                              _webBodyCell(item.beratBadan.toStringAsFixed(0)),
                              _webBodyCell(
                                item.bmi.toStringAsFixed(1),
                                isBold: true,
                                color: primaryDarkColor,
                              ),
                              _webBodyCell(
                                item.status,
                                isBold: true,
                                color: statusColor,
                              ),
                              _webBodyCell(
                                item.bmr > 0
                                    ? item.bmr.round().toString()
                                    : '-',
                              ),
                              _webBodyCell(
                                item.tdee > 0
                                    ? item.tdee.round().toString()
                                    : '-',
                              ),
                            ],
                          );
                        }),
                      ],
                    ),

                    pw.SizedBox(height: 12 * PdfPageFormat.mm),

                    // ── 4. SUMMARY CARDS DI BAWAH TABEL ──
                    if (history.length > 1) ...[
                      pw.Text(
                        'Ringkasan Progress',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: textDarkColor,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          _summaryCard(
                            'PROGRESS BERAT',
                            '${deltaBerat >= 0 ? '+' : ''}$deltaBerat kg',
                            deltaBerat < 0
                                ? primaryDarkColor
                                : deltaBerat > 0
                                ? const PdfColor.fromInt(0xFFC86432)
                                : textMutedColor,
                          ),
                          pw.SizedBox(width: 4 * PdfPageFormat.mm),
                          _summaryCard(
                            'RATA-RATA BMI',
                            avgBmi.toString(),
                            primaryDarkColor,
                          ),
                          pw.SizedBox(width: 4 * PdfPageFormat.mm),
                          _summaryCard(
                            'STATUS TERAKHIR',
                            last?.status ?? '-',
                            primaryDarkColor,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10 * PdfPageFormat.mm),
                    ],

                    // ── 5. REKOMENDASI ASUPAN MAKRONUTRIEN ──
                    if (last != null) ...[
                      pw.Text(
                        'Rekomendasi Asupan Makronutrien',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: textDarkColor,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          _summaryCard(
                            'PROTEIN',
                            '${last.proteinDisplay} g',
                            const PdfColor.fromInt(0xFF0284C7),
                          ),
                          pw.SizedBox(width: 4 * PdfPageFormat.mm),
                          _summaryCard(
                            'KARBOHIDRAT',
                            '${last.karbohidratDisplay} g',
                            const PdfColor.fromInt(0xFFB45309),
                          ),
                          pw.SizedBox(width: 4 * PdfPageFormat.mm),
                          _summaryCard(
                            'LEMAK',
                            '${last.lemakDisplay} g',
                            const PdfColor.fromInt(0xFFDC2626),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await _openPdf(pdfBytes, filename);
      return true;
    } catch (e) {
      debugPrint('Gagal export riwayat ke PDF: $e');
      return false;
    }
  }

  static pw.Widget _webHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 3.5 * PdfPageFormat.mm,
        horizontal: 2 * PdfPageFormat.mm,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _white,
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _webBodyCell(
    String text, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 3 * PdfPageFormat.mm,
        horizontal: 2 * PdfPageFormat.mm,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: color ?? _textDark,
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPER WIDGET PDF
  // ─────────────────────────────────────────────────────────

  static pw.Widget _infoChip(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: _bgLight,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: _borderLight, width: 0.5),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(color: _textMuted, fontSize: 7.5),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: _textDark,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _energyCard(
    String title,
    String val,
    String subtitle, {
    bool highlight = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: highlight ? PdfColor.fromInt(0xFFE6FFF2) : _bgLight,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(
            color: highlight ? _primary : _borderLight,
            width: highlight ? 0.8 : 0.5,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: highlight ? _primaryDark : _textMuted,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              val,
              style: pw.TextStyle(
                color: highlight ? _primary : _textDark,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(color: _textMuted, fontSize: 7),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        height: 24 * PdfPageFormat.mm,
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFAFCFB),
          borderRadius: const pw.BorderRadius.all(
            pw.Radius.circular(2 * PdfPageFormat.mm),
          ),
          border: pw.Border.all(color: _borderLight, width: 0.3),
        ),
        child: pw.Row(
          children: [
            pw.Container(
              width: 1.2 * PdfPageFormat.mm,
              height: 24 * PdfPageFormat.mm,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(2 * PdfPageFormat.mm),
                  bottomLeft: pw.Radius.circular(2 * PdfPageFormat.mm),
                ),
              ),
            ),
            pw.SizedBox(width: 3 * PdfPageFormat.mm),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 3 * PdfPageFormat.mm,
                  horizontal: 1 * PdfPageFormat.mm,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _textMuted,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      value,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: color ?? _textDark,
          fontSize: 9,
          fontWeight: color != null ? pw.FontWeight.bold : null,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _saranRow(String label, String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          height: 4,
          margin: const pw.EdgeInsets.only(top: 3.5, right: 6),
          decoration: const pw.BoxDecoration(
            color: _primary,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            color: _textDark,
            fontWeight: pw.FontWeight.bold,
            fontSize: 8.5,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(color: _textMuted, fontSize: 8.5),
          ),
        ),
      ],
    );
  }

  /// Saran aktivitas & gaya hidup berdasarkan status BMI
  static Map<String, String> _getSaran(String status) {
    switch (status) {
      case 'Kurus':
        return {
          'fokus': 'Meningkatkan massa otot & surplus kalori teratur.',
          'olahraga': 'Latihan beban 3-4x seminggu. Batasi kardio berlebih.',
          'nutrisi':
              'Tingkatkan porsi protein tinggi dan makanan padat nutrisi.',
        };
      case 'Berlebih':
        return {
          'fokus': 'Defisit kalori bertahap & pembakaran lemak aktif.',
          'olahraga': 'Kombinasi kardio 30-45 mnt 4x seminggu + angkat beban.',
          'nutrisi': 'Kurangi gula pasir dan gorengan. Perbanyak serat.',
        };
      case 'Obesitas':
        return {
          'fokus': 'Penurunan berat badan bertahap yang aman bagi sendi.',
          'olahraga': 'Olahraga low-impact: jalan kaki cepat, renang, sepeda.',
          'nutrisi':
              'Defisit 500 kkal/hari, cukupi air putih minimal 2.5L/hari.',
        };
      default:
        return {
          'fokus': 'Mempertahankan komposisi tubuh ideal dan energi optimal.',
          'olahraga': 'Aktivitas fisik sedang minimal 30 menit 3-5x seminggu.',
          'nutrisi': 'Pola makan gizi seimbang dan hidrasi cukup 2L/hari.',
        };
    }
  }
}
