import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/analisis_kesehatan_model.dart';
import '../../models/menu_model.dart';
import '../../services/api_service.dart';
import '../../services/kalkulator_service.dart';
import '../../services/menu_service.dart';
import 'menu_detail.dart';

class BmiPage extends StatefulWidget {
  final VoidCallback onBack;
  const BmiPage({super.key, required this.onBack});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  final MenuService _menuService = MenuService();
  final ApiService _apiService = ApiService();
  bool _isLoadingMenus = false;

  String gender = 'Pria';
  double height = 170;
  double weight = 65;
  double age = 25;
  String aktivitas = 'sedang';

  AnalisisKesehatan? _hasil;
  List<MenuModel> _recommendedMenus = [];

  static const _green = Color(0xFF1AB673);

  // ── BMI Category Config ──
  static const _bmiCategories = [
    {
      'label': 'Kekurangan Berat',
      'status': 'Kurus',
      'range': 'BMI < 18.5',
      'desc': 'Perlu menambah asupan kalori bernutrisi.',
      'color': Colors.blue,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'label': 'Normal',
      'status': 'Normal',
      'range': 'BMI 18.5 – 24.9',
      'desc': 'Pertahankan gaya hidup aktif & seimbang.',
      'color': Color(0xFF1AB673),
      'icon': Icons.check_circle_outline,
    },
    {
      'label': 'Kelebihan Berat',
      'status': 'Berlebih',
      'range': 'BMI 25.0 – 29.9',
      'desc': 'Disarankan defisit kalori ringan.',
      'color': Colors.orange,
      'icon': Icons.error_outline,
    },
    {
      'label': 'Obesitas',
      'status': 'Obesitas',
      'range': 'BMI ≥ 30',
      'desc': 'Konsultasikan dengan dokter.',
      'color': Colors.red,
      'icon': Icons.error_outline,
    },
  ];

  // ── Tips per Status ──
  static const Map<String, List<String>> _tips = {
    'Kurus': [
      'Makan 5–6 kali sehari dengan porsi kecil namun padat kalori.',
      'Konsumsi protein tinggi seperti telur, ayam, dan kacang-kacangan.',
      'Lakukan latihan beban 3x seminggu untuk memicu massa otot.',
    ],
    'Normal': [
      'Lakukan aktivitas fisik ringan minimal 30 menit sehari.',
      'Pastikan hidrasi tubuh tercukupi dengan minum air mineral 2L/hari.',
      'Konsumsi sayur dan buah setiap hari untuk nutrisi optimal.',
    ],
    'Berlebih': [
      'Kurangi asupan gula dan makanan olahan.',
      'Olahraga kardio seperti jalan cepat atau bersepeda 30 menit/hari.',
      'Catat asupan kalori harian untuk memantau defisit kalori.',
    ],
    'Obesitas': [
      'Konsultasi dengan dokter atau ahli gizi segera.',
      'Mulai dengan aktivitas ringan seperti jalan kaki 15 menit/hari.',
      'Hindari minuman manis dan makanan tinggi lemak jenuh.',
    ],
  };

