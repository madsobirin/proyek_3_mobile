import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
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
  bool _isChatOpen = false;

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
        const SizedBox(height: AppSpacing.sm),
        _buildHeroSection(isSmall),
        const SizedBox(height: AppSpacing.sm),
        _buildDailyTipCard(isSmall),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(
          title: "Menu Sehat Populer",
          actionText: "Lihat Semua",
          icon: Icons.restaurant_rounded,
          onActionTap: () => _onItemTapped(1), // Menu = index 1
          isSmall: isSmall,
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        _buildLatestMenu(isSmall),
        const SizedBox(height: AppSpacing.lg + 4),
        _buildSectionHeader(
          title: "Artikel & Tips Sehat",
          actionText: "Lihat Semua",
          icon: Icons.article_rounded,
          onActionTap: () => _onItemTapped(2), // Artikel = index 2
          isSmall: isSmall,
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        _buildLatestArtikel(isSmall),
      ],
    );
  }

  // --- 1. Top Header with User Greeting & Brand Badge ---
  Widget _buildTopHeader(bool isSmall) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmall ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.sm,
        isSmall ? AppSpacing.md : AppSpacing.lg,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, Sahabat FitLife! 👋",
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: isSmall ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Siap bugar & hidup sehat hari ini?",
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: isSmall ? 11 : 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2,
              vertical: AppSpacing.xxs + 1,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: AppRadius.roundedSm,
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors.accentAmber,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  "FitLife.id",
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmall ? AppSpacing.md : AppSpacing.lg - 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppRadius.roundedLg,
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 13,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    "Asisten Hidup Sehat",
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Capai Tubuh Ideal & Bugar Bersama FitLife",
              style: textTheme.titleLarge?.copyWith(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs + 1),
            Text(
              "Temukan inspirasi makanan sehat dan mulai kebiasaan hidup lebih aktif bersama FitLife.",
              style: textTheme.bodySmall?.copyWith(
                fontSize: isSmall ? 11.5 : 12.5,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Daily Tip Card (Slim) ---
  Widget _buildDailyTipCard(bool isSmall) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs - 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_rounded,
                color: colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm - 2),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(
                      text: "Tips Hari Ini: ",
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs - 2),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.transparent,
            borderRadius: AppRadius.roundedSm,
            child: InkWell(
              onTap: onActionTap,
              borderRadius: AppRadius.roundedSm,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 48,
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm - 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Latest Menu Carousel ---
  Widget _buildLatestMenu(bool isSmall) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? AppSpacing.md : AppSpacing.lg,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm + 2),
        itemBuilder: (context, index) {
          return Material(
            color: colorScheme.surfaceContainer,
            borderRadius: AppRadius.roundedLg,
            child: InkWell(
              onTap: () => _onItemTapped(1), // Menu = index 1
              borderRadius: AppRadius.roundedLg,
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.roundedLg,
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg),
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
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs - 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: AppRadius.roundedSm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 12,
                                  color: AppColors.accentAmber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  cals[index],
                                  style: textTheme.labelSmall?.copyWith(
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
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titles[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            tags[index],
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 7. Latest Articles List ---
  Widget _buildLatestArtikel(bool isSmall) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.md : AppSpacing.lg,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return Material(
          color: colorScheme.surfaceContainer,
          borderRadius: AppRadius.roundedLg,
          child: InkWell(
            onTap: () => _onItemTapped(2), // Artikel = index 2
            borderRadius: AppRadius.roundedLg,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: AppRadius.roundedLg,
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.roundedMd,
                    child: Image.network(
                      images[index],
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md - 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xxs - 1,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: AppRadius.roundedSm,
                              ),
                              child: Text(
                                categories[index],
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              readTimes[index],
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs - 2),
                        Text(
                          titles[index],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeContent(), // 0 - Home
                MenuPage(onBack: _goBack), // 1 - Menu (diakses dari Home)
                ArtikelPage(onBack: _goBack), // 2 - Artikel (diakses dari Home)
                _isLoggedIn
                    ? const ProfilePage()
                    : const GuestProfilePage(), // 3 - Profil
                BmiPage(onBack: _goBack), // 4 - Kalkulator BMI
                LocationOlahragaPage(onBack: _goBack), // 5 - Lokasi Olahraga
              ],
            ),
          ),
          if (_isChatOpen)
            Positioned(
              right: 12,
              bottom: 12,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width >= 420
                    ? 380
                    : MediaQuery.sizeOf(context).width - 24,
                height: (MediaQuery.sizeOf(context).height * 0.65).clamp(
                  320.0,
                  620.0,
                ),
                child: const ChatPanel(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
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
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
                index: 4,
                icon: Icons.monitor_weight_rounded,
                label: "Kalkulator",
              ),
              _buildScanNavItem(),
              _buildNavItem(
                index: 5,
                icon: Icons.place_rounded,
                label: "Lokasi",
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanBarcodeScreen()),
          );
        },
        customBorder: const CircleBorder(),
        child: Transform.translate(
          offset: const Offset(0, -10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.surfaceContainer,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isActive = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.roundedSm,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: AppRadius.roundedSm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: AppRadius.roundedSm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
