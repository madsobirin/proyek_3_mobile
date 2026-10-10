import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/perhitungan_model.dart';

/// Widget yang isinya persis sama seperti laporan PDF
/// (Header gelap, tabel riwayat, summary cards, makronutrien)
/// Dirender off-screen untuk di-capture sebagai PNG.
class RiwayatHealthCard extends StatelessWidget {
  final List<PerhitunganModel> history;
  final DateTime? tanggal;

  const RiwayatHealthCard({super.key, required this.history, this.tanggal});

  static const _primary = Color(0xFF00C864);
  static const _primaryDark = Color(0xFF00964B);
  static const _bgDark = Color(0xFF0F1714);
  static const _bgLight = Color(0xFFF6FCF9);
  static const _textDark = Color(0xFF1E1E1E);
  static const _textMuted = Color(0xFF787878);
  static const _borderLight = Color(0xFFDCDCDC);
  static const _white = Colors.white;

  static const _monthNames = [
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
  static const _monthShort = [
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

  String _fmtLong(DateTime d) =>
      '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

  String _fmtShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthShort[d.month - 1]} ${d.year}';

  Color _statusColor(String status) {
    switch (status) {
      case 'Normal':
        return _primaryDark;
      case 'Kurus':
        return const Color(0xFFC89600);
      case 'Berlebih':
        return const Color(0xFFDC6432);
      default:
        return const Color(0xFFC83232);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox();

    final now = tanggal ?? DateTime.now();
    final sorted = List<PerhitunganModel>.from(history)
      ..sort((a, b) => (a.createdAt ?? now).compareTo(b.createdAt ?? now));
    final reversed = sorted.reversed.toList();
    final first = sorted.first;
    final last = sorted.last;

    final deltaBerat = double.parse(
      (last.beratBadan - first.beratBadan).toStringAsFixed(1),
    );
    final avgBmi = double.parse(
      (sorted.map((e) => e.bmi).reduce((a, b) => a + b) / sorted.length)
          .toStringAsFixed(1),
    );

    return Container(
      width: 860,
      color: _white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Banner Gelap ──
          Container(
            color: _bgDark,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Perhitungan BMI',
                      style: GoogleFonts.poppins(
                        color: _white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Laporan progres berat badan & indeks massa tubuh',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB4C8BE),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Dicetak: ${_fmtLong(now)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFC8DCD2),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ${history.length} catatan',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFC8DCD2),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Garis aksen hijau ──
          Container(height: 4, color: _primary),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 2. Tabel Riwayat ──
                _buildTable(reversed),

                const SizedBox(height: 28),

                // ── 3. Ringkasan Progress (jika > 1 record) ──
                if (history.length > 1) ...[
                  Text(
                    'Ringkasan Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _summaryCard(
                        'PROGRESS BERAT',
                        '${deltaBerat >= 0 ? '+' : ''}$deltaBerat kg',
                        deltaBerat < 0
                            ? _primaryDark
                            : deltaBerat > 0
                            ? const Color(0xFFC86432)
                            : _textMuted,
                      ),
                      const SizedBox(width: 12),
                      _summaryCard(
                        'RATA-RATA BMI',
                        avgBmi.toString(),
                        _primaryDark,
                      ),
                      const SizedBox(width: 12),
                      _summaryCard(
                        'STATUS TERAKHIR',
                        last.status,
                        _primaryDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ── 4. Rekomendasi Asupan Makronutrien ──
                Text(
                  'Rekomendasi Asupan Makronutrien',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _summaryCard(
                      'PROTEIN',
                      '${last.proteinDisplay} g',
                      const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      'KARBOHIDRAT',
                      '${last.karbohidratDisplay} g',
                      const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      'LEMAK',
                      '${last.lemakDisplay} g',
                      const Color(0xFFDC2626),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Footer ──
                Divider(color: _borderLight.withValues(alpha: 0.8)),
                const SizedBox(height: 6),
                Text(
                  'Dibuat dengan Kalkulator BMI FitLife  |  Konsultasikan dengan dokter untuk hasil yang lebih akurat',
                  style: GoogleFonts.poppins(color: _textMuted, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<PerhitunganModel> items) {
    return Table(
      border: TableBorder.all(color: _borderLight, width: 0.5),
      columnWidths: const {
        0: FixedColumnWidth(36),
        1: FixedColumnWidth(100),
        2: FixedColumnWidth(70),
        3: FixedColumnWidth(70),
        4: FixedColumnWidth(54),
        5: FixedColumnWidth(72),
        6: FixedColumnWidth(70),
        7: FixedColumnWidth(70),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: _primary),
          children: [
            _thCell('No'),
            _thCell('Tanggal'),
            _thCell('Tinggi (cm)'),
            _thCell('Berat (kg)'),
            _thCell('BMI'),
            _thCell('Status'),
            _thCell('BMR'),
            _thCell('TDEE'),
          ],
        ),
        // Rows
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isOdd = idx % 2 == 1;
          final dateStr = item.createdAt != null
              ? _fmtShort(item.createdAt!)
              : '-';

          return TableRow(
            decoration: BoxDecoration(color: isOdd ? _bgLight : _white),
            children: [
              _tdCell((idx + 1).toString(), color: _textMuted, bold: true),
              _tdCell(dateStr),
              _tdCell(item.tinggiBadan.toStringAsFixed(0)),
              _tdCell(item.beratBadan.toStringAsFixed(0)),
              _tdCell(
                item.bmi.toStringAsFixed(1),
                color: _primaryDark,
                bold: true,
              ),
              _tdCell(
                item.status,
                color: _statusColor(item.status),
                bold: true,
              ),
              _tdCell(item.bmr > 0 ? item.bmr.round().toString() : '-'),
              _tdCell(item.tdee > 0 ? item.tdee.round().toString() : '-'),
            ],
          );
        }),
      ],
    );
  }

  Widget _thCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: _white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tdCell(String text, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color ?? _textDark,
          fontSize: 9.5,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderLight, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 68,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
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
