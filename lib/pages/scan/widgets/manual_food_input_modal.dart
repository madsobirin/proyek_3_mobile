import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlife/models/scan_makanan_model.dart';
import 'package:fitlife/services/scan_service.dart';

class ManualFoodInputModal extends StatefulWidget {
  final String? initialBarcode;
  final Function(ScanMakananResult result)? onSaved;

  const ManualFoodInputModal({super.key, this.initialBarcode, this.onSaved});

  static Future<void> show(
    BuildContext context, {
    String? initialBarcode,
    Function(ScanMakananResult result)? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ManualFoodInputModal(
          initialBarcode: initialBarcode,
          onSaved: onSaved,
        ),
      ),
    );
  }

  @override
  State<ManualFoodInputModal> createState() => _ManualFoodInputModalState();
}

class _ManualFoodInputModalState extends State<ManualFoodInputModal> {
  final _formKey = GlobalKey<FormState>();
  final ScanService _scanService = ScanService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _imageUrlController;
  late TextEditingController _kaloriController;
  late TextEditingController _proteinController;
  late TextEditingController _lemakController;
  late TextEditingController _karboController;
  late TextEditingController _gulaController;

  XFile? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(
      text: widget.initialBarcode ?? '',
    );
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _imageUrlController = TextEditingController();
    _kaloriController = TextEditingController();
    _proteinController = TextEditingController();
    _lemakController = TextEditingController();
    _karboController = TextEditingController();
    _gulaController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _imageUrlController.dispose();
    _kaloriController.dispose();
    _proteinController.dispose();
    _lemakController.dispose();
    _karboController.dispose();
    _gulaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImage = picked;
          _imageUrlController.clear();
        });
      }
    } catch (_) {}
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Pilih Foto Makanan',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF15803D),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Ambil Foto Kamera',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _checkIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final barcode = _barcodeController.text.trim();
    final nama = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final kalori = double.tryParse(_kaloriController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final lemak = double.tryParse(_lemakController.text.trim());
    final karbo = double.tryParse(_karboController.text.trim());
    final gula = double.tryParse(_gulaController.text.trim());

    setState(() => _isSaving = true);

    String? imageUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : null;

    // Jika ada foto dari kamera/galeri, unggah ke backend untuk dapatkan public URL
    if (_selectedImage != null) {
      final uploadedUrl = await _scanService.uploadFoodImage(
        _selectedImage!.path,
      );
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        imageUrl = uploadedUrl;
      }
    }

    final item = ScanMakananResult(
      barcode: barcode,
      namaMakanan: nama,
      brand: brand.isNotEmpty ? brand : null,
      imageUrl: imageUrl,
      kalori: kalori,
      protein: protein,
      lemak: lemak,
      karbohidrat: karbo,
      gula: gula,
      createdAt: DateTime.now(),
    );

    final isLoggedIn = await _checkIsLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      setState(() => _isSaving = false);
      _showGuestLoginDialog(item);
      return;
    }

    try {
      final savedItem = await _scanService.saveScanResult(item);
      if (!mounted) return;

      Navigator.pop(context);
      widget.onSaved?.call(savedItem);

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
                  '${savedItem.namaMakanan} berhasil disimpan ke riwayat!',
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
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Jika gagal terhubung, simpan offline
      await _scanService.saveOfflineScan(item);
      if (!mounted) return;

      Navigator.pop(context);
      widget.onSaved?.call(item);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Koneksi bermasalah. Data disimpan offline & akan disinkronkan nanti.',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.amber[900],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showGuestLoginDialog(ScanMakananResult item) {
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
                color: const Color(0xFF00FF66).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_added_rounded,
                color: Color(0xFF15803D),
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
                      Navigator.pop(dialogCtx);
                      Navigator.pop(context);
                      ScanService.pendingScanResult = item;
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF66),
                      foregroundColor: const Color(0xFF111827),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Masuk',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF15803D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Input Makanan Manual',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Catat produk dan informasi nutrisi kemasan',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto Produk
                      _buildLabel('Foto Produk Kemasan (Opsional)'),
                      if (_selectedImage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Foto dipilih',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      _selectedImage!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _showImageSourcePicker,
                                child: const Text('Ganti'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () =>
                                    setState(() => _selectedImage = null),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        GestureDetector(
                          onTap: _showImageSourcePicker,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 18,
                                  color: Color(0xFF15803D),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ambil / Pilih Foto Kemasan',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _imageUrlController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: _buildInputDecoration(
                            hint: 'Atau tempel link URL foto produk (opsional)',
                            icon: Icons.link_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Barcode field
                      _buildLabel('Barcode Produk *'),
                      TextFormField(
                        controller: _barcodeController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: 8992761011111',
                          icon: Icons.qr_code_2_rounded,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Barcode wajib diisi';
                          }
                          if (!ScanService.isValidBarcode(val)) {
                            return 'Barcode harus 3-64 digit angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Nama Makanan field
                      _buildLabel('Nama Makanan *'),
                      TextFormField(
                        controller: _nameController,
                        maxLength: 500,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Susu UHT Full Cream',
                          icon: Icons.fastfood_rounded,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama makanan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Brand field
                      _buildLabel('Merek / Brand (Opsional)'),
                      TextFormField(
                        controller: _brandController,
                        maxLength: 500,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Ultra Milk',
                          icon: Icons.branding_watermark_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header Nutrisi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Informasi Nutrisi (Opsional)',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'per 100g / porsi',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kalori (Utama)
                      TextFormField(
                        controller: _kaloriController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Kalori (kkal), misal: 150',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: Colors.orange,
                        ),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 12),

                      // Grid Makronutrisi: Protein & Lemak
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _proteinController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(
                                hint: 'Protein (g)',
                                icon: Icons.fitness_center_rounded,
                                iconColor: Colors.purple,
                              ),
                              validator: _numberValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lemakController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(
                                hint: 'Lemak (g)',
                                icon: Icons.water_drop_rounded,
                                iconColor: Colors.amber[800],
                              ),
                              validator: _numberValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Grid Makronutrisi: Karbo & Gula
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _karboController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(
                                hint: 'Karbohidrat (g)',
                                icon: Icons.grain_rounded,
                                iconColor: Colors.blue,
                              ),
                              validator: _numberValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _gulaController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(
                                hint: 'Gula (g)',
                                icon: Icons.cake_rounded,
                                iconColor: Colors.pinkAccent,
                              ),
                              validator: _numberValidator,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                        'Batal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF66),
                        foregroundColor: const Color(0xFF111827),
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
                                color: Color(0xFF111827),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.bookmark_add_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Simpan ke Riwayat',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Color? iconColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF9CA3AF),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: iconColor ?? const Color(0xFF15803D),
        size: 18,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00FF66), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  String? _numberValidator(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final parsed = double.tryParse(val.trim());
    if (parsed == null || parsed < 0) {
      return 'Angka tidak valid';
    }
    return null;
  }
}
