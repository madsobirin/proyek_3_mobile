import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/artikel_service.dart';
import '../../models/artikel_model.dart';
import 'artikel_detail_page.dart';

class ArtikelPage extends StatefulWidget {
  final VoidCallback onBack;
  const ArtikelPage({super.key, required this.onBack});

  @override
  State<ArtikelPage> createState() => _ArtikelPageState();
}

class _ArtikelPageState extends State<ArtikelPage> {
  final ArtikelService _artikelService = ArtikelService();
  List<ArtikelModel> _allArtikels = [];
  bool _isLoading = true;
  String _search = '';
  String _activeKategori = '';

  static const _green = Color(0xFF1AB673);

  @override
  void initState() {
    super.initState();
    _loadArtikels();
  }

  Future<void> _loadArtikels() async {
    try {
      final artikels = await _artikelService.getArtikels();
      if (mounted) {
        setState(() {
          _allArtikels = artikels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _kategoris {
    return _allArtikels.map((a) => a.kategori).toSet().toList();
  }

  List<ArtikelModel> get _filteredArtikels {
    return _allArtikels.where((a) {
      final matchSearch = _search.isEmpty ||
          a.judul.toLowerCase().contains(_search.toLowerCase()) ||
          a.kategori.toLowerCase().contains(_search.toLowerCase());
      final matchKategori =
          _activeKategori.isEmpty || a.kategori == _activeKategori;
      return matchSearch && matchKategori;
    }).toList();
  }

  ArtikelModel? get _featuredArtikel {
    if (_allArtikels.isEmpty) return null;
    try {
      return _allArtikels.firstWhere((a) => a.isFeatured);
    } catch (_) {
      return _allArtikels.first;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _green),
      );
    }

    final filtered = _filteredArtikels;
    final featured = _featuredArtikel;
    final showFeatured =
        featured != null && _search.isEmpty && _activeKategori.isEmpty;

    return RefreshIndicator(
      color: _green,
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadArtikels();
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
                  Text(
                    'Artikel & Tips',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                  hintText: 'Cari artikel atau kategori...',
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

          // ── Featured Article ──
          if (showFeatured)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ArtikelDetailPage(artikel: featured),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                        image: NetworkImage(featured.gambar),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.65),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '⭐ UNGGULAN',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            featured.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(featured.createdAt),
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Icon(Icons.visibility,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                '${featured.dibaca} views',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Kategori Filter ──
          if (_kategoris.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _kategoriChip('Semua', ''),
                      const SizedBox(width: 8),
                      ..._kategoris.map((k) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _kategoriChip(k, k),
                          )),
                    ],
                  ),
                ),
              ),
            ),

          // ── Section Title ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _activeKategori.isNotEmpty || _search.isNotEmpty
                          ? 'Hasil Pencarian'
                          : 'Artikel Terbaru',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '(${filtered.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Article List ──
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Icon(Icons.article_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada artikel yang cocok.',
                      style: GoogleFonts.poppins(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeKategori = '';
                          _search = '';
                        });
                      },
                      child: Text(
                        'Reset pencarian',
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
                  (context, index) => _articleCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kategoriChip(String label, String value) {
    final isActive = _activeKategori == value;

    return GestureDetector(
      onTap: () => setState(() => _activeKategori = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _green : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _green : Colors.grey[200]!,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _articleCard(ArtikelModel artikel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtikelDetailPage(artikel: artikel),
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
            // Image
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    color: Colors.grey[200],
                    image: DecorationImage(
                      image: NetworkImage(artikel.gambar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (artikel.isFeatured)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⭐',
                        style: GoogleFonts.poppins(fontSize: 8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        artikel.kategori.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      artikel.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          artikel.penulis,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.visibility_outlined,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${artikel.dibaca}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right,
                  size: 20, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
