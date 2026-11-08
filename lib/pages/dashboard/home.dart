import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/bmi_page.dart';
import '../dashboard/artikel_page.dart';
import 'package:fitlife/pages/dashboard/profile_page.dart';
import 'package:fitlife/pages/dashboard/guest_profile_page.dart';
import 'package:fitlife/pages/dashboard/menu_page.dart';
import 'package:fitlife/pages/scan/scan_barcode_screen.dart';
import 'package:fitlife/pages/lokasi/lokasi_olahraga_page.dart';
import 'package:fitlife/pages/chat/chat_panel.dart';
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
  String? _userName;
  bool _isChatOpen = false;
  String? _lokasiInitialCategory;
  String? _lokasiBmiCategory;
  String? _lokasiBmiRecommendationReason;
  List<Map<String, dynamic>>? _lokasiPreloadedLocations;
  int _lokasiNavEpoch = 0;

  void _openLokasiFromBmi({
    String? category,
    String? bmiCategory,
    String? bmiRecommendationReason,
    List<Map<String, dynamic>>? preloadedLocations,
  }) {
    setState(() {
      _lokasiInitialCategory = category;
      _lokasiBmiCategory = bmiCategory;
      _lokasiBmiRecommendationReason = bmiRecommendationReason;
      _lokasiPreloadedLocations = preloadedLocations;
      _lokasiNavEpoch++;
    });
    _onItemTapped(5);
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    String? parsedName;
    if (userData != null && userData.isNotEmpty) {
      try {
        final decoded = jsonDecode(userData);
        if (decoded is Map<String, dynamic>) {
          final rawName =
              decoded['name']?.toString() ?? decoded['username']?.toString();
          if (rawName != null && rawName.trim().isNotEmpty) {
            parsedName = rawName.trim();
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isLoggedIn = userData != null && userData.isNotEmpty;
        _userName = parsedName;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      _checkLoginStatus();
    }
    if (index != _selectedIndex) {
      _history.add(_selectedIndex);
      setState(() => _selectedIndex = index);
    }
  }

  void _goBack() {
    _checkLoginStatus();
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

  String _getGreetingEn() {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 12) {
      return 'Good Morning'; // Pukul 04.00 - 11.59
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon'; // Pukul 12.00 - 16.59
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening'; // Pukul 17.00 - 21.59 (Salam saat bertemu di malam hari)
    } else {
      return 'Good Night'; // Pukul 22.00 - 03.59 (Salam perpisahan/mau tidur)
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
        const SizedBox(height: 24),
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
    final displayName = (_userName != null && _userName!.isNotEmpty)
        ? _userName!
        : 'Sahabat FitLife';

    return Padding(
      padding: EdgeInsets.fromLTRB(isSmall ? 16 : 20, 12, isSmall ? 16 : 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: isSmall ? 34 : 38,
                  height: isSmall ? 34 : 38,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: isSmall ? 34 : 38,
                      height: isSmall ? 34 : 38,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_getGreetingEn()}, $displayName! 👋",
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Siap bugar & hidup sehat hari ini?",
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 10.5 : 11.5,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
            colors: [Color(0xFFEBF3ED), Color(0xFFDCECE0)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF20603D).withValues(alpha: 0.20),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF20603D).withValues(alpha: 0.06),
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
                  color: const Color(0xFF20603D).withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
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
                            color: Color(0xFF20603D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Asisten Hidup Sehat",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF20603D),
                            ),
                          ),
                        ],
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
                  "Temukan inspirasi makanan sehat dan mulai kebiasaan hidup lebih aktif bersama FitLife.",
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
            color: const Color(0xFF20603D).withValues(alpha: 0.15),
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
                color: const Color(0xFF20603D).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFF20603D),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF4B5563),
                  ),
                  children: [
                    TextSpan(
                      text: "Tips Hari Ini: ",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const TextSpan(
                      text:
                          "Minum air putih minimal 2L & sempatkan jalan 20 menit.",
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
              Icon(icon, size: 20, color: const Color(0xFF20603D)),
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
                color: const Color(0xFF20603D).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    actionText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF20603D),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFF20603D),
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
                            color: const Color(0xFF20603D),
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
                              color: const Color(
                                0xFF20603D,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categories[index],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF20603D),
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
    const navBarBg = Color(0xFFFFFFFF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: navBarBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeContent(), // 0 - Home
                  MenuPage(onBack: _goBack), // 1 - Menu (diakses dari Home)
                  ArtikelPage(
                    onBack: _goBack,
                  ), // 2 - Artikel (diakses dari Home)
                  _isLoggedIn
                      ? const ProfilePage()
                      : const GuestProfilePage(), // 3 - Profil
                  BmiPage(
                    onBack: _goBack,
                    onOpenMenu: () => _onItemTapped(1),
                    onOpenMaps: _openLokasiFromBmi,
                  ), // 4 - Kalkulator BMI
                  LocationOlahragaPage(
                    onBack: _goBack,
                    initialCategory: _lokasiInitialCategory,
                    bmiCategory: _lokasiBmiCategory,
                    bmiRecommendationReason: _lokasiBmiRecommendationReason,
                    preloadedLocations: _lokasiPreloadedLocations,
                    navEpoch: _lokasiNavEpoch,
                  ), // 5 - Lokasi Olahraga
                ],
              ),
            ),
            if (_isChatOpen)
              Positioned(
                right: 12,
                bottom: 76,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width >= 420
                      ? 380
                      : MediaQuery.sizeOf(context).width - 24,
                  height: (MediaQuery.sizeOf(context).height * 0.65).clamp(
                    320.0,
                    620.0,
                  ),
                  child: ChatPanel(
                    onClose: () {
                      setState(() {
                        _isChatOpen = false;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF247447),
          onPressed: () {
            setState(() {
              _isChatOpen = !_isChatOpen;
            });
          },
          child: _isChatOpen
              ? const Icon(Icons.close_rounded, color: Colors.white)
              : Image.asset(
                  'assets/maskot-ai/first.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.chat_rounded, color: Colors.white),
                ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ================= BOTTOM NAV (curved notch cradle) =================
  static const double _navBarHeight = 68.0;
  static const double _floatOverhang = 28.0;
  static const double _scanSize = 58.0;

  Widget _buildBottomNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomSafe = bottomPadding > 0 ? bottomPadding : 6.0;

    const barBg = Color(0xFFFFFFFF);
    const borderLine = Color(0xFFE5ECE7);
    const shadowCol = Colors.transparent;

    return _OverflowHitTest(
      overflowTop: _floatOverhang,
      child: SizedBox(
        height: _navBarHeight + bottomSafe,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 1. Background melengkung cradle notch
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: CustomPaint(
                painter: const _NotchedNavPainter(
                  color: barBg,
                  shadowColor: shadowCol,
                  borderColor: borderLine,
                  notchRadius: 46.0,
                  notchDepth: 38.0,
                ),
              ),
            ),

            // 2. Navigation items (tinggi terisolasi _navBarHeight, aman overflow)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _navBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _InteractiveNavItem(
                      index: 0,
                      activeIcon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                      label: "Home",
                      isActive: _selectedIndex == 0,
                      isDark: false,
                      onTap: () => _onItemTapped(0),
                    ),
                  ),
                  Expanded(
                    child: _InteractiveNavItem(
                      index: 4,
                      activeIcon: Icons.calculate_rounded,
                      inactiveIcon: Icons.calculate_outlined,
                      label: "Kalkulator",
                      isActive: _selectedIndex == 4,
                      isDark: false,
                      onTap: () => _onItemTapped(4),
                    ),
                  ),
                  // Spacer tengah untuk cekungan tombol scan
                  const Expanded(child: SizedBox()),
                  Expanded(
                    child: _InteractiveNavItem(
                      index: 5,
                      activeIcon: Icons.location_on_rounded,
                      inactiveIcon: Icons.location_on_outlined,
                      label: "Lokasi",
                      isActive: _selectedIndex == 5,
                      isDark: false,
                      onTap: () => _onItemTapped(5),
                    ),
                  ),
                  Expanded(
                    child: _InteractiveNavItem(
                      index: 3,
                      activeIcon: Icons.person_rounded,
                      inactiveIcon: Icons.person_outline_rounded,
                      label: "Profil",
                      isActive: _selectedIndex == 3,
                      isDark: false,
                      onTap: () => _onItemTapped(3),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Tombol Scan Hero melayang di tengah cekungan
            Positioned(
              top: -24.0,
              left: 0,
              right: 0,
              child: Center(
                child: _HeroScanButton(
                  isDark: false,
                  scanSize: _scanSize,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanBarcodeScreen()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item navigasi interaktif dengan micro-animasi khusus tiap ikon, morphing icon, dan pill glow.
class _InteractiveNavItem extends StatefulWidget {
  const _InteractiveNavItem({
    required this.index,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_InteractiveNavItem> createState() => _InteractiveNavItemState();
}

class _InteractiveNavItemState extends State<_InteractiveNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _offsetYAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Animasi scale bounce spring
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.86)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.86, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Animasi lompat / pin-drop (sumbu Y) untuk Home dan Lokasi
    _offsetYAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -4.5)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -4.5, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Animasi wiggle / tilt miring untuk Kalkulator
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.10)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.10, end: 0.08)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.08, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _InteractiveNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  Widget _buildAnimatedIcon(Color color) {
    Widget iconWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) {
        return ScaleTransition(
          scale: anim,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: Icon(
        widget.isActive ? widget.activeIcon : widget.inactiveIcon,
        key: ValueKey<bool>(widget.isActive),
        size: 23,
        color: color,
      ),
    );

    // Micro-motion spesifik tiap tab:
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.index == 4) {
          // Kalkulator: wiggle tilt
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          );
        } else if (widget.index == 0 || widget.index == 5) {
          // Home & Lokasi: pin drop / jump float Y
          return Transform.translate(
            offset: Offset(0, _offsetYAnimation.value),
            child: child,
          );
        }
        // Profil: scale pop
        return child!;
      },
      child: iconWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isDark ? const Color(0xFF86EFAC) : const Color(0xFF20603D);
    final inactiveColor =
        widget.isDark ? const Color(0xFF8A9A90) : const Color(0xFF788C80);
    final activeBg = widget.isDark
        ? const Color(0xFF86EFAC).withValues(alpha: 0.14)
        : const Color(0xFF20603D).withValues(alpha: 0.09);
    final activeBorder = widget.isDark
        ? const Color(0xFF86EFAC).withValues(alpha: 0.25)
        : const Color(0xFF20603D).withValues(alpha: 0.15);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: widget.isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isActive ? activeBorder : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedIcon(widget.isActive ? activeColor : inactiveColor),
                  const SizedBox(height: 1.5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      height: 1.2,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isActive ? activeColor : inactiveColor,
                      letterSpacing: widget.isActive ? 0.1 : 0.0,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: widget.isActive ? Curves.easeOutBack : Curves.easeOutCubic,
                    width: widget.isActive ? 12 : 0,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: widget.isActive ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Scan Hero dengan feedback haptic, animasi tekan spring, dan glowing shadow.
class _HeroScanButton extends StatefulWidget {
  const _HeroScanButton({
    required this.isDark,
    required this.scanSize,
    required this.onTap,
  });

  final bool isDark;
  final double scanSize;
  final VoidCallback onTap;

  @override
  State<_HeroScanButton> createState() => _HeroScanButtonState();
}

class _HeroScanButtonState extends State<_HeroScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOutQuad,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.scanSize,
          height: widget.scanSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2EB86F), Color(0xFF1B613A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF141F18) : Colors.white,
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B613A).withValues(alpha: 0.38),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFF2EB86F).withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
      ),
    );
  }
}

