import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
// import '../../models/lokasi_olahraga_model.dart';
import '../../services/lokasi_olahraga_service.dart';

class LocationOlahragaPage extends StatefulWidget {
  final VoidCallback onBack;
  final String? initialCategory;
  final String? bmiCategory;
  final String? bmiRecommendationReason;
  final List<Map<String, dynamic>>? preloadedLocations;
  const LocationOlahragaPage({
    super.key,
    required this.onBack,
    this.initialCategory,
    this.bmiCategory,
    this.bmiRecommendationReason,
    this.preloadedLocations,
  });
  @override
  State<LocationOlahragaPage> createState() => _LocationOlahragaPageState();
}

class _LocationOlahragaPageState extends State<LocationOlahragaPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;
  String _searchQuery = '';
  final List<String> _categories = [
    'Semua',
    'Gym',
    'Lapangan',
    'Aktivitas Ringan',
  ];

  final LokasiOlahragaService _lokasiService = LokasiOlahragaService.instance;
  List<Map<String, dynamic>> _locations = [];
  bool _isLoadingLocations = true;
  String? _locationError;

  Future<void> _loadLocations() async {
    // 1. Cek apakah ada data preloaded dari pemanggil (misal BmiPage)
    if (widget.preloadedLocations != null &&
        widget.preloadedLocations!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _locations = widget.preloadedLocations!;
          _isLoadingLocations = false;
          _locationError = null;
        });
      }
      return;
    }

    // 2. Cek apakah cache di service sudah ada data (seperti saat buka tab sebelumnya)
    final cached = _lokasiService.cachedLocations;
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _locations = cached.map((l) => l.toDisplayMap()).toList();
          _isLoadingLocations = false;
          _locationError = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingLocations = true;
        _locationError = null;
      });
    }

    try {
      final results = await _lokasiService.fetchAll();
      if (!mounted) return;
      setState(() {
        _locations = results
            .map((location) => location.toDisplayMap())
            .toList();
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError =
            'Data lokasi gagal dimuat. Periksa koneksi internet lalu coba lagi.';
        _isLoadingLocations = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLocations {
    return _locations.where((loc) {
      final matchCategory =
          _selectedCategory == 0 ||
          loc['category'] == _categories[_selectedCategory];
      final matchSearch =
          _searchQuery.isEmpty ||
          loc['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          loc['address'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchCategory && matchSearch;
    }).toList();
  }

  Future<void> _openMaps(String query) async {
    final cleanQuery = query.replaceAll('+', ' ').trim();
    bool launched = false;
    // 1. Coba native Android Google Maps intent via geo:0,0?q=... (Menggunakan GPS pengguna saat ini)
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
            style: GoogleFonts.inter(fontSize: 12),
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openNearbyGyms() async {
    await _openMaps('tempat olahraga terdekat');
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final requested = widget.initialCategory!.toLowerCase();
      var idx = _categories.indexWhere((c) => c.toLowerCase() == requested);
      if (idx == -1 &&
          (requested.contains('jogging') ||
              requested.contains('renang') ||
              requested.contains('low_impact') ||
              requested.contains('aktivitas ringan'))) {
        idx = _categories.indexOf('Aktivitas Ringan');
      }
      if (idx != -1) _selectedCategory = idx;
    }

    if (widget.preloadedLocations != null &&
        widget.preloadedLocations!.isNotEmpty) {
      _locations = widget.preloadedLocations!;
      _isLoadingLocations = false;
    } else {
      final cached = _lokasiService.cachedLocations;
      if (cached != null && cached.isNotEmpty) {
        _locations = cached.map((l) => l.toDisplayMap()).toList();
        _isLoadingLocations = false;
      }
    }

    _loadLocations();
  }

  @override
  void didUpdateWidget(covariant LocationOlahragaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory &&
        widget.initialCategory != null) {
      final requested = widget.initialCategory!.toLowerCase();
      var idx = _categories.indexWhere((c) => c.toLowerCase() == requested);
      if (idx == -1 &&
          (requested.contains('jogging') ||
              requested.contains('renang') ||
              requested.contains('low_impact') ||
              requested.contains('aktivitas ringan'))) {
        idx = _categories.indexOf('Aktivitas Ringan');
      }
      if (idx != -1 && idx != _selectedCategory) {
        setState(() => _selectedCategory = idx);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

    Widget _buildBmiRecommendationAlert() {
    if (widget.bmiCategory == null) return const SizedBox.shrink();
    Color badgeColor = const Color(0xFF20603D);
    IconData badgeIcon = Icons.health_and_safety_rounded;
    if (widget.bmiCategory!.toLowerCase().contains('kurus')) {
      badgeColor = Colors.blue;
      badgeIcon = Icons.fitness_center_rounded;
    } else if (widget.bmiCategory!.toLowerCase().contains('lebih') ||
        widget.bmiCategory!.toLowerCase().contains('obes')) {
      badgeColor = Colors.orange;
      badgeIcon = Icons.pool_rounded;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 22),
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
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'REKOMENDASI BMI',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.bmiCategory!,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCategory != 0)
                        GestureDetector(
                          onTap: () => setState(() => _selectedCategory = 0),
                          child: Text(
                            'Semua',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.bmiRecommendationReason ??
                        'Fasilitas olahraga disaring sesuai dengan kondisi fisik dan target kesehatan Anda.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            // BMI Recommendation Alert
            if (widget.bmiCategory != null)
              SliverToBoxAdapter(child: _buildBmiRecommendationAlert()),
            // Search & Filter
            SliverToBoxAdapter(child: _buildSearchAndFilter()),
            // Map Banner
            SliverToBoxAdapter(child: _buildMapBanner()),
            // Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredLocations.length} Tempat Ditemukan',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20603D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Lokasi FitLife',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF20603D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Location List
            if (_isLoadingLocations)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 42),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF20603D),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Memuat lokasi olahraga...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_locationError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 42,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _locationError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadLocations,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20603D),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredLocations.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildLocationCard(_filteredLocations[index]),
                    ),
                    childCount: _filteredLocations.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19,
                color: Color(0xFF252525),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi Olahraga',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF202124),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Temukan tempat olahraga yang sesuai dengan kebutuhanmu.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF777777),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama tempat atau alamat...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Category Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF20603D)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF20603D)
                            : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF20603D,
                                ).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _categories[index],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildMapBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: _openNearbyGyms,
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3460).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF247447).withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF247447,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'GOOGLE MAPS',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF34D399),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cari Tempat\nOlahraga Terdekat',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.open_in_new_rounded,
                                color: Color(0xFF34D399),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Buka di Google Maps',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF247447).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF247447).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: Color(0xFF34D399),
                        size: 36,
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
  }

  Widget _buildLocationCard(Map<String, dynamic> loc) {
    final bool? isOpen = loc['open'] as bool?;
    final Color catColor = loc['color'] as Color? ?? const Color(0xFF20603D);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    loc['icon'] as IconData,
                    color: catColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Name & Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc['name'],
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              loc['category'],
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: catColor,
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
                              color: isOpen == null
                                  ? const Color(
                                      0xFF9CA3AF,
                                    ).withValues(alpha: 0.12)
                                  : isOpen
                                  ? const Color(
                                      0xFF20603D,
                                    ).withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOpen == null
                                  ? 'Belum diketahui'
                                  : (isOpen ? 'Buka' : 'Tutup'),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOpen == null
                                    ? const Color(0xFF6B7280)
                                    : (isOpen
                                          ? const Color(0xFF20603D)
                                          : Colors.redAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Distance badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            loc['distance'] ?? 'Belum diketahui',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    loc['address'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Hours & Rating
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 5),
                Text(
                  loc['hours'] ?? 'Jam buka belum tersedia',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                  loc['rating'] == null
                      ? 'Rating belum tersedia'
                      : '${loc['rating']} (${loc['reviews'] ?? 0} ulasan)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Open in Maps Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openMaps((loc['mapQuery'] ?? loc['name']).toString()),
                icon: const Icon(Icons.map_rounded, size: 16),
                label: Text(
                  'Buka di Google Maps',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF20603D).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 48,
              color: Color(0xFF20603D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Hasil',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci atau pilih kategori lain.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
