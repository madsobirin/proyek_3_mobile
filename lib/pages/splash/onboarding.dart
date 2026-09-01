// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      badge: 'ANALISA TUBUH',
      badgeIcon: Icons.monitor_weight_rounded,
      title: 'Kenali',
      titleHighlight: 'Tubuhmu',
      subtitle:
          'Ketahui status berat badan idealmu hanya dengan memasukkan tinggi dan berat badan secara presisi.',
      buttonText: 'Lanjutkan',
      showSignIn: true,
      visualType: VisualType.bmi,
    ),
    OnboardingData(
      badge: 'NUTRISI TEPAT',
      badgeIcon: Icons.restaurant_menu_rounded,
      title: 'Makan Enak &',
      titleHighlight: 'Tetap Sehat',
      subtitle:
          'Dapatkan rekomendasi menu diet harian lengkap dengan jumlah kalori dan resep masakan bergizi.',
      buttonText: 'Selanjutnya',
      showSignIn: false,
      visualType: VisualType.menu,
    ),
    OnboardingData(
      badge: 'GAYA HIDUP',
      badgeIcon: Icons.menu_book_rounded,
      title: 'Tingkatkan',
      titleHighlight: 'Pengetahuanmu',
      subtitle:
          'Baca berbagai artikel inspiratif seputar gaya hidup sehat, nutrisi, dan tips berolahraga setiap hari.',
      buttonText: 'Mulai Sekarang',
      showSignIn: true,
      signInText: 'Log In',
      showBackButton: true,
      visualType: VisualType.artikel,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF66).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF66).withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Image(
                                image: AssetImage("assets/images/logo.png"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FitLife.id',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Skip
                      GestureDetector(
                        onTap: _skip,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Bottom section
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Visual
          Expanded(
            flex: 5,
            child: Center(child: _buildVisual(data.visualType)),
          ),

          // Text content
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00FF66).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.badgeIcon,
                          size: 14,
                          color: const Color(0xFF00CC52),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.badge,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00CC52),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(text: '${data.title}\n'),
                        TextSpan(
                          text: data.titleHighlight,
                          style: GoogleFonts.manrope(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00FF66),
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    data.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      height: 1.6,
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

  Widget _buildVisual(VisualType type) {
    switch (type) {
      case VisualType.bmi:
        return _buildImageVisual(
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=800&auto=format&fit=crop',
        );
      case VisualType.menu:
        return _buildImageVisual(
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=800&auto=format&fit=crop',
        );
      case VisualType.artikel:
        return _buildImageVisual(
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=800&auto=format&fit=crop',
        );
    }
  }

  Widget _buildImageVisual(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF66).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final data = _pages[_currentPage];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 32 : 8,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? const Color(0xFF00FF66)
                      : const Color(0xFFD1D5DB),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00FF66).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Button row
          if (data.showBackButton == true) ...[
            Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                // Next button (compact)
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          data.buttonText,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Full width button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF66),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shadowColor: const Color(0xFF00FF66).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.buttonText,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Sign In / Log In link
          if (data.showSignIn)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                GestureDetector(
                  onTap: _skip,
                  child: Text(
                    data.signInText ?? 'Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────

enum VisualType { bmi, menu, artikel }

class OnboardingData {
  final String badge;
  final IconData badgeIcon;
  final String title;
  final String titleHighlight;
  final String subtitle;
  final String buttonText;
  final bool showSignIn;
  final String? signInText;
  final bool? showBackButton;
  final VisualType visualType;

  OnboardingData({
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.buttonText,
    required this.showSignIn,
    required this.visualType,
    this.signInText,
    this.showBackButton,
  });
}
