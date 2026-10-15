import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/lokasi_olahraga_model.dart';
import '../../services/lokasi_olahraga_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

class LocationOlahragaPage extends StatefulWidget {
  final VoidCallback onBack;
  final String? initialCategory;
  final String? bmiCategory;
  final String? bmiRecommendationReason;
  final List<Map<String, dynamic>>? preloadedLocations;
  final int? navEpoch;

  const LocationOlahragaPage({
    super.key,
    required this.onBack,
    this.initialCategory,
    this.bmiCategory,
    this.bmiRecommendationReason,
    this.preloadedLocations,
    this.navEpoch,
  });

  @override
  State<LocationOlahragaPage> createState() => _LocationOlahragaPageState();
}

class _LocationOlahragaPageState extends State<LocationOlahragaPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  // Mode Tampilan: 'map' atau 'list'
  String _viewMode = 'map';

  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  // Kategori yang selaras dengan web fitlife.my.id/lokasi
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'label': 'Semua Lokasi',
      'bmiTag': 'Semua BMI',
      'icon': Icons.explore_rounded,
    },
    {
      'id': 'gym',
      'label': '🏋️ Fitness Center / Gym',
      'bmiTag': 'Underweight (Kurus)',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFFF59E0B), // Amber
    },
    {
      'id': 'lapangan',
      'label': '🏟️ Lapangan & Komunitas',
      'bmiTag': 'Normal',
      'icon': Icons.sports_soccer_rounded,
      'color': const Color(0xFF10B981), // Emerald
    },
    {
      'id': 'low_impact',
      'label': '🏊 Low-Impact (Jogging / Renang)',
      'bmiTag': 'Overweight / Obesitas',
      'icon': Icons.pool_rounded,
      'color': const Color(0xFF0284C7), // Sky Blue
    },
  ];

  final LokasiOlahragaService _lokasiService = LokasiOlahragaService.instance;
  List<Map<String, dynamic>> _locations = [];
  bool _isLoadingLocations = true;
  String? _locationError;

  // Koordinat default Indramayu (Pusat titik fasilitas di API FitLife)
  static const LatLng _indramayuCenter = LatLng(-6.3265, 108.3291);
  LatLng? _userPosition;
  bool _isLoadingGps = false;

  // Lokasi yang sedang dipilih/diklik pada peta
  Map<String, dynamic>? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _applyInitialCategory();
    _loadLocations();
    _detectUserPosition();
  }

  void _applyInitialCategory() {
    String? target = widget.initialCategory;
    if (target == null && widget.bmiCategory != null) {
      final bmi = widget.bmiCategory!.toLowerCase();
      if (bmi.contains('kurus')) {
        target = 'gym';
      } else if (bmi.contains('normal')) {
        target = 'lapangan';
      } else if (bmi.contains('lebih') || bmi.contains('obes')) {
        target = 'low_impact';
      }
    }

    if (target != null) {
      final requested = target.toLowerCase();
      if (requested.contains('gym') || requested.contains('kurus')) {
        _selectedCategoryIndex = 1;
      } else if (requested.contains('lapangan') ||
          requested.contains('normal')) {
        _selectedCategoryIndex = 2;
      } else if (requested.contains('low') ||
          requested.contains('renang') ||
          requested.contains('jogging') ||
          requested.contains('aktivitas') ||
          requested.contains('lebih') ||
          requested.contains('obes')) {
        _selectedCategoryIndex = 3;
      }
    }
  }

  @override
  void didUpdateWidget(covariant LocationOlahragaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory ||
        widget.bmiCategory != oldWidget.bmiCategory) {
      _applyInitialCategory();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Mendapatkan Posisi GPS Pengguna ---
  Future<void> _detectUserPosition({bool showFeedback = false}) async {
    if (_isLoadingGps) return;
    setState(() => _isLoadingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFeedback && mounted) {
          _showToast('GPS tidak aktif. Mohon aktifkan lokasi di perangkat.');
        }
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showFeedback && mounted) {
            _showToast('Izin lokasi ditolak.');
          }
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (showFeedback && mounted) {
          _showToast('Izin lokasi ditolak permanen di pengaturan.');
        }
        setState(() => _isLoadingGps = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      if (!mounted) return;
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
        _isLoadingGps = false;
      });

      // Recalculate distances with new user position
      _recalculateDistances();

      if (showFeedback && mounted) {
        _showToast('Lokasi GPS Anda berhasil ditemukan!');
        _mapController.move(_userPosition!, 14.5);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _recalculateDistances() {
    if (_locations.isEmpty) return;
    setState(() {
      _locations = _locations.map((loc) {
        final double? lat = (loc['latitude'] as num?)?.toDouble();
        final double? lng = (loc['longitude'] as num?)?.toDouble();
        if (_userPosition != null &&
            lat != null &&
            lng != null &&
            lat != 0 &&
            lng != 0) {
          final meters = _calculateHaversineDistance(
            _userPosition!.latitude,
            _userPosition!.longitude,
            lat,
            lng,
          );
          return {
            ...loc,
            'distanceMeters': meters,
            'distance': meters < 1000
                ? '${meters.round()} m'
                : '${(meters / 1000).toStringAsFixed(1)} km',
          };
        }
        return loc;
      }).toList();
    });
  }

  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meter
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final sinLat = math.sin(dLat / 2);
    final sinLon = math.sin(dLon / 2);
    final a =
        sinLat * sinLat +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            sinLon *
            sinLon;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // --- Mengambil Data Lokasi dari API FitLife ---
  Future<void> _loadLocations() async {
    // 1. Data preloaded
    if (widget.preloadedLocations != null &&
        widget.preloadedLocations!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _locations = widget.preloadedLocations!;
          _isLoadingLocations = false;
          _locationError = null;
        });
        _recalculateDistances();
      }
      return;
    }

    // 2. Data cached
    final cached = _lokasiService.cachedLocations;
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _locations = cached.map((l) {
            return l.toDisplayMap(
              userLat: _userPosition?.latitude,
              userLng: _userPosition?.longitude,
            );
          }).toList();
          _isLoadingLocations = false;
          _locationError = null;
        });
        _recalculateDistances();
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
        _locations = results.map((l) {
          return l.toDisplayMap(
            userLat: _userPosition?.latitude,
            userLng: _userPosition?.longitude,
          );
        }).toList();
        _isLoadingLocations = false;
      });
      _recalculateDistances();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError =
            'Gagal memuat rekomendasi tempat olahraga. Periksa koneksi internet Anda.';
        _isLoadingLocations = false;
      });
    }
  }

  // --- Filter & Sorting Lokasi ---
  List<Map<String, dynamic>> get _filteredLocations {
    final catId = _categories[_selectedCategoryIndex]['id'] as String;
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _locations.where((loc) {
      bool matchCat = true;
      if (catId != 'all') {
        final rawCat = (loc['rawCategory'] ?? '').toString().toLowerCase();
        final displayCat = (loc['category'] ?? '').toString().toLowerCase();
        if (catId == 'gym') {
          matchCat = rawCat == 'gym' || displayCat.contains('gym');
        } else if (catId == 'lapangan') {
          matchCat = rawCat == 'lapangan' || displayCat.contains('lapangan');
        } else if (catId == 'low_impact') {
          matchCat =
              rawCat == 'low_impact' ||
              displayCat.contains('ringan') ||
              displayCat.contains('low');
        }
      }

      bool matchSearch = true;
      if (query.isNotEmpty) {
        final name = (loc['name'] ?? '').toString().toLowerCase();
        final address = (loc['address'] ?? '').toString().toLowerCase();
        matchSearch = name.contains(query) || address.contains(query);
      }

      return matchCat && matchSearch;
    }).toList();

    // Urutkan berdasarkan jarak terdekat jika posisi pengguna diketahui
    if (_userPosition != null) {
      filtered.sort((a, b) {
        final distA =
            (a['distanceMeters'] as num?)?.toDouble() ?? double.infinity;
        final distB =
            (b['distanceMeters'] as num?)?.toDouble() ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

  // --- Buka Google Maps ---
  Future<void> _openMaps(String query) async {
    final cleanQuery = query.replaceAll('+', ' ').trim();
    bool launched = false;
    final geoUri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(cleanQuery)}');
    try {
      if (await canLaunchUrl(geoUri)) {
        launched = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

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
      if (!launched) {
        try {
          launched = await launchUrl(webUri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
    }

    if (!launched && mounted) {
      _showToast('Tidak dapat membuka aplikasi Google Maps.');
    }
  }

  void _showToast(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _focusLocationOnMap(Map<String, dynamic> loc) {
    final double? lat = (loc['latitude'] as num?)?.toDouble();
    final double? lng = (loc['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      setState(() {
        _viewMode = 'map';
        _selectedLocation = loc;
      });
      _mapController.move(LatLng(lat, lng), 15.5);
    } else {
      _showToast('Titik koordinat lokasi ini belum tersedia pada peta.');
    }
  }

  void _resetMapBounds() {
    final locationsWithCoords = _filteredLocations.where((loc) {
      final double? lat = (loc['latitude'] as num?)?.toDouble();
      final double? lng = (loc['longitude'] as num?)?.toDouble();
      return lat != null && lng != null && lat != 0 && lng != 0;
    }).toList();

    if (locationsWithCoords.isEmpty) {
      _mapController.move(_indramayuCenter, 13.0);
      return;
    }

    final points = locationsWithCoords.map((loc) {
      return LatLng(
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
    }).toList();

    if (_userPosition != null) {
      points.add(_userPosition!);
    }

    if (points.length == 1) {
      _mapController.move(points.first, 14.5);
    } else {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      _mapController.move(LatLng(centerLat, centerLng), 13.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalTheme = Theme.of(context);
    // Gunakan skema Light yang sama dengan AppTheme di project FitLife.
    const lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryLight,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.onPrimaryContainerLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onSecondaryLight,
      secondaryContainer: AppColors.secondaryContainerLight,
      onSecondaryContainer: AppColors.onSecondaryContainerLight,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainer: AppColors.surfaceContainerLight,
      onSurfaceVariant: AppColors.onSurfaceVariantLight,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineVariantLight,
    );
    final lightTheme = originalTheme.copyWith(
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      canvasColor: const Color(0xFFFFFFFF),
    );

    return Theme(
      data: lightTheme,
      child: Builder(
        builder: (pageContext) {
          final theme = Theme.of(pageContext);
          final colorScheme = theme.colorScheme;

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Column(
                children: [
                  // Header tetap berada di atas saat konten digulir.
                  _buildHeader(pageContext),

                  Expanded(
                    child: RefreshIndicator(
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      onRefresh: () async {
                        await _detectUserPosition();
                        await _loadLocations();
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.zero,
                        children: [
                          if (widget.bmiCategory != null)
                            _buildBmiRecommendationAlert(pageContext),
                          _buildSearchBar(pageContext),
                          _buildCategoryChips(pageContext),
                          _buildViewSwitcher(pageContext),
                          const SizedBox(height: AppSpacing.sm),
                          if (_isLoadingLocations)
                            _buildLoadingState(pageContext)
                          else if (_locationError != null)
                            _buildErrorState(pageContext)
                          else if (_filteredLocations.isEmpty)
                            _buildEmptyState(pageContext)
                          else if (_viewMode == 'map')
                            _buildMapSection(pageContext)
                          else
                            _buildListSection(pageContext),
                          const SizedBox(height: 80),
                        ],
                      ),
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

  // --- WIDGET KOMPONEN ---

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Tombol Kembali
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                widget.onBack();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Judul & Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rekomendasi Tempat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Lokasi Olahraga',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Tombol Refresh / GPS Action
          IconButton(
            tooltip: 'Perbarui Lokasi GPS',
            onPressed: () => _detectUserPosition(showFeedback: true),
            icon: _isLoadingGps
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(
                    _userPosition != null
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: _userPosition != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiRecommendationAlert(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color badgeColor = colorScheme.primary;
    IconData badgeIcon = Icons.health_and_safety_rounded;
    final bmi = widget.bmiCategory!.toLowerCase();

    if (bmi.contains('kurus')) {
      badgeColor = AppColors.accentAmber;
      badgeIcon = Icons.fitness_center_rounded;
    } else if (bmi.contains('lebih') || bmi.contains('obes')) {
      badgeColor = const Color(0xFF0284C7); // Sky Blue
      badgeIcon = Icons.pool_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.08),
          borderRadius: AppRadius.roundedLg,
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: AppRadius.roundedSm,
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Text(
                          'REKOMENDASI BMI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.bmiCategory!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCategoryIndex != 0)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategoryIndex = 0),
                          child: Text(
                            'Semua',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: colorScheme.onSurface,
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

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          // Search bar dipastikan memakai warna Light, tidak mengikuti
          // surfaceContainer dari tema perangkat yang mungkin Dark.
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(color: AppColors.outlineLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.onSurfaceLight,
          ),
          cursorColor: colorScheme.primary,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            hintText: 'Cari gym, lapangan, taman olahraga...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.onSurfaceVariantLight,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: colorScheme.onSurfaceVariant,
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm + 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final bool isSelected = _selectedCategoryIndex == index;
          final catColor = cat['color'] as Color? ?? colorScheme.primary;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
                _selectedLocation = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(
                right: AppSpacing.xs,
                top: 4,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainer,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (index != 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.onPrimary.withValues(alpha: 0.2)
                            : catColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: Text(
                        cat['bmiTag'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? colorScheme.onPrimary : catColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Counter Info
          Row(
            children: [
              Text(
                '${_filteredLocations.length} Tempat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              if (_userPosition != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'Terdekat GPS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),

          // Switcher Buttons: [Peta] | [Daftar]
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                _buildSwitchOption(
                  context: context,
                  id: 'map',
                  label: 'Peta',
                  icon: Icons.map_rounded,
                  isSelected: _viewMode == 'map',
                ),
                const SizedBox(width: 4),
                _buildSwitchOption(
                  context: context,
                  id: 'list',
                  label: 'Daftar',
                  icon: Icons.format_list_bulleted_rounded,
                  isSelected: _viewMode == 'list',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchOption({
    required BuildContext context,
    required String id,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _viewMode = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAMPILAN PETA (MAP VIEW) ---
  Widget _buildMapSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Kumpulkan marker untuk peta
    final List<Marker> markers = [];

    // Marker Posisi Pengguna (Pulse radar)
    if (_userPosition != null) {
      markers.add(
        Marker(
          point: _userPosition!,
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Marker Lokasi Olahraga
    for (final loc in _filteredLocations) {
      final double? lat = (loc['latitude'] as num?)?.toDouble();
      final double? lng = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null || lat == 0 || lng == 0) continue;

      final bool isSelected = _selectedLocation?['id'] == loc['id'];
      final Color catColor = loc['color'] as Color? ?? colorScheme.primary;
      final IconData catIcon =
          loc['icon'] as IconData? ?? Icons.location_on_rounded;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: isSelected ? 52 : 44,
          height: isSelected ? 52 : 44,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedLocation = loc);
              _mapController.move(LatLng(lat, lng), 15.0);
            },
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 3 : 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.4),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      catIcon,
                      color: Colors.white,
                      size: isSelected ? 22 : 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Map Container
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xxs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Container(
            height: 380,
            decoration: BoxDecoration(
              borderRadius: AppRadius.roundedLg,
              border: Border.all(color: colorScheme.outline, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Flutter Map Widget
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _userPosition ?? _indramayuCenter,
                      initialZoom: 13.5,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      onTap: (_, __) {
                        setState(() => _selectedLocation = null);
                      },
                    ),
                    children: [
                      // OpenStreetMap Standard Tiles
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'id.my.fitlife.app',
                      ),
                      // Marker Layer
                      MarkerLayer(markers: markers),
                    ],
                  ),

                  // Floating Map Action Buttons
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        // Zoom In
                        _buildMapActionButton(
                          context: context,
                          icon: Icons.add_rounded,
                          tooltip: 'Perbesar',
                          onTap: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        // Zoom Out
                        _buildMapActionButton(
                          context: context,
                          icon: Icons.remove_rounded,
                          tooltip: 'Perkecil',
                          onTap: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom - 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        // Reset Bounds / All Markers
                        _buildMapActionButton(
                          context: context,
                          icon: Icons.crop_free_rounded,
                          tooltip: 'Tampilkan Semua Titik',
                          onTap: _resetMapBounds,
                        ),
                        const SizedBox(height: 6),
                        // My GPS Location
                        _buildMapActionButton(
                          context: context,
                          icon: Icons.my_location_rounded,
                          tooltip: 'Posisiku',
                          color: _userPosition != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          onTap: () {
                            if (_userPosition != null) {
                              _mapController.move(_userPosition!, 15.0);
                            } else {
                              _detectUserPosition(showFeedback: true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Floating Information Badge (Top Left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer.withValues(
                          alpha: 0.95,
                        ),
                        borderRadius: AppRadius.roundedSm,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 13,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'OpenStreetMap',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Detail Card saat Marker diklik
                  if (_selectedLocation != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: _buildFloatingSelectedCard(
                        context,
                        _selectedLocation!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Carousel / Kartu Horizontal Tempat Olahraga di Bawah Peta
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xxs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Titik Olahraga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Geser untuk memilih',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _filteredLocations.length,
            itemBuilder: (context, index) {
              final loc = _filteredLocations[index];
              final bool isSelected = _selectedLocation?['id'] == loc['id'];
              return _buildHorizontalLocationItem(context, loc, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 18,
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: color ?? colorScheme.onSurface),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFloatingSelectedCard(
    BuildContext context,
    Map<String, dynamic> loc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String name = (loc['name'] ?? 'Tempat Olahraga').toString();
    final String category = (loc['category'] ?? 'Olahraga').toString();
    final String address = (loc['address'] ?? 'Alamat belum tersedia')
        .toString();
    final String distance = (loc['distance'] ?? 'Belum diketahui').toString();
    final Color catColor = loc['color'] as Color? ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: catColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (distance != 'Belum diketahui')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 11,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      distance,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedLocation = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps((loc['mapQuery'] ?? name).toString()),
              icon: const Icon(Icons.directions_rounded, size: 16),
              label: Text(
                'Rute Navigasi Google Maps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLocationItem(
    BuildContext context,
    Map<String, dynamic> loc,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String name = (loc['name'] ?? 'Tempat').toString();
    final String category = (loc['category'] ?? 'Olahraga').toString();
    final String distance = (loc['distance'] ?? 'Belum diketahui').toString();
    final Color catColor = loc['color'] as Color? ?? colorScheme.primary;
    final IconData catIcon =
        loc['icon'] as IconData? ?? Icons.location_on_rounded;

    return GestureDetector(
      onTap: () => _focusLocationOnMap(loc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 230,
        margin: const EdgeInsets.only(right: AppSpacing.sm, bottom: 4),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Icon(catIcon, color: catColor, size: 16),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                        ),
                      ),
                      if (distance != 'Belum diketahui')
                        Text(
                          distance,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Fokus Peta',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAMPILAN DAFTAR (LIST VIEW) ---
  Widget _buildListSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredLocations.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final loc = _filteredLocations[index];
          return _buildLocationListCard(context, loc);
        },
      ),
    );
  }

  Widget _buildLocationListCard(
    BuildContext context,
    Map<String, dynamic> loc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String name = (loc['name'] ?? 'Tempat Olahraga').toString();
    final String category = (loc['category'] ?? 'Olahraga').toString();
    final String address = (loc['address'] ?? 'Alamat belum tersedia')
        .toString();
    final String distance = (loc['distance'] ?? 'Belum diketahui').toString();
    final String bmiTag = (loc['bmiLabel'] ?? '').toString();
    final Color catColor = loc['color'] as Color? ?? colorScheme.primary;
    final IconData catIcon =
        loc['icon'] as IconData? ?? Icons.location_on_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildBadge(
                          label: category,
                          bg: catColor.withValues(alpha: 0.12),
                          fg: catColor,
                        ),
                        if (bmiTag.isNotEmpty)
                          _buildBadge(
                            label: 'BMI: $bmiTag',
                            bg: colorScheme.surface,
                            fg: colorScheme.onSurfaceVariant,
                          ),
                        if (distance != 'Belum diketahui')
                          _buildBadge(
                            label: distance,
                            bg: colorScheme.primaryContainer,
                            fg: colorScheme.onPrimaryContainer,
                            icon: Icons.near_me_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 10),

          // Alamat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tombol Aksi: [Lihat di Peta] & [Buka Google Maps]
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _focusLocationOnMap(loc),
                  icon: const Icon(Icons.map_rounded, size: 15),
                  label: Text(
                    'Lihat di Peta',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openMaps((loc['mapQuery'] ?? name).toString()),
                  icon: const Icon(Icons.directions_rounded, size: 15),
                  label: Text(
                    'Rute Navigasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedMd,
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

  Widget _buildBadge({
    required String label,
    required Color bg,
    required Color fg,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.roundedSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // --- STATUS LOADING, ERROR, & EMPTY ---

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Memuat rekomendasi tempat olahraga...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _locationError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _loadLocations,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 42,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lokasi Tidak Ditemukan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada tempat olahraga yang cocok dengan pencarian "$_searchQuery".'
                : 'Belum ada rekomendasi tempat pada kategori ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Text(
                'Reset Pencarian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
