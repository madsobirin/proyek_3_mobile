import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../services/artikel_service.dart';
import '../../services/news_service.dart';
import '../../models/artikel_model.dart';
import '../../models/news_article_model.dart';
import 'artikel_detail_page.dart';

class ArtikelPage extends StatefulWidget {
  final VoidCallback onBack;
  const ArtikelPage({super.key, required this.onBack});
  @override
  State<ArtikelPage> createState() => _ArtikelPageState();
}

class _ArtikelPageState extends State<ArtikelPage> {
  // ── Tab State ──
  int _selectedTabIndex = 0; // 0: Artikel FitLife, 1: FitNews

  // ── Tab 1: Artikel FitLife State ──
  final ArtikelService _artikelService = ArtikelService();
  List<ArtikelModel> _allArtikels = [];
  bool _isLoading = true;
  String _search = '';
  String _activeKategori = '';

  // ── Tab 2: FitNews State ──
  final NewsService _newsService = NewsService();
  final TextEditingController _newsSearchController = TextEditingController();
  final ScrollController _newsScrollController = ScrollController();
  Timer? _newsDebounceTimer;

  List<NewsArticleModel> _newsArticles = [];
  bool _isNewsLoading = false;
  bool _isNewsLoadingMore = false;
  int _newsPage = 1;
  final int _newsPageSize = 10;
  int _newsTotalResults = 0;
  bool _hasMoreNews = true;
  String _newsQuery = '';
  String? _newsError;

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

  @override
  void initState() {
    super.initState();
    _loadArtikels();
    _newsScrollController.addListener(_onNewsScroll);
  }

  @override
  void dispose() {
    _newsDebounceTimer?.cancel();
    _newsSearchController.dispose();
    _newsScrollController.removeListener(_onNewsScroll);
    _newsScrollController.dispose();
    super.dispose();
  }

