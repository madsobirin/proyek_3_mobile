import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationOlahragaPage extends StatefulWidget {
  final VoidCallback onBack;
  const LocationOlahragaPage({super.key, required this.onBack});

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
    'Kolam Renang',
    'Jogging Track',
    'Stadion',
  ];

  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'FitFirst Fitness Center',
      'category': 'Gym',
      'address': 'Jl. Sudirman No.45, Jakarta Pusat',
      'distance': '0.8 km',
      'rating': 4.7,
      'reviews': 312,
      'open': true,
      'hours': '06.00 – 22.00',
      'icon': Icons.fitness_center_rounded,
      'color': Colors.purple,
      'mapQuery': 'Fitness+Center+Jakarta',
    },
    {
      'name': 'Gelora Bung Karno Sport Complex',
      'category': 'Stadion',
      'address': 'Jl. Pintu Satu Senayan, Jakarta Pusat',
      'distance': '1.2 km',
      'rating': 4.8,
      'reviews': 5210,
      'open': true,
      'hours': '05.00 – 21.00',
      'icon': Icons.stadium_rounded,
      'color': Colors.red,
      'mapQuery': 'Gelora+Bung+Karno+Jakarta',
    },
    {
      'name': 'Lapangan Badminton Gor Ciracas',
      'category': 'Lapangan',
      'address': 'Jl. Raya Bogor No.1, Jakarta Timur',
      'distance': '2.1 km',
      'rating': 4.3,
      'reviews': 128,
      'open': true,
      'hours': '07.00 – 23.00',
      'icon': Icons.sports_tennis_rounded,
      'color': Colors.orange,
      'mapQuery': 'Lapangan+Badminton+Jakarta',
    },
    {
      'name': 'Kolam Renang Senayan',
      'category': 'Kolam Renang',
      'address': 'Komplek GBK, Senayan, Jakarta Selatan',
      'distance': '1.5 km',
      'rating': 4.6,
      'reviews': 874,
      'open': false,
      'hours': '06.00 – 18.00',
      'icon': Icons.pool_rounded,
      'color': Colors.blue,
      'mapQuery': 'Kolam+Renang+Senayan+Jakarta',
    },
    {
      'name': 'Hutan Kota Srengseng',
      'category': 'Jogging Track',
      'address': 'Jl. Srengseng Raya, Jakarta Barat',
      'distance': '3.4 km',
      'rating': 4.5,
      'reviews': 642,
      'open': true,
      'hours': '05.00 – 18.00',
      'icon': Icons.nature_people_rounded,
      'color': const Color(0xFF00CC52),
      'mapQuery': 'Hutan+Kota+Srengseng+Jakarta',
    },
    {
      'name': 'Gold\'s Gym Kelapa Gading',
      'category': 'Gym',
      'address': 'Mal Kelapa Gading Lt.3, Jakarta Utara',
      'distance': '4.0 km',
      'rating': 4.9,
      'reviews': 1203,
      'open': true,
      'hours': '06.00 – 23.00',
      'icon': Icons.fitness_center_rounded,
      'color': Colors.deepOrange,
      'mapQuery': "Gold's+Gym+Kelapa+Gading+Jakarta",
    },
    {
      'name': 'Lapangan Sepak Bola Ragunan',
      'category': 'Lapangan',
      'address': 'Jl. Harsono RM, Ragunan, Jakarta Selatan',
      'distance': '5.2 km',
      'rating': 4.2,
      'reviews': 231,
      'open': true,
      'hours': '07.00 – 18.00',
      'icon': Icons.sports_soccer_rounded,
      'color': Colors.green,
      'mapQuery': 'Lapangan+Sepak+Bola+Ragunan+Jakarta',
    },
    {
      'name': 'Rooftop Jogging Track SCBD',
      'category': 'Jogging Track',
      'address': 'Jl. Jend. Sudirman Kav.52, Jakarta Selatan',
      'distance': '1.9 km',
      'rating': 4.4,
      'reviews': 89,
      'open': true,
      'hours': '05.30 – 20.00',
      'icon': Icons.directions_run_rounded,
      'color': Colors.teal,
      'mapQuery': 'Jogging+Track+SCBD+Jakarta',
    },
  ];

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
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openNearbyGyms() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/tempat+olahraga+terdekat/',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader()),

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
                      color: const Color(0xFF00FF66).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Dekat Lokasimu',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location List
          if (_filteredLocations.isEmpty)
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Image.asset('assets/images/logo.png')),
              ),
              const SizedBox(width: 8),
              Text(
                'Fitlife.id',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Lokasi Olahraga 📍',
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Temukan gym, lapangan, dan tempat olahraga terdekat di sekitarmu.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
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
                          ? const Color(0xFF00FF66)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00FF66)
                            : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF00FF66,
                                ).withValues(alpha: 0.3),
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
                            ? const Color(0xFF111827)
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
          height: 160,
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
                    color: const Color(0xFF00FF66).withValues(alpha: 0.08),
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
                                0xFF00FF66,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'GOOGLE MAPS',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00FF66),
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
                                color: Color(0xFF00FF66),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Buka di Google Maps',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF00FF66),
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
                        color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00FF66).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: Color(0xFF00FF66),
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
    final bool isOpen = loc['open'] as bool;
    final Color catColor = loc['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                              color: isOpen
                                  ? const Color(
                                      0xFF00FF66,
                                    ).withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOpen ? 'Buka' : 'Tutup',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOpen
                                    ? const Color(0xFF15803D)
                                    : Colors.redAccent,
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
                            loc['distance'],
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
                  loc['hours'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                  '${loc['rating']} (${loc['reviews']} ulasan)',
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
                onPressed: () => _openMaps(loc['mapQuery'] as String),
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
              color: const Color(0xFF00FF66).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 48,
              color: Color(0xFF15803D),
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
