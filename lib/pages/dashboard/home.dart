import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/bmi_page.dart';
import '../dashboard/artikel_page.dart';
import 'package:fitlife/pages/dashboard/profile_page.dart';
import 'package:fitlife/pages/dashboard/guest_profile_page.dart';
import 'package:fitlife/pages/dashboard/menu_page.dart';
import 'package:fitlife/pages/scan/scan_barcode_screen.dart';
import 'package:fitlife/pages/lokasi/lokasi_olahraga_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final List<int> _history = [];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    if (mounted) {
      setState(() {
        _isLoggedIn = userData != null && userData.isNotEmpty;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      _history.add(_selectedIndex);
      setState(() => _selectedIndex = index);
    }
  }

  void _goBack() {
    if (_history.isNotEmpty) {
      setState(() {
        _selectedIndex = _history.removeLast();
      });
    } else {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  // ================= HOME CONTENT =================
  Widget _buildHomeContent() {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 370;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _buildTopHeader(isSmall),
        const SizedBox(height: 12),
        _buildHeroSection(isSmall),
        const SizedBox(height: 12),
        _buildDailyTipCard(isSmall),
        const SizedBox(height: 20),
        _buildFeatureSection(isSmall),
        const SizedBox(height: 28),
        _buildSectionHeader(
          title: "Menu Sehat Populer",
          actionText: "Lihat Semua",
          icon: Icons.restaurant_rounded,
          onActionTap: () => _onItemTapped(1), // Menu = index 1
          isSmall: isSmall,
        ),
        const SizedBox(height: 14),
        _buildLatestMenu(isSmall),
        const SizedBox(height: 28),
        _buildSectionHeader(
          title: "Artikel & Tips Sehat",
          actionText: "Lihat Semua",
          icon: Icons.article_rounded,
          onActionTap: () => _onItemTapped(2), // Artikel = index 2
          isSmall: isSmall,
        ),
        const SizedBox(height: 14),
        _buildLatestArtikel(isSmall),
      ],
    );
  }

  // --- 1. Top Header with User Greeting & Brand Badge ---
  Widget _buildTopHeader(bool isSmall) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isSmall ? 16 : 20, 12, isSmall ? 16 : 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF66), Color(0xFF00CC52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF66).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF111827),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, Sahabat FitLife! 👋",
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    "Siap bugar & hidup sehat hari ini?",
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 10.5 : 11.5,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF66).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00CC52).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Color(0xFF00CC52),
                ),
                const SizedBox(width: 3),
                Text(
                  "FitLife.id",
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Hero Section Banner ---
  Widget _buildHeroSection(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmall ? 16 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8FDF2), Color(0xFFD1FAE5)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF00FF66).withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF66).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF66).withValues(alpha: 0.12),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: Color(0xFF00CC52),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Asisten Hidup Sehat",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BmiPage(onBack: () => Navigator.pop(context)),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00CC52),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00CC52).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Cek BMI",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Capai Tubuh Ideal & Bugar Bersama FitLife",
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Pantau kalkulasi BMI, telusuri asupan gizi sehat, serta cari tempat olahraga terdekat.",
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 11 : 11.5,
                    height: 1.35,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Daily Tip Card (Slim) ---
  Widget _buildDailyTipCard(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00FF66).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFF00CC52),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF4B5563)),
                  children: [
                    TextSpan(
                      text: "Tips Hari Ini: ",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const TextSpan(
                      text: "Minum air putih minimal 2L & sempatkan jalan 20 menit.",
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

  // --- 4. Feature Section (4 Quick Cards) ---
  Widget _buildFeatureSection(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fitur Utama",
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.monitor_weight_rounded,
                  title: "Kalkulator\nBMI",
                  color: Colors.orange,
                  badgeText: "Cek",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BmiPage(onBack: () => Navigator.pop(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.restaurant_menu_rounded,
                  title: "Menu\nSehat",
                  color: Colors.pink,
                  badgeText: "Nutrisi",
                  onTap: () => _onItemTapped(1), // Menu = index 1
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.place_rounded,
                  title: "Lokasi\nOlahraga",
                  color: Colors.indigo,
                  badgeText: "Dekat",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LocationOlahragaPage(onBack: () => Navigator.pop(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: "Scan\nMakanan",
                  color: const Color(0xFF00CC52),
                  badgeText: "AI",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanBarcodeScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. Section Header ---
  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required IconData icon,
    required VoidCallback onActionTap,
    required bool isSmall,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF00CC52)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF66).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    actionText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFF15803D),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Latest Menu Carousel ---
  Widget _buildLatestMenu(bool isSmall) {
    final titles = [
      "Salad Buah Segar",
      "Oatmeal Berries",
      "Ayam Panggang Lemon",
    ];
    final cals = ["250 kcal", "320 kcal", "450 kcal"];
    final tags = ["Rendah Kalori", "Tinggi Serat", "Tinggi Protein"];
    final images = [
      "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1517673132405-a56a62b18caf?q=80&w=400&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1532550907401-a500c9a57435?q=80&w=400&auto=format&fit=crop",
    ];

    return SizedBox(
      height: 195,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onItemTapped(1), // Menu = index 1
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        child: Image.network(
                          images[index],
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 12,
                                color: Colors.orangeAccent,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                cals[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tags[index],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00CC52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 7. Latest Articles List ---
  Widget _buildLatestArtikel(bool isSmall) {
    final titles = [
      "Cara Mulai Diet Sehat untuk Pemula Tanpa Menyiksa",
      "Pentingnya Hidrasi Tubuh Saat Berolahraga",
      "5 Mitos Tentang Diet yang Harus Kamu Ketahui",
    ];
    final categories = ["Diet & Nutrisi", "Kebugaran", "Gaya Hidup"];
    final readTimes = ["3 mnt baca", "4 mnt baca", "2 mnt baca"];
    final images = [
      "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=400&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1523362628745-0c100150b504?q=80&w=400&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1542204165-65bf26472b9b?q=80&w=400&auto=format&fit=crop",
    ];

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _onItemTapped(2), // Artikel = index 2
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[index],
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categories[index],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            readTimes[index],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        titles[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeContent(), // 0 - Home
            MenuPage(onBack: _goBack), // 1 - Menu
            ArtikelPage(onBack: _goBack), // 2 - Artikel
            _isLoggedIn ? const ProfilePage() : const GuestProfilePage(), // 3 - Profil
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(index: 0, icon: Icons.home_rounded, label: "Home"),
              _buildNavItem(
                index: 1,
                icon: Icons.restaurant_menu_rounded,
                label: "Menu",
              ),
              _buildScanNavItem(),
              _buildNavItem(
                index: 2,
                icon: Icons.article_rounded,
                label: "Artikel",
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_rounded,
                label: "Profil",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanNavItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanBarcodeScreen()),
        );
      },
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FF66), Color(0xFF00CC52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF66).withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF111827),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00CC52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00FF66).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? const Color(0xFF00CC52)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF00CC52)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
