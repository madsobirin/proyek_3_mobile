import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/analisis_kesehatan_model.dart';
import '../../models/menu_model.dart';
import '../../models/perhitungan_model.dart';
import '../../services/auth_services.dart';
import '../../services/kalkulator_service.dart';
import '../../services/menu_service.dart';
import '../../services/perhitungan_service.dart';
import 'menu_detail.dart';
import 'menu_page.dart';
import 'widgets/kartu_kesehatan_modal.dart';
import 'widgets/riwayat_health_card.dart';
import '../../services/kartu_kesehatan_export_service.dart';

class BmiPage extends StatefulWidget {
  final VoidCallback onBack;
  const BmiPage({super.key, required this.onBack});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  final MenuService _menuService = MenuService();
  final PerhitunganService _perhitunganService = PerhitunganService();
  final AuthServices _authServices = AuthServices();

  bool _isLoadingMenus = false;
  bool _isLoggedIn = false;
  bool _isLoadingHistory = false;
  String? _historyError;
  List<PerhitunganModel> _historyList = [];
  final GlobalKey _riwayatPngKey = GlobalKey();

  String gender = 'Pria';
  double height = 170;
  double weight = 65;
  double age = 25;
  String aktivitas = 'sedang';

  AnalisisKesehatan? _hasil;
  List<MenuModel> _recommendedMenus = [];
  String _selectedMealTab = 'semua';

  int get _totalKcal => _hasil?.tdeeDisplay ?? 2000;
  int get _sarapanKcal => (0.25 * _totalKcal).round();
  int get _siangKcal => (0.40 * _totalKcal).round();
  int get _malamKcal => (0.35 * _totalKcal).round();