  // ── Tab Navigation ──
  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
    if (index == 1 && _newsArticles.isEmpty && !_isNewsLoading) {
      _loadNews(refresh: true);
    }
  }

  // ── Tab 1 Methods (Artikel FitLife) ──
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
      final matchSearch =
          _search.isEmpty ||
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ── Tab 2 Methods (FitNews) ──
  void _onNewsScroll() {
    if (!_newsScrollController.hasClients) return;
    final maxScroll = _newsScrollController.position.maxScrollExtent;
    final currentScroll = _newsScrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      if (!_isNewsLoading && !_isNewsLoadingMore && _hasMoreNews) {
        _loadMoreNews();
      }
    }
  }

  void _onNewsSearchChanged(String query) {
    _newsDebounceTimer?.cancel();
    _newsDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _newsQuery = query;
      });
      _loadNews(refresh: true);
    });
  }

  Future<void> _loadNews({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isNewsLoading = true;
        _newsError = null;
        _newsPage = 1;
      });
    }

    try {
      final response = await _newsService.getNews(
        page: 1,
        pageSize: _newsPageSize,
        q: _newsQuery.trim().isEmpty ? null : _newsQuery.trim(),
      );

      if (mounted) {
        setState(() {
          _newsArticles = response.articles;
          _newsTotalResults = response.totalResults;
          _newsPage = 1;
          _hasMoreNews = response.articles.length >= _newsPageSize &&
              _newsArticles.length < _newsTotalResults;
          _isNewsLoading = false;
          _newsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNewsLoading = false;
          _newsError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isNewsLoadingMore || !_hasMoreNews) return;

    setState(() {
      _isNewsLoadingMore = true;
    });

    final nextPage = _newsPage + 1;
    try {
      final response = await _newsService.getNews(
        page: nextPage,
        pageSize: _newsPageSize,
        q: _newsQuery.trim().isEmpty ? null : _newsQuery.trim(),
      );

      if (mounted) {
        setState(() {
          _newsPage = nextPage;
          _newsArticles.addAll(response.articles);
          _newsTotalResults = response.totalResults;
          _hasMoreNews = response.articles.length >= _newsPageSize &&
              _newsArticles.length < _newsTotalResults;
          _isNewsLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isNewsLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openNewsUrl(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak dapat membuka tautan berita',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: _lightScheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatNewsDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ── UI Components ──
  Widget _buildFixedHeader() {
    final isFitNews = _selectedTabIndex == 1;
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
              isFitNews ? 'FitNews' : 'Artikel',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _lightScheme.primary,
              ),
            ),
          ),
          Icon(
            isFitNews ? Icons.newspaper_outlined : Icons.article_outlined,
            color: _lightScheme.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _lightScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              title: 'Artikel FitLife',
              icon: Icons.article_rounded,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTabButton(
              index: 1,
              title: 'FitNews',
              icon: Icons.newspaper_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isActive = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _lightScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _lightScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : _lightScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : _lightScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildFixedHeader(),
          _buildTabSwitcher(),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildArtikelTabContent(),
                _buildNewsTabContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1 View: Artikel FitLife ──
  Widget _buildArtikelTabContent() {
    final filtered = _filteredArtikels;
    final featured = _featuredArtikel;
    final showFeatured =
        featured != null && _search.isEmpty && _activeKategori.isEmpty;

    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: _lightScheme.primary,
            ),
          )
        : RefreshIndicator(
            color: _lightScheme.primary,
            onRefresh: () async {
              setState(() => _isLoading = true);
              await _loadArtikels();
            },
            child: CustomScrollView(
              slivers: [
                // ── Search Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: TextField(
                      style: GoogleFonts.poppins(
                        color: _lightScheme.onSurface,
                        fontSize: 14,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Cari artikel atau kategori...',
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
                                onTap: () => setState(() => _search = ''),
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
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: _lightScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: _lightScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: _lightScheme.primary,
                            width: 1.5,
                          ),
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
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: DecorationImage(
                              image: NetworkImage(featured.gambar),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.65),
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
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _lightScheme.primary,
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
                                    const Icon(
                                      Icons.access_time,
                                      size: 13,
                                      color: Color(0xFFF3F4F6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(featured.createdAt),
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFF3F4F6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Icon(
                                      Icons.visibility,
                                      size: 13,
                                      color: Color(0xFFF3F4F6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${featured.dibaca} views',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFF3F4F6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
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
                            ..._kategoris.map(
                              (k) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _kategoriChip(k, k),
                              ),
                            ),
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
                            color: _lightScheme.primary,
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
                              color: _lightScheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          '(${filtered.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _lightScheme.onSurfaceVariant,
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
                          Icon(
                            Icons.article_outlined,
                            size: 48,
                            color: _lightScheme.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada artikel yang cocok.',
                            style: GoogleFonts.poppins(
                              color: _lightScheme.onSurfaceVariant,
                            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _green : _lightScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _green : _lightScheme.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive
                ? _lightScheme.surface
                : _lightScheme.onSurfaceVariant,
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _lightScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _lightScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('⭐', style: GoogleFonts.poppins(fontSize: 8)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        artikel.kategori.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _lightScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      artikel.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _lightScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          artikel.penulis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _lightScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${artikel.dibaca}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _lightScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2 View: FitNews ──
  Widget _buildNewsTabContent() {
    return RefreshIndicator(
      color: _lightScheme.primary,
      onRefresh: () async {
        await _loadNews(refresh: true);
      },
      child: CustomScrollView(
        controller: _newsScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Search Bar FitNews (Debounce 400ms) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: TextField(
                controller: _newsSearchController,
                style: GoogleFonts.poppins(
                  color: _lightScheme.onSurface,
                  fontSize: 14,
                ),
                onChanged: _onNewsSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari berita kesehatan terkini...',
                  hintStyle: GoogleFonts.poppins(
                    color: _lightScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6B7280),
                    size: 22,
                  ),
                  suffixIcon: _newsSearchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _newsSearchController.clear();
                            _onNewsSearchChanged('');
                          },
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
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: _lightScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: _lightScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: _lightScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Header Summary ──
          if (!_isNewsLoading && _newsArticles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _lightScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _newsQuery.isNotEmpty
                            ? 'Hasil Pencarian Berita'
                            : 'Kabar Kesehatan Dunia',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _lightScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '$_newsTotalResults berita',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _lightScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // ── Loading Skeleton / Error / Empty / List ──
          if (_isNewsLoading)
            SliverToBoxAdapter(child: _buildNewsSkeleton())
          else if (_newsError != null && _newsArticles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildNewsErrorState(),
            )
          else if (_newsArticles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildNewsEmptyState(),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildFitNewsCard(_newsArticles[index]),
                  childCount: _newsArticles.length,
                ),
              ),
            ),
            if (_isNewsLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _lightScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            if (!_hasMoreNews && _newsArticles.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  child: Center(
                    child: Text(
                      'Semua berita telah dimuat',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _lightScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── FitNews Card Component ──
  Widget _buildFitNewsCard(NewsArticleModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _lightScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _lightScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openNewsUrl(article.url),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail dengan placeholder fallback
                _buildNewsThumbnail(article.image),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge media + Tanggal rilis
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: _lightScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  article.source.isNotEmpty
                                      ? article.source
                                      : 'Berita',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _lightScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            if (article.publishedAt != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatNewsDate(article.publishedAt),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: _lightScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Judul berita (max 2 baris, truncate)
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.3,
                            color: _lightScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Ringkasan deskripsi (max 3 baris)
                        if (article.description.isNotEmpty)
                          Text(
                            article.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              height: 1.3,
                              color: _lightScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Tombol / Aksi Tap (Baca Berita)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Baca Berita',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _lightScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: _lightScheme.primary,
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
        ),
      ),
    );
  }

  Widget _buildNewsThumbnail(String? imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: SizedBox(
        width: 108,
        child: (imageUrl != null && imageUrl.trim().isNotEmpty)
            ? Image.network(
                imageUrl.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _lightScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 108,
      color: _lightScheme.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_rounded,
            size: 32,
            color: _lightScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'FitNews',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _lightScheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 120,
          decoration: BoxDecoration(
            color: _lightScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _lightScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 108,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 70,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsEmptyState() {
    final isSearching = _newsQuery.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _lightScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.newspaper_rounded,
              size: 34,
              color: _lightScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Berita Tidak Ditemukan' : 'Belum Ada Berita',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _lightScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Tidak ada berita yang cocok dengan "$_newsQuery". Coba gunakan kata kunci lain.'
                : 'Saat ini belum ada berita kesehatan terbaru yang tersedia.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _lightScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (isSearching)
            ElevatedButton.icon(
              onPressed: () {
                _newsSearchController.clear();
                _onNewsSearchChanged('');
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reset Pencarian',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _lightScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _loadNews(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Muat Ulang',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _lightScheme.primary,
                side: BorderSide(color: _lightScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: _lightScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Gagal Memuat Berita',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _lightScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _newsError ?? 'Terjadi kendala saat menghubungkan ke server.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _lightScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadNews(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _lightScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
