import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/analisis_kesehatan_model.dart';

class DigitalHealthCard extends StatelessWidget {
  final AnalisisKesehatan data;
  final DateTime? tanggal;

  const DigitalHealthCard({super.key, required this.data, this.tanggal});

  // ── Palet warna profesional (sesuai PDF) ──
  static const _primary = Color(0xFF00C864);
  static const _primaryDark = Color(0xFF00964B);
  static const _bgDark = Color(0xFF0F1714);
  static const _bgLight = Color(0xFFF6FCF9);
  static const _textDark = Color(0xFF1E1E1E);
  static const _textMuted = Color(0xFF787878);
  static const _borderLight = Color(0xFFDCDCDC);
  static const _white = Colors.white;

  Color get _statusColor {
    switch (data.status) {
      case 'Normal':
        return _primaryDark;
      case 'Kurus':
        return const Color(0xFFC89600);
      case 'Berlebih':
        return const Color(0xFFDC6432);
      default: // Obesitas
        return const Color(0xFFC83232);
    }
  }

  Map<String, String> get _saran {
    switch (data.status) {
      case 'Kurus':
        return {
          'Fokus': 'Meningkatkan massa otot & surplus kalori teratur.',
          'Latihan': 'Latihan beban 3-4x seminggu. Batasi kardio berlebih.',
          'Nutrisi':
              'Tingkatkan porsi protein tinggi dan makanan padat nutrisi.',
        };
      case 'Berlebih':
        return {
          'Fokus': 'Defisit kalori bertahap & pembakaran lemak aktif.',
          'Latihan': 'Kombinasi kardio 30-45 mnt 4x seminggu + angkat beban.',
          'Nutrisi': 'Kurangi gula pasir dan gorengan. Perbanyak serat.',
        };
      case 'Obesitas':
        return {
          'Fokus': 'Penurunan berat badan bertahap yang aman bagi sendi.',
          'Latihan': 'Olahraga low-impact: jalan kaki cepat, renang, sepeda.',
          'Nutrisi':
              'Defisit 500 kkal/hari, cukupi air putih minimal 2.5L/hari.',
        };
      default:
        return {
          'Fokus': 'Mempertahankan komposisi tubuh ideal dan energi optimal.',
          'Latihan': 'Aktivitas fisik sedang minimal 30 menit 3-5x seminggu.',
          'Nutrisi': 'Pola makan gizi seimbang dan hidrasi cukup 2L/hari.',
        };
    }
  }

  String _formatTanggal(DateTime d) {
    const bulan = [
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
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tgl = tanggal ?? DateTime.now();
    final dateStr = _formatTanggal(tgl);
    final saran = _saran;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Banner Header Gelap ──
            Container(
              color: _bgDark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Laporan progres berat badan & indeks massa tubuh',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB4C8BE),
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Dicetak: $dateStr',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFC8DCD2),
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'FITLIFE',
                          style: GoogleFonts.poppins(
                            color: _primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Garis aksen hijau ──
            Container(height: 3, color: _primary),

            // ── Body konten ──
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 2. Chip Data Fisik ──
                  Row(
                    children: [
                      _dataChip('Tinggi', '${data.tinggiBadan.round()} cm'),
                      const SizedBox(width: 6),
                      _dataChip(
                        'Berat',
                        '${data.beratBadan.toStringAsFixed(1)} kg',
                      ),
                      const SizedBox(width: 6),
                      _dataChip('Gender', data.gender),
                      const SizedBox(width: 6),
                      _dataChip('Usia', '${data.usia} Thn'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── 3. BMI & Berat Ideal ──
                  Row(
                    children: [
                      // BMI Card
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _statusColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INDEKS MASSA TUBUH',
                                style: GoogleFonts.poppins(
                                  color: _textMuted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data.bmiDisplay,
                                style: GoogleFonts.poppins(
                                  color: _statusColor,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  data.status,
                                  style: GoogleFonts.poppins(
                                    color: _statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Berat Ideal
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BERAT IDEAL',
                                style: GoogleFonts.poppins(
                                  color: _textMuted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data.beratMin.toStringAsFixed(1)} - ${data.beratMax.toStringAsFixed(1)}',
                                style: GoogleFonts.poppins(
                                  color: _textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'kg (Normal WHO)',
                                style: GoogleFonts.poppins(
                                  color: _primaryDark,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── 4. Tiga Pilar Energi ──
                  Row(
                    children: [
                      _energyCard(
                        'BMR',
                        '${data.bmrDisplay} kkal',
                        'Metabolisme basal',
                      ),
                      const SizedBox(width: 6),
                      _energyCard(
                        'TDEE',
                        '${data.tdeeDisplay} kkal',
                        data.aktivitas,
                      ),
                      const SizedBox(width: 6),
                      _energyCard(
                        'Target',
                        '${data.tdeeDisplay} kkal',
                        'Kebutuhan harian',
                        highlight: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── 5. Rekomendasi Asupan Makronutrien ──
                  Text(
                    'Rekomendasi Asupan Makronutrien',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _summaryCard(
                        'PROTEIN',
                        '${data.proteinDisplay} g',
                        const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      _summaryCard(
                        'KARBOHIDRAT',
                        '${data.karbohidratDisplay} g',
                        const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 6),
                      _summaryCard(
                        'LEMAK',
                        '${data.lemakDisplay} g',
                        const Color(0xFFDC2626),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── 6. Rekomendasi Gaya Hidup ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REKOMENDASI GAYA HIDUP',
                          style: GoogleFonts.poppins(
                            color: _primaryDark,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...saran.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _bulletSaran(e.key, e.value),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Footer ──
                  Divider(color: _borderLight.withValues(alpha: 0.8)),
                  const SizedBox(height: 4),
                  Text(
                    'Dibuat dengan Kalkulator BMI | Konsultasikan dengan dokter untuk hasil yang lebih akurat',
                    style: GoogleFonts.poppins(color: _textMuted, fontSize: 7),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: _bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderLight),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(color: _textMuted, fontSize: 7.5),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: _textDark,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _energyCard(
    String title,
    String val,
    String subtitle, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE6FFF2) : _bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? _primary : _borderLight,
            width: highlight ? 1 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: highlight ? _primaryDark : _textMuted,
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              val,
              style: GoogleFonts.poppins(
                color: highlight ? _primary : _textDark,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(color: _textMuted, fontSize: 7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderLight, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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

  Widget _bulletSaran(String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 4, right: 6),
          decoration: const BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 8.5, color: _textMuted),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