  void hitungAnalisis() async {
    final double roundedHeight = height.roundToDouble();
    final double roundedWeight = weight.roundToDouble();
    final int roundedAge = age.round();

    // Validasi
    final error = KalkulatorService.validasi(
      tinggi: roundedHeight,
      berat: roundedWeight,
      usia: roundedAge,
      gender: gender,
      aktivitas: aktivitas,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final hasil = KalkulatorService.hitung(
      tinggi: roundedHeight,
      berat: roundedWeight,
      usia: roundedAge,
      gender: gender,
      aktivitas: aktivitas,
    );

    setState(() {
      _hasil = hasil;
    });

    // Ambil menu rekomendasi
    _fetchRecommendedMenus(hasil.status);

    // Kirim data ke backend untuk disimpan ke riwayat
    try {
      await _apiService.post('/perhitungan', hasil.toApiPayload());
    } catch (e) {
      debugPrint('Gagal menyimpan data perhitungan ke backend: $e');
    }
  }

  Future<void> _fetchRecommendedMenus(String status) async {
    setState(() => _isLoadingMenus = true);
    try {
      final menus = await _menuService.getMenusByTarget(status);
      if (mounted) {
        setState(() {
          _recommendedMenus = menus.take(5).toList();
          _isLoadingMenus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMenus = false);
    }
  }

  Color _kategoriColor() {
    if (_hasil == null) return Colors.grey;
    switch (_hasil!.status) {
      case 'Kurus':
        return Colors.blue;
      case 'Normal':
        return _green;
      case 'Berlebih':
        return Colors.orange;
      case 'Obesitas':
      default:
        return Colors.red;
    }
  }

  Widget _modernCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _genderSelector(String label) {
    final isSelected = gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? _green.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _green : Colors.grey[200]!,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label == 'Pria' ? '♂' : '♀',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _green : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aktivitasSelector(OpsiAktivitas opsi) {
    final isSelected = aktivitas == opsi.id;
    return GestureDetector(
      onTap: () => setState(() => aktivitas = opsi.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? _green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _green : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    opsi.label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? _green : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 16, color: _green),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              opsi.deskripsi,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _hasil?.status ?? 'Normal';
    final tips = _tips[currentStatus] ?? _tips['Normal']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalkulator Kesehatan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Analisis Tubuh, Energi & Nutrisi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Form Input Card ──
          _modernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parameter Fisik',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Jenis Kelamin
                Text(
                  'Jenis Kelamin',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _genderSelector('Pria'),
                    const SizedBox(width: 10),
                    _genderSelector('Wanita'),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Tinggi Badan Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tinggi Badan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '${height.toInt()} ',
                            style: const TextStyle(color: _green, fontSize: 20),
                          ),
                          TextSpan(
                            text: 'CM',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: height,
                  min: 100,
                  max: 220,
                  divisions: 120,
                  activeColor: _green,
                  inactiveColor: Colors.grey[200],
                  onChanged: (value) =>
                      setState(() => height = value.roundToDouble()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '100 cm',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '220 cm',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Berat Badan Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Berat Badan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '${weight.toInt()} ',
                            style: const TextStyle(color: _green, fontSize: 20),
                          ),
                          TextSpan(
                            text: 'KG',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: weight,
                  min: 30,
                  max: 200,
                  divisions: 170,
                  activeColor: _green,
                  inactiveColor: Colors.grey[200],
                  onChanged: (value) =>
                      setState(() => weight = value.roundToDouble()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '30 kg',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '200 kg',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Usia Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Usia',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '${age.toInt()} ',
                            style: const TextStyle(color: _green, fontSize: 20),
                          ),
                          TextSpan(
                            text: 'Tahun',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: age,
                  min: 15,
                  max: 90,
                  divisions: 75,
                  activeColor: _green,
                  inactiveColor: Colors.grey[200],
                  onChanged: (value) =>
                      setState(() => age = value.roundToDouble()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '15 Tahun',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '90 Tahun',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 5. Tingkat Aktivitas Harian
                Text(
                  'Tingkat Aktivitas Harian',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: KalkulatorService.daftarAktivitas
                      .map((opsi) => _aktivitasSelector(opsi))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Tombol Hitung
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hitungAnalisis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hitung Analisis Kesehatan Saya',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Bagian Hasil Analisis ──
          if (_hasil == null)
            _modernCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: _green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Masukkan data fisik Anda dan klik hitung untuk melihat analisis tubuh, kebutuhan kalori harian, serta estimasi nutrisi.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_hasil != null) ...[
            // ── 1. BODY ANALYSIS (Analisis Tubuh) ──
            Text(
              '1. Analisis Tubuh',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _modernCard(
              child: Column(
                children: [
                  // Status & BMI Circle Banner
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _kategoriColor().withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kategoriColor().withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _hasil!.bmiDisplay,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _kategoriColor(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _kategoriColor().withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _kategoriColor().withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                _hasil!.statusLabel,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: _kategoriColor(),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tinggi: ${_hasil!.tinggiBadan.toInt()} cm • Berat: ${_hasil!.beratBadan.toInt()} kg',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Grid Detail Tubuh (BMI & Kisaran Berat)
                  Row(
                    children: [
                      // Skor BMI
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BMI',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${_hasil!.bmiDisplay}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kategoriColor(),
                                ),
                              ),
                              Text(
                                'Kategori: ${_hasil!.status}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Kisaran Berat Ideal Berdasarkan BMI
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kisaran Berat Sehat',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${_hasil!.kisaranBeratDisplay}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'BMI 18.5 – 24.9',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. ENERGY NEEDS (Kebutuhan Energi) ──
            Text(
              '2. Kebutuhan Energi Harian',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _modernCard(
              child: Row(
                children: [
                  // BMR Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'BMR',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '≈ ${_hasil!.bmrDisplay}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'kcal/hari (istirahat)',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // TDEE Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt, size: 14, color: _green),
                              const SizedBox(width: 4),
                              Text(
                                'Energi Harian (TDEE)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '≈ ${_hasil!.tdeeDisplay}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _green,
                            ),
                          ),
                          Text(
                            'kcal/hari (aktif)',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. NUTRITION ESTIMATE (Estimasi Nutrisi) ──
            Text(
              '3. Rekomendasi Nutrisi Harian',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _modernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant, color: _green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Distribusi Makronutrien',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Protein
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'PROTEIN',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${_hasil!.proteinDisplay}g',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'BB × 1.4 g',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Lemak
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'LEMAK',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${_hasil!.lemakDisplay}g',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '30% TDEE',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Karbohidrat
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'KARBOHIDRAT',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${_hasil!.karbohidratDisplay}g',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sisa Kalori',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tips Section ──
            _modernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tips Cepat Sehat',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 7),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Kategori BMI Reference Grid ──
          Text(
            'Panduan Kategori BMI',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _bmiCategories.length,
            itemBuilder: (context, index) {
              final cat = _bmiCategories[index];
              final color = cat['color'] as Color;
              final isActive =
                  _hasil != null && _hasil!.status == cat['status'];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive
                        ? color.withValues(alpha: 0.6)
                        : Colors.grey[200]!,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat['label'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat['range'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        cat['desc'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Rekomendasi Menu Sehat ──
          if (_hasil != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: _green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menu Rekomendasi: ${_hasil!.status}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pilihan nutrisi terbaik untuk kebutuhan Anda saat ini.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 14),

            if (_isLoadingMenus)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _green),
                ),
              )
            else if (_recommendedMenus.isEmpty)
              _modernCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Belum ada menu untuk kategori ini.',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _recommendedMenus.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final menu = _recommendedMenus[index];
                    return _recommendedMenuCard(menu);
                  },
                ),
              ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _recommendedMenuCard(MenuModel menu) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuDetailPage(menu: menu.toJson()),
          ),
        );
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                image: DecorationImage(
                  image: NetworkImage(menu.gambar),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.namaMenu,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${menu.kalori} kal',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.blue[300],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${menu.waktuMemasak}m',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
