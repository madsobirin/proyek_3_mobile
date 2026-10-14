import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/analisis_kesehatan_model.dart';
import '../../models/menu_model.dart';
import '../../models/perhitungan_model.dart';
import '../../services/auth_services.dart';
import '../../services/kalkulator_service.dart';
import '../../services/menu_service.dart';
import '../../services/perhitungan_service.dart';
import 'menu_detail.dart';
import 'menu_page.dart';
import '../lokasi/lokasi_olahraga_page.dart';
import 'widgets/riwayat_health_card.dart';
import '../../services/kartu_kesehatan_export_service.dart';
import '../../services/download_notification_service.dart';
import '../../services/lokasi_olahraga_service.dart';

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
  bool _isExportingPng = false;
  bool _isExportingPdf = false;
  final LokasiOlahragaService _lokasiOlahragaService =
      LokasiOlahragaService.instance;
  List<Map<String, dynamic>> _sportsLocations = [];
  bool _isLoadingSportsLocations = false;

  // ── Tab & UI States ──
  int _selectedMainTab = 0; // 0: Kalkulator, 1: Riwayat & Tren
  bool _isFormExpanded = true;
  int _selectedResultTab =
      0; // 0: Nutrisi & Energi, 1: Menu Diet, 2: Olahraga, 3: Panduan BMI

  // ── Input Form States ──
  String gender = 'Pria';
  double height = 0;
  double weight = 0;
  double age = 0;
  String aktivitas = '';

  // Controller input dimulai kosong agar pengguna mengisi datanya sendiri.
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

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

  List<PerhitunganModel> get _displayHistoryList {
    if (_historyList.isNotEmpty) return _historyList;
    if (_hasil != null) {
      return [
        PerhitunganModel(
          tinggiBadan: _hasil!.tinggiBadan,
          beratBadan: _hasil!.beratBadan,
          bmi: _hasil!.bmi,
          status: _hasil!.status,
          gender: _hasil!.gender,
          usia: _hasil!.usia,
          aktivitas: _hasil!.aktivitas,
          bmr: _hasil!.bmr,
          tdee: _hasil!.tdee,
          targetKalori: _hasil!.tdee,
          beratMin: _hasil!.beratMin,
          beratMax: _hasil!.beratMax,
          protein: _hasil!.protein,
          karbohidrat: _hasil!.karbohidrat,
          lemak: _hasil!.lemak,
          createdAt: DateTime.now(),
        ),
      ];
    }
    return [];
  }

  List<PerhitunganModel> get _exportHistoryList => _displayHistoryList;

  static const _green = Color(0xFF20603D);

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
      'color': Color(0xFF20603D),
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
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadHistory();
    DownloadNotificationService().initialize();
    _fetchSportsLocations();
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

    final newRecord = PerhitunganModel(
      tinggiBadan: roundedHeight,
      beratBadan: roundedWeight,
      bmi: hasil.bmi,
      status: hasil.status,
      gender: gender,
      usia: roundedAge,
      aktivitas: aktivitas,
      bmr: hasil.bmr,
      tdee: hasil.tdee,
      targetKalori: hasil.tdee,
      beratMin: hasil.beratMin,
      beratMax: hasil.beratMax,
      protein: hasil.protein,
      karbohidrat: hasil.karbohidrat,
      lemak: hasil.lemak,
      createdAt: DateTime.now(),
    );

    setState(() {
      _hasil = hasil;
      _selectedMealTab = 'semua';
      _isFormExpanded = false; // Ringkas form agar hasil langsung fokus
      _selectedResultTab = 0;
      // Optimistic update: langsung masukkan ke _historyList agar segera tampil di tab Riwayat & Tren
      _historyList.insert(0, newRecord);
    });

    // Ambil menu rekomendasi
    _fetchRecommendedMenus(hasil.status);
    _fetchSportsLocations();

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

  Future<void> _fetchSportsLocations() async {
    if (_sportsLocations.isNotEmpty) return;
    setState(() => _isLoadingSportsLocations = true);
    try {
      final results = await _lokasiOlahragaService.fetchAll();
      if (mounted) {
        setState(() {
          _sportsLocations = results.map((l) => l.toDisplayMap()).toList();
          _isLoadingSportsLocations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSportsLocations = false);
      }
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

  // Input parameter fisik menggunakan satu metode: tombol minus dan plus.
  Widget _numberInputField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[400],
              fontWeight: FontWeight.normal,
            ),
            suffixText: unit,
            suffixStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: _green,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderSelector(String label) {
    final isSelected = gender == label;
    final icon = label == 'Pria' ? Icons.male_rounded : Icons.female_rounded;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? _green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _green : Colors.grey[200]!,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? _green : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected ? _green : Colors.black87,
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
    final IconData iconData;
    switch (opsi.id) {
      case 'rebahan':
      case 'sedentary':
        iconData = Icons.chair_outlined;
        break;
      case 'ringan':
      case 'light':
        iconData = Icons.directions_walk_rounded;
        break;
      case 'sedang':
      case 'moderate':
        iconData = Icons.fitness_center_rounded;
        break;
      case 'berat':
      case 'active':
      default:
        iconData = Icons.bolt_rounded;
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => aktivitas = opsi.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _green.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.03),
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
                Icon(
                  iconData,
                  size: 16,
                  color: isSelected ? _green : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    opsi.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isSelected ? _green : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 14, color: _green),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              opsi.deskripsi,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                color: Colors.grey[600],
                height: 1.25,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        Text(
                          'Analisis Tubuh, Energi & Nutrisi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Top Main Tab Switcher (Kalkulator vs Riwayat) ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMainTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedMainTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedMainTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calculate_outlined,
                                size: 18,
                                color: _selectedMainTab == 0
                                    ? _green
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Kalkulator BMI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: _selectedMainTab == 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: _selectedMainTab == 0
                                        ? _green
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMainTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedMainTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedMainTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.show_chart_rounded,
                                size: 18,
                                color: _selectedMainTab == 1
                                    ? _green
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Riwayat & Tren',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: _selectedMainTab == 1
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: _selectedMainTab == 1
                                        ? _green
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (_displayHistoryList.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedMainTab == 1
                                        ? _green
                                        : Colors.grey[400],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_displayHistoryList.length}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── TAB CONTENT ──
              if (_selectedMainTab == 0)
                _buildKalkulatorTabContent()
              else
                _buildRiwayatTabContent(),

              const SizedBox(height: 32),

              // ── Hidden widget untuk capture PNG (0x0 space) ──
              if (_isLoggedIn)
                SizedBox(
                  width: 0,
                  height: 0,
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 860,
                    maxWidth: 860,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Transform.translate(
                      offset: const Offset(-10000, 0),
                      child: RepaintBoundary(
                        key: _riwayatPngKey,
                        child: RiwayatHealthCard(history: _exportHistoryList),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ── KALKULATOR TAB VIEW ──
  // ════════════════════════════════════════════════════════════════════
  Widget _buildKalkulatorTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Parameter Fisik (Expanded / Collapsed Compact Summary) ──
        if (!_isFormExpanded && _hasil != null)
          _buildCompactInputSummary()
        else
          _buildExpandedInputForm(),

        const SizedBox(height: 18),

        // ── 2. Bagian Hasil Analisis ──
        if (_hasil == null) ...[
          // Friendly info card saat belum dihitung
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
                    'Atur data fisik Anda di atas dan klik tombol hitung untuk melihat analisis tubuh, target kalori harian, dan rekomendasi nutrisi lengkap.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildBmiCategoryGuide(),
        ] else ...[
          // Hero Result Card
          _buildHeroResultCard(),

          const SizedBox(height: 18),

          // Sub-tabs untuk Hasil (Nutrisi, Menu, Olahraga, Panduan)
          _buildResultSubTabs(),

          const SizedBox(height: 16),

          // Konten sub-tab yang dipilih
          _buildSelectedResultSubTabContent(),
        ],
      ],
    );
  }

  // Ringkasan Input saat form diciutkan
  Widget _buildCompactInputSummary() {
    final aktivitasOpsi = KalkulatorService.daftarAktivitas.firstWhere(
      (a) => a.id == aktivitas,
      orElse: () => KalkulatorService.daftarAktivitas[2],
    );

    return _modernCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune_rounded, color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parameter Fisik',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$gender • ${height.toInt()} cm • ${weight.toInt()} kg • ${age.toInt()} thn • ${aktivitasOpsi.label}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _isFormExpanded = true),
            icon: const Icon(Icons.edit_outlined, size: 14, color: _green),
            label: Text(
              'Ubah Data',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: _green,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: _green.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form Input Lengkap
  Widget _buildExpandedInputForm() {
    return _modernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parameter Fisik',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green.shade900,
                ),
              ),
              if (_hasil != null)
                GestureDetector(
                  onTap: () => setState(() => _isFormExpanded = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sembunyikan',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
          const SizedBox(height: 18),

          // 2. Tinggi badan diisi langsung oleh pengguna
          _numberInputField(
            label: 'Tinggi Badan',
            unit: 'cm',
            controller: _heightController,
            hint: 'Contoh: 165',
            onChanged: (value) {
              setState(
                () => height = double.tryParse(value.replaceAll(',', '.')) ?? 0,
              );
            },
          ),
          const SizedBox(height: 14),

          // 3. Berat badan diisi langsung oleh pengguna
          _numberInputField(
            label: 'Berat Badan',
            unit: 'kg',
            controller: _weightController,
            hint: 'Contoh: 55',
            onChanged: (value) {
              setState(
                () => weight = double.tryParse(value.replaceAll(',', '.')) ?? 0,
              );
            },
          ),
          const SizedBox(height: 14),

          // 4. Usia diisi langsung oleh pengguna
          _numberInputField(
            label: 'Usia',
            unit: 'tahun',
            controller: _ageController,
            hint: 'Contoh: 21',
            onChanged: (value) {
              setState(
                () => age = double.tryParse(value.replaceAll(',', '.')) ?? 0,
              );
            },
          ),
          const SizedBox(height: 18),

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
            childAspectRatio: 1.45,
            children: KalkulatorService.daftarAktivitas
                .map((opsi) => _aktivitasSelector(opsi))
                .toList(),
          ),

          const SizedBox(height: 22),

          // Tombol Hitung Analisis
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hitungAnalisis,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Hitung Analisis Kesehatan',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
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

  // Hero Card Hasil Analisis Utama
  Widget _buildHeroResultCard() {
    return _modernCard(
      child: Column(
        children: [
          Row(
            children: [
              // Circular BMI Score Ring
              Container(
                width: 76,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kategoriColor().withValues(alpha: 0.1),
                  border: Border.all(
                    color: _kategoriColor().withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _hasil!.bmiDisplay,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kategoriColor(),
                        ),
                      ),
                      Text(
                        'BMI',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kategoriColor().withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _kategoriColor().withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _hasil!.statusLabel,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: _kategoriColor(),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tinggi: ${_hasil!.tinggiBadan.toInt()} cm • Berat: ${_hasil!.beratBadan.toInt()} kg',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kisaran Sehat: ${_hasil!.kisaranBeratDisplay}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // BMR & TDEE Dual Pill
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BMR (Istirahat)',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '≈ ${_hasil!.bmrDisplay}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'kkal/hari',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _green.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: _green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'TDEE (Kebutuhan)',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '≈ ${_hasil!.tdeeDisplay}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                      Text(
                        'kkal/hari',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoggedIn) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, size: 14, color: _green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tersimpan otomatis ke riwayat akun Anda',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedMainTab = 1),
                    child: Text(
                      'Lihat Tren →',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Sub-tabs untuk membagi hasil analisis secara rapi
  Widget _buildResultSubTabs() {
    final tabs = [
      {'index': 0, 'label': '⚡ Nutrisi & Kalori'},
      {'index': 1, 'label': '🥗 Rekomendasi Menu'},
      {'index': 2, 'label': '🏃 Olahraga & Peta'},
      {'index': 3, 'label': '📋 Panduan BMI'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final idx = tab['index'] as int;
          final isSelected = _selectedResultTab == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedResultTab = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Tampilkan konten sub-tab hasil yang dipilih
  Widget _buildSelectedResultSubTabContent() {
    switch (_selectedResultTab) {
      case 0:
        return _buildNutrisiAndEnergySection();
      case 1:
        return _buildMenuRecommendationSection();
      case 2:
        return _buildSportsMapRecommendationSection();
      case 3:
      default:
        return _buildBmiCategoryGuide();
    }
  }

  // ── SUB-TAB 0: NUTRISI & ENERGI ──
  Widget _buildNutrisiAndEnergySection() {
    final currentStatus = _hasil?.status ?? 'Normal';
    final tips = _tips[currentStatus] ?? _tips['Normal']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Makronutrisi Cards
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
                      'Distribusi Makronutrien Harian',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Protein
                  Expanded(
                    child: _macroBox(
                      title: 'PROTEIN',
                      gram: '${_hasil!.proteinDisplay}g',
                      note: 'BB × 1.4 g',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Lemak
                  Expanded(
                    child: _macroBox(
                      title: 'LEMAK',
                      gram: '${_hasil!.lemakDisplay}g',
                      note: '30% TDEE',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Karbohidrat
                  Expanded(
                    child: _macroBox(
                      title: 'KARBOHIDRAT',
                      gram: '${_hasil!.karbohidratDisplay}g',
                      note: 'Sisa Kalori',
                      color: const Color(0xFF20603D),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Pembagian Waktu Makan
        _modernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alokasi Kalori per Waktu Makan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
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
                      label: '☀️ Siang (40%)',
                      kcal: '~$_siangKcal kkal',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _calorieSummaryBox(
                      label: '🌙 Malam (35%)',
                      kcal: '~$_malamKcal kkal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Tips Cepat Sehat
        _modernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tips Cepat Sehat (${_hasil!.statusLabel})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Colors.green.shade900,
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
                        margin: const EdgeInsets.only(top: 6),
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
                            fontSize: 12.5,
                            color: Colors.grey[700],
                            height: 1.45,
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
    );
  }

  Widget _macroBox({
    required String title,
    required String gram,
    required String note,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '≈ $gram',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ── SUB-TAB 1: MENU REKOMENDASI ──
  Widget _buildMenuRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Diet: ${_hasil!.status}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  Text(
                    'Target energi harian Anda: $_totalKcal kkal',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
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
                      'Katalog',
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
        const SizedBox(height: 12),

        // Filter Tabs (Semua, Sarapan, Siang, Malam)
        _buildMealFilterTabs(),
        const SizedBox(height: 14),

        // List Menu
        if (_isLoadingMenus)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
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
    );
  }

  // ── SUB-TAB 3: PANDUAN KATEGORI BMI ──
  Widget _buildBmiCategoryGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panduan Kategori BMI',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 175,
          ),
          itemCount: _bmiCategories.length,
          itemBuilder: (context, index) {
            final cat = _bmiCategories[index];
            final color = cat['color'] as Color;
            final isActive = _hasil != null && _hasil!.status == cat['status'];

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? color : Colors.grey[200]!,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: color,
                          size: 18,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Anda',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat['range'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['desc'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF374151),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ── RIWAYAT & TREN TAB VIEW ──
  // ════════════════════════════════════════════════════════════════════
  Widget _buildRiwayatTabContent() {
    final list = _displayHistoryList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Export Buttons (PNG & PDF) - hanya tampil jika pengguna sudah log in
        if (_isLoggedIn) ...[_buildExportButtons(), const SizedBox(height: 16)],

        if (!_isLoggedIn) ...[
          _buildGuestHistoryCard(),
          const SizedBox(height: 14),
        ],

        if (_isLoadingHistory && list.isEmpty)
          _buildHistoryLoading()
        else if (_historyError != null && list.isEmpty)
          _buildHistoryError()
        else if (list.isEmpty)
          _buildHistoryEmpty()
        else
          _buildHistoryAndTrendContent(),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ── REKOMENDASI PETA OLAHRAGA ──
  // ════════════════════════════════════════════════════════════════════
  Future<void> _openMapsQuery(String query) async {
    final cleanQuery = query.replaceAll('+', ' ').trim();
    bool launched = false;

    // 1. Coba native Android Google Maps intent via geo:0,0?q=...
    final geoUri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(cleanQuery)}');
    try {
      if (await canLaunchUrl(geoUri)) {
        launched = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

    // 2. Jika intent geo belum terbuka, coba URL Google Maps Search
    if (!launched) {
      final webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cleanQuery)}',
      );
      try {
        if (await canLaunchUrl(webUri)) {
          launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {}

      // 3. Fallback platformDefault / browser
      if (!launched) {
        try {
          launched = await launchUrl(webUri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka Google Maps. Pastikan aplikasi Google Maps atau browser terpasang.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildSportsMapRecommendationSection() {
    if (_hasil == null) return const SizedBox.shrink();

    final status = _hasil!.status;
    final isLowImpact = status == 'Berlebih' || status == 'Obesitas';
    final isUnderweight = status == 'Kurus';

    final String categoryTitle;
    final String sportSubtitle;
    final String reasonText;
    final Color accentColor;
    final IconData mainIcon;
    final String initialMapCat;
    final String mapsQuery;
    final List<String> quickTags;

    if (isLowImpact) {
      categoryTitle = 'Fasilitas Low-Impact';
      sportSubtitle = 'Jalur Jogging & Kolam Renang';
      reasonText =
          'Berdasarkan status BMI Anda (${_hasil!.statusLabel}), olahraga low-impact seperti berenang atau jalan santai di lintasan jogging sangat dianjurkan untuk membakar lemak secara aman tanpa membebani persendian lutut.';
      accentColor = const Color(0xFF0284C7);
      mainIcon = Icons.pool_rounded;
      initialMapCat = 'Aktivitas Ringan';
      mapsQuery = 'jalur jogging kolam renang terdekat';
      quickTags = ['🏊 Kolam Renang', '🏃 Jogging Track', '🌿 Jalur Santai'];
    } else if (isUnderweight) {
      categoryTitle = 'Fitness Center & Gym';
      sportSubtitle = 'Latihan Beban & Massa Otot';
      reasonText =
          'Berdasarkan status BMI Anda (${_hasil!.statusLabel}), Anda disarankan untuk berlatih resistensi atau angkat beban di fitness center / gym guna menstimulasi pertumbuhan massa otot dan menaikkan berat badan ideal.';
      accentColor = const Color(0xFF7C3AED);
      mainIcon = Icons.fitness_center_rounded;
      initialMapCat = 'Gym';
      mapsQuery = 'gym terdekat';
      quickTags = [
        '🏋️ Fitness Center',
        '💪 Free Weight Gym',
        '🔥 Mesin Beban',
      ];
    } else {
      categoryTitle = 'Lapangan & Komunitas Olahraga';
      sportSubtitle = 'Lapangan Terbuka & Sport Complex';
      reasonText =
          'Hebat! Berat badan Anda (${_hasil!.statusLabel}) sudah berada di rentang ideal. Pertahankan daya tahan fisik dan kebugaran jantung dengan aktif berolahraga di lapangan terbuka atau sarana olahraga bersama komunitas.';
      accentColor = const Color(0xFF16A34A);
      mainIcon = Icons.sports_tennis_rounded;
      initialMapCat = 'Lapangan';
      mapsQuery = 'lapangan olahraga terdekat';
      quickTags = [
        '🏸 Lapangan Badminton',
        '⚽ Sepak Bola',
        '🏟️ Stadion Kompleks',
      ];
    }

    // Filter dynamic places dari API Lokasi Olahraga
    List<Map<String, dynamic>> dynamicPlaces = [];
    if (_sportsLocations.isNotEmpty) {
      if (isLowImpact) {
        dynamicPlaces = _sportsLocations.where((loc) {
          final cat = (loc['category'] ?? '').toString().toLowerCase();
          final name = (loc['name'] ?? '').toString().toLowerCase();
          return cat.contains('ringan') ||
              cat.contains('low') ||
              name.contains('jogging') ||
              name.contains('renang') ||
              name.contains('taman');
        }).toList();
      } else if (isUnderweight) {
        dynamicPlaces = _sportsLocations.where((loc) {
          final cat = (loc['category'] ?? '').toString().toLowerCase();
          final name = (loc['name'] ?? '').toString().toLowerCase();
          return cat.contains('gym') ||
              cat.contains('fitness') ||
              name.contains('gym') ||
              name.contains('fitness');
        }).toList();
      } else {
        dynamicPlaces = _sportsLocations.where((loc) {
          final cat = (loc['category'] ?? '').toString().toLowerCase();
          final name = (loc['name'] ?? '').toString().toLowerCase();
          return cat.contains('lapangan') ||
              cat.contains('stadion') ||
              cat.contains('komunitas') ||
              name.contains('lapangan') ||
              name.contains('gor') ||
              name.contains('center');
        }).toList();
      }

      // Jika kategori spesifik tidak cukup, ambil lokasi lainnya
      if (dynamicPlaces.isEmpty) {
        dynamicPlaces = _sportsLocations.take(3).toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.map_rounded, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi Peta Olahraga',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fasilitas olahraga yang disesuaikan dengan hasil BMI Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
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
                    builder: (_) => LocationOlahragaPage(
                      onBack: () => Navigator.pop(context),
                      initialCategory: initialMapCat,
                      bmiCategory: _hasil!.status,
                      bmiRecommendationReason: reasonText,
                      preloadedLocations: _sportsLocations,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Peta Lengkap',
                      style: GoogleFonts.poppins(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios, size: 11, color: accentColor),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Banner Card Rekomendasi Khusus Kategori BMI
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(mainIcon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BMI: ${_hasil!.statusLabel}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                categoryTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sportSubtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded, size: 15, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reasonText,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black87,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // List fasilitas olahraga dari API
        if (_isLoadingSportsLocations)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Memuat rekomendasi lokasi olahraga...',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else if (dynamicPlaces.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Belum ada lokasi spesifik untuk kategori ini di database.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...dynamicPlaces.map(
            (place) => _buildSportLocationCard(place, accentColor),
          ),

        const SizedBox(height: 8),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationOlahragaPage(
                        onBack: () => Navigator.pop(context),
                        initialCategory: initialMapCat,
                        bmiCategory: _hasil!.status,
                        bmiRecommendationReason: reasonText,
                        preloadedLocations: _sportsLocations,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.explore_rounded,
                  size: 17,
                  color: Colors.white,
                ),
                label: Text(
                  'Buka Peta Lengkap',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () => _openMapsQuery(mapsQuery),
                icon: const Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: _green,
                ),
                label: Text(
                  'Cari Sekitar',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: _green, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSportLocationCard(Map<String, dynamic> loc, Color accentColor) {
    final placeColor = loc['color'] as Color? ?? accentColor;
    final mapQuery = (loc['mapQuery'] ?? loc['name'] ?? '').toString();
    final String distanceStr = (loc['distance'] ?? 'Belum diketahui')
        .toString();
    final ratingVal = loc['rating'];
    final String hoursStr = (loc['hours'] ?? 'Jam operasional di Maps')
        .toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openMapsQuery(mapQuery),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: placeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    loc['icon'] as IconData? ?? Icons.location_on_rounded,
                    color: placeColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              loc['name']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: placeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              loc['category']?.toString() ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: placeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        loc['address']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distanceStr,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (ratingVal != null) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$ratingVal',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '🕒 $hoursStr',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Rute',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ── WIDGETS MENU & FILTER ──
  // ════════════════════════════════════════════════════════════════════
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
                fontSize: 13.5,
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
      {'id': 'siang', 'label': '☀️ Siang (~$_siangKcal kkal)'},
      {'id': 'malam', 'label': '🌙 Malam (~$_malamKcal kkal)'},
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
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _green : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.black87,
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
                    height: 135,
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
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.amber,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${menu.kalori} kkal',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 3),
                  Text(
                    menu.deskripsi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 12,
                              color: _green,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${menu.kalori} kkal',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${menu.waktuMemasak} mnt',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Lihat Resep',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
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

  // ════════════════════════════════════════════════════════════════════
  // ── RIWAYAT & EKSPOR LAPORAN ──
  // ════════════════════════════════════════════════════════════════════
  Widget _buildExportButtons() {
    if (!_isLoggedIn) return const SizedBox.shrink();

    final bool isExporting = _isExportingPng || _isExportingPdf;

    return Row(
      children: [
        // Tombol Unduh PNG
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _green,
              side: const BorderSide(color: _green, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: isExporting
                ? null
                : () async {
                    final dataToExport = _exportHistoryList;
                    if (dataToExport.isEmpty) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Belum ada data untuk diunduh. Silakan hitung analisis BMI terlebih dahulu.',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() => _isExportingPng = true);
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sedang memproses dan menyimpan gambar PNG...',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1F2937),
                        duration: const Duration(seconds: 15),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );

                    await DownloadNotificationService().showDownloadStart(
                      id: 101,
                      title: 'Menyimpan Gambar PNG',
                      body: 'Sedang memproses gambar kartu riwayat FitLife...',
                    );

                    final ok =
                        await KartuKesehatanExportService.captureAndDownloadPng(
                          _riwayatPngKey,
                        );

                    if (mounted) {
                      setState(() => _isExportingPng = false);
                      messenger.hideCurrentSnackBar();
                      if (ok) {
                        await DownloadNotificationService().showDownloadComplete(
                          id: 101,
                          title: 'Unduhan PNG Selesai',
                          body:
                              'Gambar kartu riwayat berhasil disimpan ke perangkat.',
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Gambar PNG berhasil diunduh dan disimpan ke perangkat!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF20603D),
                            duration: const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else {
                        await DownloadNotificationService().showDownloadFailed(
                          id: 101,
                          title: 'Unduhan PNG Gagal',
                          body:
                              'Gagal membuat dan menyimpan gambar kartu riwayat.',
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Gagal membuat dan menyimpan gambar PNG. Silakan coba lagi.',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
            icon: _isExportingPng
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _green,
                    ),
                  )
                : const Icon(Icons.image_outlined, size: 18),
            label: Text(
              _isExportingPng ? 'Menyimpan...' : 'Unduh PNG',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: _green,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Tombol Unduh PDF
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: isExporting
                ? null
                : () async {
                    final dataToExport = _exportHistoryList;
                    if (dataToExport.isEmpty) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Belum ada data untuk diunduh. Silakan hitung analisis BMI terlebih dahulu.',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() => _isExportingPdf = true);
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sedang membuat dan memproses dokumen PDF...',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1F2937),
                        duration: const Duration(seconds: 15),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );

                    await DownloadNotificationService().showDownloadStart(
                      id: 102,
                      title: 'Mengunduh Laporan PDF',
                      body: 'Sedang menyusun dokumen laporan BMI FitLife...',
                    );

                    final ok =
                        await KartuKesehatanExportService.exportRiwayatToPdf(
                          dataToExport,
                        );

                    if (mounted) {
                      setState(() => _isExportingPdf = false);
                      messenger.hideCurrentSnackBar();
                      if (ok) {
                        await DownloadNotificationService().showDownloadComplete(
                          id: 102,
                          title: 'Unduhan PDF Selesai',
                          body:
                              'Dokumen laporan PDF berhasil disimpan ke perangkat.',
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Dokumen PDF berhasil diunduh dan disimpan ke perangkat!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF20603D),
                            duration: const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else {
                        await DownloadNotificationService().showDownloadFailed(
                          id: 102,
                          title: 'Unduhan PDF Gagal',
                          body: 'Gagal membuat dokumen laporan PDF.',
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Gagal membuat dokumen PDF. Silakan coba lagi.',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: Text(
              _isExportingPdf ? 'Menyimpan...' : 'Unduh PDF',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'kurus':
        return Colors.blue;
      case 'normal':
        return const Color(0xFF20603D);
      case 'berlebih':
        return Colors.orange;
      case 'obesitas':
        return Colors.red;
      default:
        return const Color(0xFF20603D);
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
              'Gagal menghapus riwayat: $e',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildHistoryAndTrendContent() {
    final list = _displayHistoryList;
    if (list.isEmpty) return const SizedBox.shrink();

    final latest = list.first;
    final oldest = list.last;
    final double beratTerbaru = latest.beratBadan;
    final double bmiTerkini = latest.bmi;
    final String statusTerkini = latest.status;
    final double totalPerubahan = beratTerbaru - oldest.beratBadan;

    final String statusTren;
    if (list.length == 1) {
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
          totalRecords: list.length,
        ),
        const SizedBox(height: 14),

        // 2. Chart or Single-Record Banner
        if (list.length == 1)
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
              '${list.length} Catatan Tersimpan',
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? const Color(0xFF111827),
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? _green).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor ?? _green,
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
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleRecordBanner(PerhitunganModel single) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: _green,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Pertama Tersimpan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lakukan perhitungan lagi di waktu berbeda untuk memantau grafik tren berat badan Anda.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
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
    final chronological = _displayHistoryList.reversed.toList();

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
            height: 200,
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= chronological.length) {
                          return const SizedBox.shrink();
                        }
                        if (chronological.length > 5 &&
                            idx % ((chronological.length / 4).ceil()) != 0 &&
                            idx != chronological.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final date = chronological[idx].createdAt;
                        final label = date != null
                            ? DateFormat('d/M').format(date)
                            : '#${idx + 1}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: _green,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _green.withValues(alpha: 0.22),
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
    return _modernCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.blue,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Simpan Riwayat Anda',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masuk ke akun FitLife Anda untuk menyimpan catatan perhitungan BMI, melihat grafik perkembangan, dan mengunduh laporan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: _green),
      ),
    );
  }

  Widget _buildHistoryError() {
    return _modernCard(
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat riwayat: $_historyError',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh, size: 14, color: _green),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontSize: 12, color: _green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEmpty() {
    return _modernCard(
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, color: _green, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum Ada Riwayat Tersimpan',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hitung analisis BMI Anda di tab Kalkulator untuk mulai mencatat riwayat kesehatan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => _selectedMainTab = 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Mulai Hitung BMI',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final list = _displayHistoryList;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildHistoryItemCard(item);
      },
    );
  }

  Widget _buildHistoryItemCard(PerhitunganModel item) {
    final statusColor = _statusColor(item.status);

    return InkWell(
      onTap: () {
        // Memuat parameter ke form kalkulator dan berpindah ke tab Kalkulator
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
          _selectedMainTab = 0; // Pindah langsung ke tab kalkulator
          _isFormExpanded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Parameter riwayat (${item.beratBadan.toStringAsFixed(0)} kg, ${item.tinggiBadan.toStringAsFixed(0)} cm) dimuat ke form kalkulator.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                if (item.id != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _deleteHistoryItem(item),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.bmiDisplay,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'BMI',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.beratBadan.toStringAsFixed(1)} kg  •  ${item.tinggiBadan.toStringAsFixed(0)} cm',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ideal: ${item.kisaranBeratDisplay}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
