import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlife/models/food_compatibility_model.dart';
import 'package:fitlife/models/scan_makanan_model.dart';
import 'package:fitlife/services/food_compatibility_service.dart';
import 'package:fitlife/services/perhitungan_service.dart';
import 'package:fitlife/services/scan_service.dart';

class ScanResultModal extends StatefulWidget {
  final ScanMakananResult result;
  final VoidCallback onDismissed;

  const ScanResultModal({
    super.key,
    required this.result,
    required this.onDismissed,
  });

  static Future<void> show(
    BuildContext context,
    ScanMakananResult result, {
    required VoidCallback onDismissed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ScanResultModal(result: result, onDismissed: onDismissed),
    ).then((_) => onDismissed());
  }

  @override
  State<ScanResultModal> createState() => _ScanResultModalState();
}

class _ScanResultModalState extends State<ScanResultModal> {
  final ScanService _scanService = ScanService();
  final PerhitunganService _perhitunganService = PerhitunganService();
  bool _isSaving = false;
  FoodCompatibilityResult? _compatibility;
  bool _isLoadingCompatibility = true;

  @override
  void initState() {
    super.initState();
    _loadCompatibility();
  }

  Future<void> _loadCompatibility() async {
    try {
      final userHealth = await _perhitunganService.getLatestPerhitungan();
      if (!mounted) return;
      final verdict = FoodCompatibilityService.evaluasi(
        food: widget.result,
        userHealth: userHealth,
      );
      setState(() {
        _compatibility = verdict;
        _isLoadingCompatibility = false;
      });
    } catch (_) {
      if (!mounted) return;
      final fallbackVerdict = FoodCompatibilityService.evaluasi(
        food: widget.result,
        userHealth: null,
      );
      setState(() {
        _compatibility = fallbackVerdict;
        _isLoadingCompatibility = false;
      });
    }
  }

  Future<bool> _checkIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final isLoggedIn = await _checkIsLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      _showGuestLoginDialog();
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _scanService.saveScanResult(widget.result);
      if (!mounted) return;

      Navigator.pop(context); // Tutup modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.result.namaMakanan} berhasil disimpan ke riwayat!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final errorMsg = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Simpan Offline',
            textColor: const Color(0xFF20603D),
            onPressed: () async {
              await _scanService.saveOfflineScan(widget.result);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tersimpan offline. Akan disinkronkan saat membuka riwayat.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  void _showGuestLoginDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF20603D).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_added_rounded,
                color: Color(0xFF20603D),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Simpan ke Riwayat Akun',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masuk atau buat akun FitLife terlebih dahulu agar riwayat scan makanan tersimpan dan dapat diakses kapan saja.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx); // Tutup dialog
                      Navigator.pop(context); // Tutup modal
                      // Simpan data pending scan
                      ScanService.pendingScanResult = widget.result;
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20603D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Masuk',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.result;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto Produk & Info Dasar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 90,
                            height: 90,
                            color: const Color(0xFFF3F4F6),
                            child:
                                item.imageUrl != null &&
                                    item.imageUrl!.isNotEmpty
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.restaurant_rounded,
                                        color: Color(0xFF9CA3AF),
                                        size: 36,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.fastfood_rounded,
                                      color: Color(0xFF9CA3AF),
                                      size: 36,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF20603D,
                                      ).withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.brand ?? 'Produk Makanan',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF20603D),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.namaMakanan,
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 14,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.barcode,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 20),

                    // Evaluasi Kecocokan Makanan dengan Profil Kesehatan
                    _buildCompatibilitySection(),

                    // Header Nutrisi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rincian Nutrisi',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'per 100g / porsi',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card Kalori Utama (Highlight)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEBF3ED), Color(0xFFDCECE0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF20603D).withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.orange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL ENERGI / KALORI',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.kalori != null
                                    ? '${item.kalori!.toStringAsFixed(1)} kkal'
                                    : 'Data tidak tersedia',
                                style: GoogleFonts.manrope(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Grid Makronutrisi (Protein, Lemak, Karbohidrat, Gula)
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutrientCard(
                            title: 'Protein',
                            value: item.protein != null
                                ? '${item.protein!.toStringAsFixed(1)} g'
                                : '-',
                            icon: Icons.fitness_center_rounded,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNutrientCard(
                            title: 'Lemak',
                            value: item.lemak != null
                                ? '${item.lemak!.toStringAsFixed(1)} g'
                                : '-',
                            icon: Icons.water_drop_rounded,
                            color: Colors.amber[800]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutrientCard(
                            title: 'Karbohidrat',
                            value: item.karbohidrat != null
                                ? '${item.karbohidrat!.toStringAsFixed(1)} g'
                                : '-',
                            icon: Icons.grain_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNutrientCard(
                            title: 'Gula',
                            value: item.gula != null
                                ? '${item.gula!.toStringAsFixed(1)} g'
                                : '-',
                            icon: Icons.cake_rounded,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: widget.result.id != null
                        ? OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Color(0xFF15803D),
                            ),
                            label: Text(
                              'Tersimpan di Riwayat',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF20603D),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF20603D)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF20603D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.bookmark_add_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Simpan ke Riwayat',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilitySection() {
    if (_isLoadingCompatibility) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF20603D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Menganalisis kecocokan dengan profil tubuhmu...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final compat = _compatibility;
    if (compat == null) return const SizedBox.shrink();

    final Color badgeBg;
    final Color badgeBorder;
    final Color badgeColor;
    final IconData badgeIcon;

    switch (compat.level) {
      case CompatibilityLevel.cocok:
        badgeBg = const Color(0xFFECFDF5);
        badgeBorder = const Color(0xFF10B981).withValues(alpha: 0.35);
        badgeColor = const Color(0xFF047857);
        badgeIcon = Icons.check_circle_rounded;
        break;
      case CompatibilityLevel.perluPerhatian:
        badgeBg = const Color(0xFFFFFBEB);
        badgeBorder = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        badgeColor = const Color(0xFFB45309);
        badgeIcon = Icons.info_rounded;
        break;
      case CompatibilityLevel.kurangCocok:
        badgeBg = const Color(0xFFFEF2F2);
        badgeBorder = const Color(0xFFEF4444).withValues(alpha: 0.35);
        badgeColor = const Color(0xFFB91C1C);
        badgeIcon = Icons.warning_amber_rounded;
        break;
    }

    final double kaloriPercent = compat.kaloriPercent ?? 0.0;
    final double progressVal = (kaloriPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeBorder),
                ),
                child: Icon(badgeIcon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          compat.title,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Text(
                            compat.userStatus != null
                                ? 'BMI: ${compat.userStatus}'
                                : 'Standar AKG',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compat.summary,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kontribusi Kuota Kalori Harian',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    Text(
                      compat.kaloriPercent != null
                          ? '${compat.kaloriPercent!.toStringAsFixed(0)}% dari ${compat.userTargetKalori.round()} kkal'
                          : 'Target: ${compat.userTargetKalori.round()} kkal',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressVal,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                  ),
                ),
              ],
            ),
          ),
          if (compat.warnings.isNotEmpty || compat.highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...compat.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.priority_high_rounded,
                      size: 14,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        w,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...compat.highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        h,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF166534),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    compat.detailAdvice,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (compat.isGuestFallback) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/bmi');
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF20603D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF20603D).withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calculate_outlined,
                      size: 16,
                      color: Color(0xFF20603D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hitung BMI di Kalkulator untuk analisa personal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF20603D),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF20603D),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
