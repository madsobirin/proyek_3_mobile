import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _activeFilter = '';
  String _sortBy = 'terbaru'; // terbaru, kalori_asc, kalori_desc

  static const _green = Color(0xFF1AB673);

  static const _statusFilters = ['Kurus', 'Normal', 'Berlebih', 'Obesitas'];

  static const Map<String, Color> _statusColors = {
    'Kurus': Colors.blue,
    'Normal': Color(0xFF1AB673),
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
    var list = _allMenus.where((m) {
      final matchSearch = _search.isEmpty ||
          m.namaMenu.toLowerCase().contains(_search.toLowerCase()) ||
          m.deskripsi.toLowerCase().contains(_search.toLowerCase());
      final matchFilter =
          _activeFilter.isEmpty || m.targetStatus == _activeFilter;
      return matchSearch && matchFilter;
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
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
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
                      color: Colors.grey[300],
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
          color: isActive ? _green : Colors.black87,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _green),
      );
    }

    final filtered = _filteredMenus;

    return RefreshIndicator(
      color: _green,
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadMenus();
      },
      child: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Menu Sehat',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _sortBy != 'terbaru'
                            ? _green.withOpacity(0.12)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.sort,
                          size: 20,
                          color: _sortBy != 'terbaru'
                              ? _green
                              : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Cari resep atau bahan makanan...',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400], fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[400], size: 22),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() => _search = ''),
                          child: Icon(Icons.close,
                              color: Colors.grey[400], size: 20),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: _green, width: 1.5),
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
                    ..._statusFilters.map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _filterChip(s, s),
                        )),
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
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_activeFilter.isNotEmpty || _search.isNotEmpty)
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
                          color: _green,
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
                    Icon(Icons.restaurant_menu,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Menu tidak ditemukan',
                      style: GoogleFonts.poppins(color: Colors.grey[500]),
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
                          color: _green,
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
    );
  }

  Widget _filterChip(String label, String value) {
    final isActive = _activeFilter == value;
    final statusColor =
        value.isNotEmpty ? _getStatusColor(value) : _green;

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? statusColor.withOpacity(0.15) : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? statusColor : Colors.grey[200]!,
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
                color: isActive ? statusColor : Colors.grey[600],
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with status badge
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
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
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.namaMenu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.deskripsi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 14, color: Colors.orange[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${menu.kalori} kal',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.access_time,
                            size: 14, color: Colors.blue[300]),
                        const SizedBox(width: 4),
                        Text(
                          '${menu.waktuMemasak} mnt',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            size: 20, color: Colors.grey[400]),
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