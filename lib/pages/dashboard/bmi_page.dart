import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../../services/menu_service.dart';
import '../../models/menu_model.dart';
import 'menu_detail.dart';

class BmiPage extends StatefulWidget {
  final VoidCallback onBack;
  const BmiPage({super.key, required this.onBack});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  final MenuService _menuService = MenuService();
  bool _isLoadingMenus = false;

  String gender = "Pria";
  double height = 170;
  double weight = 65;
  double? bmiResult;
  String kategori = "";
  String statusApi = "";
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
      'desc': 'Pertahankan gaya hidup aktif.',
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
      'Lakukan latihan beban 3x seminggu untuk massa otot.',
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

  String _getApiStatus() {
    if (bmiResult == null) return 'Normal';
    if (bmiResult! < 18.5) return 'Kurus';
    if (bmiResult! < 25) return 'Normal';
    if (bmiResult! < 30) return 'Berlebih';
    return 'Obesitas';
  }

  void hitungBMI() async {
    double tinggiMeter = height / 100;
    double bmi = weight / pow(tinggiMeter, 2);

    String hasilKategori;
    if (bmi < 18.5) {
      hasilKategori = "Kekurangan Berat";
    } else if (bmi < 25) {
      hasilKategori = "Normal";
    } else if (bmi < 30) {
      hasilKategori = "Kelebihan Berat";
    } else {
      hasilKategori = "Obesitas";
    }

    setState(() {
      bmiResult = bmi;
      kategori = hasilKategori;
      statusApi = _getApiStatus();
    });

    // Fetch recommended menus
    _fetchRecommendedMenus();
  }

  Future<void> _fetchRecommendedMenus() async {
    setState(() => _isLoadingMenus = true);
    try {
      final menus = await _menuService.getMenusByTarget(statusApi);
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

  Color kategoriColor() {
    if (bmiResult == null) return Colors.grey;
    if (bmiResult! < 18.5) return Colors.blue;
    if (bmiResult! < 25) return _green;
    if (bmiResult! < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _modernCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                ? _green.withOpacity(0.12)
                : Colors.grey.withOpacity(0.06),
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

  @override
  Widget build(BuildContext context) {
    final currentStatus = bmiResult != null ? statusApi : 'Normal';
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
                    color: Colors.grey.withOpacity(0.1),
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
              Text(
                "Kalkulator BMI",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Form Card ──
          _modernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jenis Kelamin",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _genderSelector("Pria"),
                    const SizedBox(width: 10),
                    _genderSelector("Wanita"),
                  ],
                ),
                const SizedBox(height: 24),

                // Height slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tinggi Badan",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: "${height.toInt()} ",
                            style: TextStyle(color: _green, fontSize: 22),
                          ),
                          TextSpan(
                            text: "CM",
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
                  activeColor: _green,
                  inactiveColor: Colors.grey[200],
                  onChanged: (value) => setState(() => height = value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "100 cm",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      "220 cm",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Weight slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Berat Badan",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: "${weight.toInt()} ",
                            style: TextStyle(color: _green, fontSize: 22),
                          ),
                          TextSpan(
                            text: "KG",
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
                  activeColor: _green,
                  inactiveColor: Colors.grey[200],
                  onChanged: (value) => setState(() => weight = value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "30 kg",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      "200 kg",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hitungBMI,
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
                          "Hitung BMI Saya",
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

          // ── Result Card ──
          if (bmiResult == null)
            _modernCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
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
                      "BMI membantu mengetahui apakah berat badan Anda sudah ideal.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (bmiResult != null) ...[
            _modernCard(
              child: Column(
                children: [
                  // BMI Circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kategoriColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kategoriColor().withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        bmiResult!.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kategoriColor(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kategoriColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kategoriColor().withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      kategori,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kategoriColor(),
                        fontSize: 24,
                      ),
                    ),
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
                          color: Colors.amber.withOpacity(0.12),
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
                        "Tips Cepat Sehat",
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
                            decoration: BoxDecoration(
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

          // ── BMI Category Cards ──
          Text(
            "Kategori BMI",
            style: GoogleFonts.poppins(
              fontSize: 17,
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
                  bmiResult != null && statusApi == (cat['status'] as String);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive
                        ? color.withOpacity(0.5)
                        : Colors.grey[200]!,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.1),
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
                        color: color.withOpacity(0.1),
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

          // ── Recommended Menus ──
          if (bmiResult != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: _green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Menu Diet: $statusApi",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Pilihan nutrisi terbaik untuk kondisi Anda saat ini.",
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
                      "Belum ada menu untuk kategori ini.",
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
              color: Colors.black.withOpacity(0.05),
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
