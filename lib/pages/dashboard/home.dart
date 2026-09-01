import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/bmi_page.dart';
import '../dashboard/artikel_page.dart';
import 'package:fitlife/pages/dashboard/profile_page.dart';
import 'package:fitlife/pages/dashboard/menu_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final List<int> _history = [];

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
        _buildSectionHeader("Menu Sehat Terbaru", "Lihat Semua", () => _onItemTapped(2), isSmall),
        const SizedBox(height: 16),
        _buildLatestMenu(isSmall),
        const SizedBox(height: 24),
        _buildSectionHeader("Artikel Terbaru", "Lihat Semua", () => _onItemTapped(3), isSmall),
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
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(45),
        ),
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
                Icon(Icons.monitor_weight_rounded, size: isSmall ? 18 : 20, color: Colors.white),
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

  Widget _buildSectionHeader(String title, String actionText, VoidCallback onActionTap, bool isSmall) {
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
          final titles = ["Salad Buah Segar", "Oatmeal Berries", "Ayam Panggang"];
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                            const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.orange),
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
      "5 Mitos Tentang Diet yang Harus Kamu Ketahui"
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            _buildHomeContent(),
            BmiPage(onBack: _goBack),
            // const Center(child: Text("Halaman Menu")),
            MenuPage(onBack: _goBack),
            ArtikelPage(onBack: _goBack),
            // const ProfilePages(),
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final isActive = _selectedIndex == index;

          final icons = [
            Icons.home,
            Icons.calculate,
            Icons.restaurant_menu,
            Icons.article,
            Icons.person,
          ];

          final labels = ["Home", "BMI", "Menu", "Artikel", "Profil"];

          return GestureDetector(
            onTap: () => _onItemTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 8,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF00FF66).withOpacity(0.15)
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    icons[index],
                    size: isActive ? 26 : 22,
                    color: isActive ? const Color(0xFF00FF66) : Colors.grey,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Text(
                      labels[index],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00FF66),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
