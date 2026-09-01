import 'dart:convert';
import 'package:fitlife/models/user_model.dart';
import 'package:fitlife/services/auth_services.dart';
import 'package:fitlife/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final AuthServices _authServices = AuthServices();
  final ApiService _apiService = ApiService();

  UserModel? _user;
  bool _loading = true;
  bool _savingField = false;
  bool _uploadingAvatar = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _birthDate;
  bool _changingPassword = false;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final Map<String, bool> _editing = {
    'username': false,
    'phone': false,
    'height': false,
    'weight': false,
  };

  static const Color _bg = Color(0xFFF8FFFA);
  static const Color _primary = Color(0xFF00FF66);
  static const Color _primaryDark = Color(0xFF15803D);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fetchProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Fetch profile dari API /api/profile ──
  Future<void> _fetchProfile() async {
    setState(() => _loading = true);

    try {
      final response = await _apiService.get('/profile');
      final data = _apiService.handleResponse(response);

      final userData = data['user'] ?? data;
      final token = await _authServices.getToken();
      final user = UserModel.fromJson({...userData, 'token': token});

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));

      setState(() {
        _user = user;
        _usernameController.text = user.username ?? '';
        _phoneController.text = user.phone ?? '';
        _heightController.text = user.height?.toString() ?? '';
        _weightController.text = user.weight?.toString() ?? '';
        if (user.birthdate != null) {
          _birthDate = DateTime.tryParse(user.birthdate!);
        }
        _loading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ── Save field ke API PATCH /api/profile ──
  Future<void> _saveField(String field, dynamic value) async {
    setState(() => _savingField = true);

    try {
      final Map<String, dynamic> body = {};
      switch (field) {
        case 'username':
          body['username'] = value;
          break;
        case 'phone':
          body['phone'] = value;
          break;
        case 'height':
          body['height'] = int.tryParse(value.toString());
          break;
        case 'weight':
          body['weight'] = int.tryParse(value.toString());
          break;
        case 'birthdate':
          body['birthdate'] = DateFormat(
            'yyyy-MM-dd',
          ).format(value as DateTime);
          break;
      }

      final response = await _apiService.patch('/profile', body);
      final data = _apiService.handleResponse(response);
      final userData = data['user'] ?? data;
      final token = await _authServices.getToken();
      final user = UserModel.fromJson({...userData, 'token': token});

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));

      setState(() {
        _user = user;
        _editing[field] = false;
        _savingField = false;
      });

      if (!mounted) return;
      _showSuccessSnackBar('Berhasil disimpan');
    } catch (e) {
      setState(() {
        _editing[field] = false;
        _savingField = false;
      });
      if (!mounted) return;
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: _primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF00FF66),
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
      await _saveField('birthdate', picked);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Kompres ukuran file (0-100)
      maxWidth: 800, // Resize ukuran pixel maksimal
      maxHeight: 800,
    );

    if (pickedFile == null) return;

    setState(() => _uploadingAvatar = true);

    try {
      final response = await _apiService.postMultipart(
        '/profile/upload', // Sesuai dengan app/api/profile/upload/route.ts di web
        'photo',
        pickedFile.path,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final userData = data['user'] ?? data;
        final token = await _authServices.getToken();
        final user = UserModel.fromJson({...userData, 'token': token});

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user.toJson()));

        setState(() {
          _user = user;
          _uploadingAvatar = false;
        });

        if (!mounted) return;
        _showSuccessSnackBar('Foto profil berhasil diperbarui');
      } else {
        throw Exception(data['message'] ?? 'Gagal mengupload foto');
      }
    } catch (e) {
      setState(() => _uploadingAvatar = false);
      if (!mounted) return;
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Keluar Akun?',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda akan keluar dari akun ini.\nLogin ulang diperlukan untuk melanjutkan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Keluar',
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

    if (confirm != true) return;
    await _authServices.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/login',
      arguments: {'message': 'Berhasil keluar dari akun'},
    );
  }

  String get _initials {
    final name = _user?.name ?? '';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: Stack(
                children: [
                  Positioned(
                    top: -80,
                    right: -80,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x1A00FF66),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 160,
                    left: -80,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x0D3B82F6),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildHeader(),
                              const SizedBox(height: 24),
                              _buildAvatarCard(),
                              const SizedBox(height: 20),
                              _buildFieldCard(
                                icon: Icons.person_outline_rounded,
                                label: 'NAMA LENGKAP',
                                value: _user?.name ?? '-',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildEditableCard(
                                      fieldKey: 'username',
                                      icon: Icons.alternate_email_rounded,
                                      label: 'USERNAME',
                                      controller: _usernameController,
                                      hint: 'Klik untuk mengisi',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildFieldCard(
                                      icon: Icons.email_outlined,
                                      label: 'EMAIL',
                                      value: _user?.email ?? '-',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildEditableCard(
                                      fieldKey: 'phone',
                                      icon: Icons.phone_outlined,
                                      label: 'NOMOR TELEPON',
                                      controller: _phoneController,
                                      hint: 'Klik untuk mengisi',
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildDateCard()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildEditableCard(
                                      fieldKey: 'weight',
                                      icon: Icons.monitor_weight_outlined,
                                      label: 'BERAT (KG)',
                                      controller: _weightController,
                                      hint: 'Klik untuk mengisi',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildEditableCard(
                                      fieldKey: 'height',
                                      icon: Icons.height_rounded,
                                      label: 'TINGGI (CM)',
                                      controller: _heightController,
                                      hint: 'Klik untuk mengisi',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPasswordCard(),
                              const SizedBox(height: 20),
                              _buildLogoutButton(),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Klik pada field untuk mengedit • Email tidak dapat diubah',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ]),
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

  Widget _buildHeader() {
    return Row(
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
            color: _textDark,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF66).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF66).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF00FF66).withOpacity(0.4),
                      width: 1.5,
                    ),
                    image: _user?.photo != null
                        ? DecorationImage(
                            image: NetworkImage(_user!.photo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _user?.photo == null
                      ? Center(
                          child: Text(
                            _initials,
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _primaryDark,
                            ),
                          ),
                        )
                      : null,
                ),
                if (_uploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 10,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.name ?? 'User',
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _user?.email ?? '-',
                  style: GoogleFonts.inter(fontSize: 13, color: _textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (_user?.role ?? 'user').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _primaryDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: _primaryDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _primaryDark,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard({
    required String fieldKey,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isEditing = _editing[fieldKey] ?? false;
    return GestureDetector(
      onTap: isEditing ? null : () => setState(() => _editing[fieldKey] = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEditing ? const Color(0xFFF0FFF4) : _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEditing ? _primary : _border,
            width: isEditing ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: _primaryDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _primaryDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (isEditing)
                  GestureDetector(
                    onTap: _savingField
                        ? null
                        : () => _saveField(fieldKey, controller.text),
                    child: _savingField
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF15803D),
                            ),
                          )
                        : Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: _primaryDark,
                          ),
                  )
                else
                  Icon(Icons.edit_outlined, size: 13, color: _textMuted),
              ],
            ),
            const SizedBox(height: 8),
            isEditing
                ? TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: _textMuted,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    controller.text.isEmpty ? hint : controller.text,
                    style: GoogleFonts.inter(
                      fontSize: controller.text.isEmpty ? 13 : 14,
                      fontWeight: controller.text.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: controller.text.isEmpty ? _textMuted : _textDark,
                      fontStyle: controller.text.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: _primaryDark,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'TGL LAHIR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _primaryDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Icon(Icons.edit_outlined, size: 13, color: _textMuted),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _birthDate != null
                  ? DateFormat('dd MMM yyyy').format(_birthDate!)
                  : 'Klik untuk mengisi',
              style: GoogleFonts.inter(
                fontSize: _birthDate != null ? 14 : 13,
                fontWeight: _birthDate != null
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: _birthDate != null ? _textDark : _textMuted,
                fontStyle: _birthDate != null
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return GestureDetector(
      onTap: _showPasswordDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubah Password',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    'Perbarui password akun kamu',
                    style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Keluar dari Akun',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _obscureCurrent = true;
    _obscureNew = true;
    _obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Ubah Password',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                Text(
                  'Masukkan password lama dan baru kamu',
                  style: GoogleFonts.inter(fontSize: 13, color: _textMuted),
                ),
                const SizedBox(height: 24),

                // Current password
                _buildPasswordInput(
                  controller: _currentPasswordController,
                  label: 'Password Saat Ini',
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setModalState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 16),

                // New password
                _buildPasswordInput(
                  controller: _newPasswordController,
                  label: 'Password Baru',
                  obscure: _obscureNew,
                  onToggle: () =>
                      setModalState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 16),

                // Confirm password
                _buildPasswordInput(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password Baru',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setModalState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _changingPassword
                        ? null
                        : () async {
                            if (_newPasswordController.text !=
                                _confirmPasswordController.text) {
                              _showErrorSnackBar(
                                'Konfirmasi password tidak cocok',
                              );
                              return;
                            }
                            if (_newPasswordController.text.length < 8) {
                              _showErrorSnackBar(
                                'Password baru minimal 8 karakter',
                              );
                              return;
                            }

                            setModalState(() => _changingPassword = true);

                            try {
                              final res = await _apiService
                                  .patch('/profile/password', {
                                    'currentPassword':
                                        _currentPasswordController.text,
                                    'newPassword': _newPasswordController.text,
                                  });

                              setModalState(() => _changingPassword = false);

                              if (res.statusCode == 200) {
                                if (!mounted) return;
                                Navigator.of(ctx).pop();
                                _showSuccessSnackBar(
                                  'Password berhasil diubah',
                                );
                              } else {
                                final data = jsonDecode(res.body);
                                if (!mounted) return;
                                _showErrorSnackBar(
                                  data['message'] ?? 'Gagal mengubah password',
                                );
                              }
                            } catch (e) {
                              setModalState(() => _changingPassword = false);
                              if (!mounted) return;
                              _showErrorSnackBar('Terjadi kesalahan koneksi');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF66),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _changingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'Simpan Password',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
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

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 15, color: _textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color: _textMuted,
              ),
            ),
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
              borderSide: const BorderSide(color: Color(0xFF00FF66), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
