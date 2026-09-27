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

  //HOME CONTENT
  Widget _buildHomeContent() {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 370;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        _buildHeroSection(isSmall),
        const SizedBox(height: 24),
        _buildFeatureSection(isSmall),
        const SizedBox(height: 24),
        _buildSectionHeader(
          "Menu Sehat Terbaru",
          "Lihat Semua",
          () => _onItemTapped(2),
          isSmall,
        ),
        const SizedBox(height: 16),
        _buildLatestMenu(isSmall),
        const SizedBox(height: 24),
        _buildSectionHeader(
          "Artikel Terbaru",
          "Lihat Semua",
          () => _onItemTapped(3),
          isSmall,
        ),
        const SizedBox(height: 16),
        _buildLatestArtikel(isSmall),
      ],
    );
  }

  Widget _buildHeroSection(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isSmall ? 20 : 24,
        isSmall ? 24 : 30,
        isSmall ? 20 : 24,
        30,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6FFF3), Color(0xFFCFFFEA)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF66).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selamat datang di",
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "FitLife",
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 32 : 36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Mulai perjalanan sehatmu hari ini. Pantau BMI, temukan resep lezat, dan baca tips kesehatan terbaik.",
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 13 : 14,
              height: 1.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _onItemTapped(1), // Ke halaman BMI
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF66),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 20 : 24,
                vertical: isSmall ? 12 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF00FF66).withOpacity(0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monitor_weight_rounded,
                  size: isSmall ? 18 : 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  "Hitung BMI Sekarang",
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fitur Unggulan",
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.monitor_weight_rounded,
                  title: "BMI\nKalkulator",
                  color: Colors.orange,
                  onTap: () => _onItemTapped(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.restaurant_menu_rounded,
                  title: "Menu\nSehat",
                  color: Colors.pink,
                  onTap: () => _onItemTapped(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.menu_book_rounded,
                  title: "Artikel\nKesehatan",
                  color: Colors.blue,
                  onTap: () => _onItemTapped(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSquareFeatureCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: "Scan\nMakanan",
                  color: const Color(0xFF00CC52),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onActionTap,
    bool isSmall,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1AB673),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestMenu(bool isSmall) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final titles = [
            "Salad Buah Segar",
            "Oatmeal Berries",
            "Ayam Panggang",
          ];
          final cals = ["250 kcal", "320 kcal", "450 kcal"];
          final images = [
            "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop",
            "https://images.unsplash.com/photo-1517673132405-a56a62b18caf?q=80&w=400&auto=format&fit=crop",
            "https://images.unsplash.com/photo-1532550907401-a500c9a57435?q=80&w=400&auto=format&fit=crop",
          ];

          return GestureDetector(
            onTap: () => _onItemTapped(2),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      images[index],
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 12,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cals[index],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF6B7280),
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
        },
      ),
    );
  }

  Widget _buildLatestArtikel(bool isSmall) {
    final titles = [
      "Cara Mulai Diet Sehat untuk Pemula Tanpa Menyiksa",
      "Pentingnya Hidrasi Tubuh Saat Berolahraga",
      "5 Mitos Tentang Diet yang Harus Kamu Ketahui",
    ];
    final categories = ["Diet & Nutrisi", "Kesehatan", "Gaya Hidup"];
    final images = [
      "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=400&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1523362628745-0c100150b504?q=80&w=400&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1542204165-65bf26472b9b?q=80&w=400&auto=format&fit=crop",
    ];

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _onItemTapped(3),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF66).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categories[index],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1AB673),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        titles[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
            _buildHomeContent(), // 0
            BmiPage(onBack: _goBack), // 1
            MenuPage(onBack: _goBack), // 2
            ArtikelPage(onBack: _goBack), // 3
            LocationOlahragaPage(onBack: _goBack), // 4
            _isLoggedIn ? const ProfilePage() : const GuestProfilePage(), // 5
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
                icon: Icons.calculate_rounded,
                label: "BMI",
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.restaurant_menu_rounded,
                label: "Menu",
              ),
              _buildScanNavItem(),
              _buildNavItem(
                index: 3,
                icon: Icons.article_rounded,
                label: "Artikel",
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.place_rounded,
                label: "Lokasi",
              ),
              _buildNavItem(
                index: 5,
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
