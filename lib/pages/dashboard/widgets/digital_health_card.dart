import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/analisis_kesehatan_model.dart';

class DigitalHealthCard extends StatelessWidget {
  final AnalisisKesehatan data;
  final DateTime? tanggal;

  const DigitalHealthCard({
    super.key,
    required this.data,
    this.tanggal,
  });

  Color get statusColor {
    switch (data.status) {
      case 'Kurus':
        return const Color(0xFF38BDF8); // Cyan
      case 'Normal':
        return const Color(0xFF00FF7F); // Emerald neon
      case 'Berlebih':
        return const Color(0xFFFBBF24); // Amber
      default:
        return const Color(0xFFF87171); // Red
    }
  }

  Map<String, String> get saranKesehatan {
    switch (data.status) {
      case 'Kurus':
        return {
          'fokus': 'Meningkatkan massa otot & surplus kalori teratur.',
          'olahraga': 'Latihan beban 3-4x seminggu. Batasi kardio berlebih.',
          'nutrisi': 'Tingkatkan porsi protein tinggi dan makanan padat nutrisi.',
        };
      case 'Berlebih':
        return {
          'fokus': 'Defisit kalori bertahap & pembakaran lemak aktif.',
          'olahraga': 'Kombinasi kardio 30-45 mnt 4x seminggu + angkat beban.',
          'nutrisi': 'Kurangi konsumsi gula pasir dan gorengan. Perbanyak serat.',
        };
      case 'Obesitas':
        return {
          'fokus': 'Penurunan berat badan bertahap yang aman bagi sendi.',
          'olahraga': 'Olahraga low-impact: jalan kaki cepat, renang, sepeda.',
          'nutrisi': 'Defisit 500 kkal/hari, cukupi air putih minimal 2.5L/hari.',
        };
      default:
        return {
          'fokus': 'Mempertahankan komposisi tubuh ideal dan energi optimal.',
          'olahraga': 'Aktivitas fisik sedang minimal 30 menit 3-5x seminggu.',
          'nutrisi': 'Pola makan gizi seimbang dan hidrasi cukup 2L/hari.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final tgl = tanggal ?? DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(tgl);
    final saran = saranKesehatan;

    return Container(
      width: 380,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF090E0C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00FF7F).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF7F).withOpacity(0.08),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Kartu ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF00FF7F), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'DIGITAL HEALTH PASSPORT',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00FF7F),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rangkuman Kesehatan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF7F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00FF7F).withOpacity(0.3)),
                ),
                child: Text(
                  'FITLIFE',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00FF7F),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // ── 4 Chip Data Fisik ──
          Row(
            children: [
              _metricChip('Tinggi', '${data.tinggiBadan.round()} cm'),
              const SizedBox(width: 6),
              _metricChip('Berat', '${data.beratBadan.toStringAsFixed(1)} kg'),
              const SizedBox(width: 6),
              _metricChip('Gender', data.gender),
              const SizedBox(width: 6),
              _metricChip('Usia', '${data.usia} Thn'),
            ],
          ),

          const SizedBox(height: 14),

          // ── BMI & Rentang Berat Ideal ──
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INDEKS MASSA TUBUH',
                        style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.bmiDisplay,
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.status,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BERAT IDEAL',
                        style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.beratMin.toStringAsFixed(1)} - ${data.beratMax.toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'kg (Normal WHO)',
                        style: GoogleFonts.poppins(color: const Color(0xFF00FF7F), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Tiga Pilar Energi: BMR, TDEE, Target ──
          Row(
            children: [
              _energyCard('BMR', '${data.bmrDisplay} kkal', 'Metabolisme basal'),
              const SizedBox(width: 6),
              _energyCard('TDEE', '${data.tdeeDisplay} kkal', data.aktivitas),
              const SizedBox(width: 6),
              _energyCard('Target', '${data.tdeeDisplay} kkal', 'Kebutuhan harian', isHighlight: true),
            ],
          ),

          const SizedBox(height: 12),

          // ── Makronutrisi ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroItem('Protein', '${data.proteinDisplay}g', const Color(0xFF38BDF8)),
                Container(width: 1, height: 18, color: Colors.white12),
                _macroItem('Karbo', '${data.karbohidratDisplay}g', const Color(0xFFFBBF24)),
                Container(width: 1, height: 18, color: Colors.white12),
                _macroItem('Lemak', '${data.lemakDisplay}g', const Color(0xFFF87171)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Saran Aktivitas & Gaya Hidup ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 REKOMENDASI GAYA HIDUP',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00FF7F),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _bulletSaran('Fokus', saran['fokus']!),
                const SizedBox(height: 4),
                _bulletSaran('Latihan', saran['olahraga']!),
                const SizedBox(height: 4),
                _bulletSaran('Nutrisi', saran['nutrisi']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 8)),
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _energyCard(String title, String val, String subtitle, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFF00FF7F).withOpacity(0.12) : const Color(0xFF00FF7F).withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighlight ? const Color(0xFF00FF7F).withOpacity(0.4) : const Color(0xFF00FF7F).withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(color: isHighlight ? const Color(0xFF00FF7F) : Colors.grey[300], fontSize: 9, fontWeight: FontWeight.w600)),
            Text(val, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 7.5)),
          ],
        ),
      ),
    );
  }

  Widget _macroItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 8)),
        Text(val, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _bulletSaran(String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: GoogleFonts.poppins(color: const Color(0xFF00FF7F), fontWeight: FontWeight.bold, fontSize: 10)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[300]),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
