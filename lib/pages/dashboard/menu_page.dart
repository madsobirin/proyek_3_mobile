import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/menu_service.dart';
import '../../models/menu_model.dart';
import 'menu_detail.dart';

class MenuPage extends StatefulWidget {
  final VoidCallback onBack;
  const MenuPage({super.key, required this.onBack});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuService _menuService = MenuService();
  List<MenuModel> _allMenus = [];
  bool _isLoading = true;
  String _search = '';
  String _budgetLimit = '';
  String _activeFilter = '';
  String _sortBy = 'terbaru'; // terbaru, kalori_asc, kalori_desc
  static const _green = AppColors.primaryLight;
  static const ColorScheme _lightScheme = ColorScheme(
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
  static const _statusFilters = ['Kurus', 'Normal', 'Berlebih', 'Obesitas'];
  static const Map<String, Color> _statusColors = {
    'Kurus': Colors.blue,
    'Normal': Color(0xFF20603D),
    'Berlebih': Colors.orange,
    'Obesitas': Colors.red,
  };
  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      final menus = await _menuService.getMenus();
      if (mounted) {
        setState(() {
          _allMenus = menus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<MenuModel> get _filteredMenus {
    final budgetText = _budgetLimit.trim();
    final maxBudget = num.tryParse(budgetText);

    var list = _allMenus.where((m) {
      final matchSearch =
          _search.isEmpty ||
          m.namaMenu.toLowerCase().contains(_search.toLowerCase()) ||
          m.deskripsi.toLowerCase().contains(_search.toLowerCase());
      final matchFilter =
          _activeFilter.isEmpty || m.targetStatus == _activeFilter;
      final matchBudget =
          budgetText.isEmpty ||
          (maxBudget != null &&
              maxBudget > 0 &&
              m.biayaPerPorsi != null &&
              m.biayaPerPorsi! <= maxBudget);
      return matchSearch && matchFilter && matchBudget;
    }).toList();
    switch (_sortBy) {
      case 'kalori_asc':
        list.sort((a, b) => a.kalori.compareTo(b.kalori));
        break;
      case 'kalori_desc':
        list.sort((a, b) => b.kalori.compareTo(a.kalori));
        break;
      case 'terbaru':
      default:
        list.sort(
          (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
            a.createdAt ?? DateTime(2000),
          ),
        );
        break;
    }
    return list;
  }

  Color _getStatusColor(String status) {
    return _statusColors[status] ?? Colors.grey;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _lightScheme.surface, // Tambahkan ini
      // surfaceTintColor: _lightScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _lightScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Urutkan Menu',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _lightScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _sortOption('Terbaru', 'terbaru', ctx),
                _sortOption('Kalori Terendah', 'kalori_asc', ctx),
                _sortOption('Kalori Tertinggi', 'kalori_desc', ctx),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortOption(String label, String value, BuildContext ctx) {
    final isActive = _sortBy == value;
    return ListTile(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(ctx);
      },
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isActive ? _green : Colors.grey,
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? _green : _lightScheme.onSurface,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _lightScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: _lightScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _lightScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _lightScheme.outline),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: _lightScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Menu',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _lightScheme.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _sortBy != 'terbaru'
                    ? _lightScheme.primaryContainer
                    : _lightScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _lightScheme.outline),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.sort, size: 20, color: _lightScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMenus;
    return SafeArea(
      child: Column(
        children: [
          _buildFixedHeader(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _lightScheme.primary,
                    ),
                  )
                : RefreshIndicator(
                    color: _lightScheme.primary,
                    onRefresh: () async {
                      setState(() => _isLoading = true);
                      await _loadMenus();
                    },
                    child: CustomScrollView(
                      slivers: [
                        // ── Search Bar ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: TextField(
                              style: GoogleFonts.poppins(
                                color: _lightScheme.onSurface,
                                fontSize: 14,
                              ),
                              onChanged: (v) => setState(() => _search = v),
                              decoration: InputDecoration(
                                hintText: 'Cari resep atau bahan makanan...',
                                hintStyle: GoogleFonts.poppins(
                                  color: _lightScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF6B7280),
                                  size: 22,
                                ),
                                suffixIcon: _search.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () =>
                                            setState(() => _search = ''),
                                        child: const Icon(
                                          Icons.close,
                                          color: Color(0xFF6B7280),
                                          size: 20,
                                        ),
                                      )
                                    : null,
                                filled: true,
                                fillColor: _lightScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _lightScheme.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _lightScheme.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _lightScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // ── Low Budget ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: TextField(
                              style: GoogleFonts.poppins(
                                color: _lightScheme.onSurface,
                                fontSize: 14,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              onChanged: (value) =>
                                  setState(() => _budgetLimit = value),
                              decoration: InputDecoration(
                                hintText: 'Budget maks. (Rp/porsi)',
                                hintStyle: GoogleFonts.poppins(
                                  color: _lightScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: _lightScheme.primary,
                                ),
                                suffixIcon: _budgetLimit.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () =>
                                            setState(() => _budgetLimit = ''),
                                      )
                                    : null,
                                filled: true,
                                fillColor: _lightScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _lightScheme.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _lightScheme.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _lightScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // ── Filter Chips ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _filterChip('Semua', ''),
                                  const SizedBox(width: 8),
                                  ..._statusFilters.map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _filterChip(s, s),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // ── Count + Sort Label ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${filtered.length} menu ditemukan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _lightScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (_activeFilter.isNotEmpty ||
                                    _search.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _activeFilter = '';
                                        _search = '';
                                      });
                                    },
                                    child: Text(
                                      'Reset filter',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: _lightScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // ── Menu List ──
                        if (filtered.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 48,
                                    color: _lightScheme.outlineVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Menu tidak ditemukan',
                                    style: GoogleFonts.poppins(
                                      color: _lightScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _activeFilter = '';
                                        _search = '';
                                      });
                                    },
                                    child: Text(
                                      'Reset filter',
                                      style: GoogleFonts.poppins(
                                        color: _lightScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _menuCard(filtered[index]),
                                childCount: filtered.length,
                              ),
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

  Widget _filterChip(String label, String value) {
    final isActive = _activeFilter == value;
    final statusColor = value.isNotEmpty ? _getStatusColor(value) : _green;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? statusColor.withValues(alpha: 0.15)
              : _lightScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? statusColor : _lightScheme.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.isNotEmpty) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? statusColor : _lightScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(MenuModel menu) {
    final statusColor = _getStatusColor(menu.targetStatus);
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _lightScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with status badge
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(menu.gambar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      menu.targetStatus,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.namaMenu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _lightScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.deskripsi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _lightScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${menu.kalori} kal',
                          style: GoogleFonts.poppins(
                            color: _lightScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${menu.waktuMemasak} mnt',
                          style: GoogleFonts.poppins(
                            color: _lightScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
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
}