  List<MenuModel> get _filteredRecommendedMenus {
    final sKcal = _sarapanKcal;
    final lKcal = _siangKcal;
    final dKcal = _malamKcal;

    switch (_selectedMealTab) {
      case 'sarapan':
        return _recommendedMenus.where((m) => m.kalori <= sKcal + 150).toList();
      case 'siang':
        return _recommendedMenus
            .where((m) => m.kalori >= 350 && m.kalori <= lKcal + 200)
            .toList();
      case 'malam':
        return _recommendedMenus.where((m) => m.kalori <= dKcal + 150).toList();
      case 'semua':
      default:
        return _recommendedMenus;
    }
  }

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

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadHistory();
  }

  Future<void> _checkAuthAndLoadHistory() async {
    final token = await _authServices.getToken();
    final loggedIn = token != null && token.isNotEmpty;
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
      });
    }
    if (loggedIn) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (!_isLoggedIn) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final items = await _perhitunganService.getHistory();
      if (mounted) {
        setState(() {
          _historyList = items;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingHistory = false;
        });
      }
    }
  }

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
      _selectedMealTab = 'semua';
    });

    // Ambil menu rekomendasi
    _fetchRecommendedMenus(hasil.status);

    // Kirim data ke backend untuk disimpan ke riwayat HANYA jika user sudah login
    if (_isLoggedIn) {
      try {
        final saved = await _perhitunganService.savePerhitungan(hasil);
        if (saved && mounted) {
          _loadHistory();
        }
      } catch (e) {
        debugPrint('Gagal menyimpan data perhitungan ke backend: $e');
      }
    }
  }

  Future<void> _fetchRecommendedMenus(String status) async {
    setState(() => _isLoadingMenus = true);
    try {
      final menus = await _menuService.getMenusByTarget(status);
      if (mounted) {
        setState(() {
          _recommendedMenus = menus;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        widget.onBack();
                      }
                    },
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalkulator Kesehatan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Analisis Tubuh, Energi & Nutrisi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
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
                    Expanded(
                      child: Text(
                        'Tinggi Badan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
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
                    Expanded(
                      child: Text(
                        'Berat Badan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
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
                    Expanded(
                      child: Text(
                        'Usia',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
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
                  childAspectRatio: 1.35,
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
                        Flexible(
                          child: Text(
                            'Hitung Analisis Kesehatan Saya',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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
                              Expanded(
                                child: Text(
                                  'Energi Harian (TDEE)',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _green,
                                  ),
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
                      Expanded(
                        child: Text(
                          'Distribusi Makronutrien',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
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
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'PROTEIN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '≈ ${_hasil!.proteinDisplay}g',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'BB × 1.4 g',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.grey[500],
                                  ),
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
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'LEMAK',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '≈ ${_hasil!.lemakDisplay}g',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '30% TDEE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.grey[500],
                                  ),
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
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'KARBOHIDRAT',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '≈ ${_hasil!.karbohidratDisplay}g',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Sisa Kalori',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.grey[500],
                                  ),
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
                      Expanded(
                        child: Text(
                          'Tips Cepat Sehat',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  KartuKesehatanModal.show(
                    context,
                    _hasil!,
                    isLoggedIn: _isLoggedIn,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF090E0C),
                  foregroundColor: const Color(0xFF00FF7F),
                  side: const BorderSide(color: Color(0xFF00FF7F), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.auto_awesome, color: Color(0xFF00FF7F), size: 18),
                label: Text(
                  'Unduh / Cetak Kartu Digital',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
              mainAxisExtent: 185,
            ),
            itemCount: _bmiCategories.length,
            itemBuilder: (context, index) {
              final cat = _bmiCategories[index];
              final color = cat['color'] as Color;
              final isActive =
                  _hasil != null && _hasil!.status == cat['status'];

              return Container(
                padding: const EdgeInsets.all(12),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    Text(
                      cat['desc'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.restaurant_menu, color: _green, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendasi Menu Diet: ${_hasil!.status}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nutrisi seimbang untuk mendukung kebutuhan energi harian Anda ($_totalKcal kcal/hari).',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MenuPage(onBack: () => Navigator.pop(context)),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: GoogleFonts.poppins(
                            color: _green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 11,
                          color: _green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3 Summary Cards Pembagian Kalori
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _calorieSummaryBox(
                      label: '🌅 Sarapan (25%)',
                      kcal: '~$_sarapanKcal kkal',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _calorieSummaryBox(
                      label: '☀️ Makan Siang (40%)',
                      kcal: '~$_siangKcal kkal',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _calorieSummaryBox(
                      label: '🌙 Makan Malam (35%)',
                      kcal: '~$_malamKcal kkal',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filter Tabs (Semua Menu, Sarapan, Makan Siang, Makan Malam)
            _buildMealFilterTabs(),
            const SizedBox(height: 14),

            // Daftar Menu Rekomendasi
            if (_isLoadingMenus)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _green),
                ),
              )
            else if (_filteredRecommendedMenus.isEmpty)
              _modernCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Belum ada menu yang cocok untuk kategori ini.',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _filteredRecommendedMenus
                    .map((menu) => _recommendedMenuCard(menu, _totalKcal))
                    .toList(),
              ),
          ],

          // ── Riwayat Perhitungan Section ──
          const SizedBox(height: 28),
          _buildHistorySection(),

          const SizedBox(height: 40),

          // ── Hidden widget untuk capture PNG (di-render di luar layar) ──
          Transform.translate(
            offset: const Offset(-10000, 0),
            child: RepaintBoundary(
              key: _riwayatPngKey,
              child: RiwayatHealthCard(history: _historyList),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _calorieSummaryBox({required String label, required String kcal}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              kcal,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealFilterTabs() {
    final tabs = [
      {'id': 'semua', 'label': 'Semua Menu'},
      {'id': 'sarapan', 'label': '🌅 Sarapan (~$_sarapanKcal kkal)'},
      {'id': 'siang', 'label': '☀️ Makan Siang (~$_siangKcal kkal)'},
      {'id': 'malam', 'label': '🌙 Makan Malam (~$_malamKcal kkal)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final id = tab['id']!;
          final label = tab['label']!;
          final isSelected = _selectedMealTab == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMealTab = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? _green
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _green.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _recommendedMenuCard(MenuModel menu, int totalKcal) {
    final targetPct = totalKcal > 0
        ? (menu.kalori / totalKcal * 100).round()
        : 0;

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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Image.network(
                      menu.gambar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$targetPct% Target Harian',
                        style: GoogleFonts.poppins(
                          color: _green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'RECOMMENDED',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.namaMenu,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${menu.kalori} kkal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: _green.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${menu.waktuMemasak}m',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: _green,
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'kurus':
        return Colors.blue;
      case 'normal':
        return const Color(0xFF1AB673);
      case 'berlebih':
        return Colors.orange;
      case 'obesitas':
        return Colors.red;
      default:
        return const Color(0xFF1AB673);
    }
  }

  Future<void> _deleteHistoryItem(PerhitunganModel item) async {
    if (item.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Riwayat?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data perhitungan BMI ${item.bmiDisplay} (${item.status}) ini?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('[DEBUG DELETE] GET record id: ${item.id}');
      debugPrint('[DEBUG DELETE] Model id: ${item.id}');
      debugPrint('[DEBUG DELETE] Delete id: ${item.id}');
      await _perhitunganService.deleteHistory(item.id!);
      if (mounted) {
        setState(() {
          _historyList.removeWhere((element) => element.id == item.id);
        });
        _loadHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Riwayat perhitungan berhasil dihapus.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: _green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Riwayat & Tren Berat Badan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (_isLoggedIn && _historyList.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_historyList.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Visualisasi riwayat dan perkembangan berat badan Anda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoggedIn) ...[
              IconButton(
                icon: _isLoadingHistory
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _green,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                tooltip: 'Segarkan Riwayat',
                onPressed: _isLoadingHistory ? null : _loadHistory,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (!_isLoggedIn)
          _buildGuestHistoryCard()
        else if (_isLoadingHistory && _historyList.isEmpty)
          _buildHistoryLoading()
        else if (_historyError != null && _historyList.isEmpty)
          _buildHistoryError()
        else if (_historyList.isEmpty)
          _buildHistoryEmpty()
        else
          _buildHistoryAndTrendContent(),
      ],
    );
  }

  Widget _buildHistoryAndTrendContent() {
    final latest = _historyList.first;
    final oldest = _historyList.last;
    final double beratTerbaru = latest.beratBadan;
    final double bmiTerkini = latest.bmi;
    final String statusTerkini = latest.status;
    final double totalPerubahan = beratTerbaru - oldest.beratBadan;

    final String statusTren;
    if (_historyList.length == 1) {
      statusTren = 'Awal';
    } else if (totalPerubahan > 0.2) {
      statusTren = 'Naik';
    } else if (totalPerubahan < -0.2) {
      statusTren = 'Turun';
    } else {
      statusTren = 'Stabil';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Summary Card
        _buildSummaryCard(
          beratTerbaru: beratTerbaru,
          bmiTerkini: bmiTerkini,
          statusTerkini: statusTerkini,
          totalPerubahan: totalPerubahan,
          statusTren: statusTren,
          totalRecords: _historyList.length,
        ),
        const SizedBox(height: 14),

        // 2. Chart or Single-Record Banner
        if (_historyList.length == 1)
          _buildSingleRecordBanner(latest)
        else
          _buildWeightTrendChart(),

        const SizedBox(height: 20),

        // 3. Detail Pengukuran Subheader
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detail Pengukuran',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              '${_historyList.length} Catatan Tersimpan',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 4. Detail list
        _buildHistoryList(),

        const SizedBox(height: 16),

        // 5. Tombol Unduh Laporan
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: _green, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Menyiapkan gambar PNG...'),
                      backgroundColor: Color(0xFF1AB673),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  final ok = await KartuKesehatanExportService
                      .captureAndDownloadPng(_riwayatPngKey);
                  if (!ok) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Gagal membuat PNG. Coba lagi.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.image_outlined, size: 16),
                label: Text(
                  'Unduh PNG',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menyiapkan laporan PDF...'),
                      backgroundColor: Color(0xFF1AB673),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  await KartuKesehatanExportService.exportRiwayatToPdf(
                    _historyList,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: Text(
                  'Unduh PDF',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required double beratTerbaru,
    required double bmiTerkini,
    required String statusTerkini,
    required double totalPerubahan,
    required String statusTren,
    required int totalRecords,
  }) {
    final statusColor = _statusColor(statusTerkini);

    final Color trenColor;
    final IconData trenIcon;
    if (statusTren == 'Naik') {
      trenColor = Colors.orange[700]!;
      trenIcon = Icons.trending_up_rounded;
    } else if (statusTren == 'Turun') {
      trenColor = Colors.blue[600]!;
      trenIcon = Icons.trending_down_rounded;
    } else {
      trenColor = _green;
      trenIcon = Icons.trending_flat_rounded;
    }

    final String perubahanText = totalRecords == 1
        ? '0.0 kg'
        : '${totalPerubahan > 0 ? '+' : ''}${totalPerubahan.toStringAsFixed(1)} kg';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryMetricBox(
                  icon: Icons.monitor_weight_outlined,
                  iconColor: Colors.blue,
                  title: 'Berat Terbaru',
                  value: '${beratTerbaru.toStringAsFixed(1)} kg',
                  subtitle: 'Catatan terkini',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetricBox(
                  icon: Icons.speed_rounded,
                  iconColor: statusColor,
                  title: 'BMI Terkini',
                  value: bmiTerkini.toStringAsFixed(1),
                  badge: statusTerkini,
                  badgeColor: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryMetricBox(
                  icon: Icons.compare_arrows_rounded,
                  iconColor: trenColor,
                  title: 'Total Perubahan',
                  value: perubahanText,
                  valueColor: totalRecords == 1 ? null : trenColor,
                  subtitle: totalRecords == 1
                      ? 'Pengukuran awal'
                      : 'Sejak awal tercatat',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetricBox(
                  icon: trenIcon,
                  iconColor: trenColor,
                  title: 'Status Tren',
                  value: statusTren,
                  valueColor: trenColor,
                  subtitle: totalRecords == 1
                      ? 'Belum ada tren'
                      : 'Arah perkembangan',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetricBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
    String? subtitle,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? const Color(0xFF111827),
                  ),
                ),
              ),
              if (badge != null && badgeColor != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleRecordBanner(PerhitunganModel single) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 Catatan Pengukuran Tersimpan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lakukan kalkulasi berikutnya untuk melihat grafik tren visualisasi perkembangan berat badan Anda.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTrendChart() {
    // Urutan kronologis: terlama -> terbaru
    final chronological = _historyList.reversed.toList();

    double minWeight = chronological.first.beratBadan;
    double maxWeight = chronological.first.beratBadan;
    for (final item in chronological) {
      if (item.beratBadan < minWeight) minWeight = item.beratBadan;
      if (item.beratBadan > maxWeight) maxWeight = item.beratBadan;
    }

    final double minY = (minWeight - 2).floorToDouble();
    final double maxY = (maxWeight + 2).ceilToDouble();
    final double interval = (maxY - minY) > 10 ? 5 : 2;

    final spots = List.generate(
      chronological.length,
      (index) => FlSpot(index.toDouble(), chronological[index].beratBadan),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: _green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Grafik Tren Berat Badan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                'Terlama → Terbaru',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval > 0 ? interval : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.12),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: interval > 0 ? interval : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} kg',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chronological.length) {
                          final item = chronological[index];
                          final dateText = item.createdAt != null
                              ? DateFormat(
                                  'd/M',
                                ).format(item.createdAt!.toLocal())
                              : '#${index + 1}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dateText,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF111827),
                    tooltipBorderRadius: BorderRadius.circular(10),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        if (idx >= 0 && idx < chronological.length) {
                          final item = chronological[idx];
                          return LineTooltipItem(
                            '${item.formattedDate}\n${item.beratBadan.toStringAsFixed(1)} kg\nBMI ${item.bmiDisplay} (${item.status})',
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          );
                        }
                        return LineTooltipItem(
                          '${spot.y} kg',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: _green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4.5,
                          color: _green,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _green.withValues(alpha: 0.25),
                          _green.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: _green,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mode Tamu (Belum Masuk)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Anda dapat melakukan kalkulasi kapan saja. Masuk ke akun FitLife Anda untuk menyimpan dan melihat riwayat kesehatan secara otomatis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login').then((_) {
                  _checkAuthAndLoadHistory();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Masuk ke Akun FitLife',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: const Center(child: CircularProgressIndicator(color: _green)),
    );
  }

  Widget _buildHistoryError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            _historyError ?? 'Gagal memuat riwayat perhitungan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh_rounded, size: 16, color: _green),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 32,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Riwayat Perhitungan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hasil perhitungan yang Anda simpan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _historyList[index];
        return _buildHistoryItemCard(item);
      },
    );
  }

  Widget _buildHistoryItemCard(PerhitunganModel item) {
    final statusColor = _statusColor(item.status);

    return InkWell(
      onTap: () {
        // Memuat parameter ke form kalkulator
        setState(() {
          gender =
              (item.gender != null && item.gender!.toLowerCase() == 'wanita')
              ? 'Wanita'
              : 'Pria';
          height = item.tinggiBadan;
          weight = item.beratBadan;
          if (item.usia != null && item.usia! > 0) {
            age = item.usia!.toDouble();
          }
          if (item.aktivitas != null && item.aktivitas!.isNotEmpty) {
            aktivitas = item.aktivitas!.toLowerCase();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Parameter riwayat (${item.beratBadan.toStringAsFixed(0)} kg, ${item.tinggiBadan.toStringAsFixed(0)} cm) dimuat ke form.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Date, Category Badge, Delete Action
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  item.formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (item.id != null) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _deleteHistoryItem(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.redAccent.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Middle: BMI Box & Body Stats
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.bmiDisplay,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'BMI',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${item.beratBadan.toStringAsFixed(0)} kg',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            '${item.tinggiBadan.toStringAsFixed(0)} cm',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ideal: ${item.kisaranBeratDisplay}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'BMR: ${item.bmrDisplay} kkal • TDEE: ${item.tdeeDisplay} kkal',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
            const SizedBox(height: 10),

            // Bottom: Macronutrients Chips
            Row(
              children: [
                _macroChip(
                  label: 'Protein',
                  value: '${item.proteinDisplay}g',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _macroChip(
                  label: 'Lemak',
                  value: '${item.lemakDisplay}g',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _macroChip(
                  label: 'Karbo',
                  value: '${item.karbohidratDisplay}g',
                  color: const Color(0xFF1AB673),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