/// Menggambar latar belakang bottom bar dengan cekungan lengkung halus (cradle notch).
class _NotchedNavPainter extends CustomPainter {
  const _NotchedNavPainter({
    required this.color,
    required this.shadowColor,
    required this.borderColor,
    this.notchRadius = 46.0,
    this.notchDepth = 38.0,
  });

  final Color color;
  final Color shadowColor;
  final Color borderColor;
  final double notchRadius;
  final double notchDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final s = notchRadius * 1.25;
    final d = notchDepth;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(cx - s, 0);

    // Lengkungan kubik halus turun ke dasar cekungan
    path.cubicTo(
      cx - s + (s * 0.42), 0,
      cx - (s * 0.45), d,
      cx, d,
    );

    // Lengkungan kubik halus naik ke bahu kanan
    path.cubicTo(
      cx + (s * 0.45), d,
      cx + s - (s * 0.42), 0,
      cx + s, 0,
    );

    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // 1. Bayangan lembut di atas kurva (hanya jika ada shadowColor)
    if (shadowColor != Colors.transparent && shadowColor.a > 0) {
      final shadowPaint = Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.save();
      canvas.translate(0, -2);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    // 2. Isi background bar
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Garis tepi atas mengikuti kontur kurva
    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.lineTo(cx - s, 0);
    borderPath.cubicTo(
      cx - s + (s * 0.42), 0,
      cx - (s * 0.45), d,
      cx, d,
    );
    borderPath.cubicTo(
      cx + (s * 0.45), d,
      cx + s - (s * 0.42), 0,
      cx + s, 0,
    );
    borderPath.lineTo(w, 0);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchedNavPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.notchDepth != notchDepth;
  }
}

/// Memperluas area hit-test ke atas agar tombol yang menonjol keluar dari bounding box tetap responsif diklik.
class _OverflowHitTest extends SingleChildRenderObjectWidget {
  const _OverflowHitTest({required super.child, required this.overflowTop});

  final double overflowTop;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverflowHitTest(overflowTop: overflowTop);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderOverflowHitTest renderObject) {
    renderObject.overflowTop = overflowTop;
  }
}

class _RenderOverflowHitTest extends RenderProxyBox {
  _RenderOverflowHitTest({required double overflowTop})
      : _overflowTop = overflowTop;

  double _overflowTop;

  set overflowTop(double value) {
    if (_overflowTop != value) {
      _overflowTop = value;
      markNeedsLayout();
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final Rect extendedBounds = Rect.fromLTRB(
      0,
      -_overflowTop,
      size.width,
      size.height,
    );
    if (extendedBounds.contains(position)) {
      if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
}
