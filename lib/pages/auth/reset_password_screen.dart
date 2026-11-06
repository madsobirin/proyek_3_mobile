import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_services.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// Token JWT dari deep link / argument navigasi.
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthServices _authServices = AuthServices();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _tokenError;
  String? _passwordError;
  String? _confirmError;

  static const _primary = Color(0xFF20603D);
  static const _bg = Color(0xFFF8FFFA);

  // Regex sesuai spesifikasi backend
  static final _hasLetter = RegExp(r'[a-zA-Z]');
  static final _hasDigit = RegExp(r'[0-9]');

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Validasi lokal semua field. Return true jika lolos.
  bool _validate() {
    bool ok = true;

    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _tokenError = 'Token reset wajib diisi.');
      ok = false;
    } else {
      setState(() => _tokenError = null);
    }

    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _passwordError = 'Password minimal 8 karakter.');
      ok = false;
    } else if (!_hasLetter.hasMatch(password)) {
      setState(() => _passwordError = 'Password harus mengandung minimal 1 huruf.');
      ok = false;
    } else if (!_hasDigit.hasMatch(password)) {
      setState(() => _passwordError = 'Password harus mengandung minimal 1 angka.');
      ok = false;
    } else {
      setState(() => _passwordError = null);
    }

    if (_confirmController.text != _passwordController.text) {
      setState(() => _confirmError = 'Konfirmasi password tidak cocok.');
      ok = false;
    } else {
      setState(() => _confirmError = null);
    }

    return ok;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);

    final result = await _authServices.resetPassword(
      token: _tokenController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Sukses: navigasi ke login dengan pesan
      Navigator.pushReplacementNamed(
        context,
        '/login',
        arguments: {
          'message':
              'Kata sandi berhasil diperbarui! Silakan login dengan kata sandi baru.',
        },
      );
    } else if (result['fieldErrors'] != null) {
      // Validasi field dari backend
      final errors = result['fieldErrors'] as Map<String, dynamic>;
      setState(() {
        _tokenError = (errors['token'] as List?)?.first as String?;
        _passwordError = (errors['password'] as List?)?.first as String?;
      });
    } else {
      // Token expired / invalid / reused — arahkan ke forgot password
      _showTokenErrorDialog(
        result['message'] ??
            'Tautan reset tidak valid atau telah kedaluwarsa.',
      );
    }
  }

  void _showTokenErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Tautan Tidak Valid',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF374151),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/forgot-password');
            },
            child: Text(
              'Minta Tautan Baru',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Image(image: AssetImage('assets/images/logo.png')),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FitLife.id',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.key_rounded,
            size: 28,
            color: _primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Buat Kata Sandi Baru',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan token dari email dan kata sandi baru Anda.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // ── Token field (hanya tampil jika tidak ada initialToken) ──
        if (widget.initialToken == null) ...[
          _buildLabel('Token Reset'),
          const SizedBox(height: 6),
          TextField(
            controller: _tokenController,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Paste token dari email di sini',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.vpn_key_rounded,
                  size: 22,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              errorText: _tokenError,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
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
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Password baru ──
        _buildLabel('Kata Sandi Baru'),
        const SizedBox(height: 6),
        _buildPasswordField(
          controller: _passwordController,
          hint: 'Minimal 8 karakter, ada huruf & angka',
          obscure: _obscurePassword,
          error: _passwordError,
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
        ),
        const SizedBox(height: 20),

        // ── Konfirmasi password ──
        _buildLabel('Konfirmasi Kata Sandi'),
        const SizedBox(height: 6),
        _buildPasswordField(
          controller: _confirmController,
          hint: 'Ulangi kata sandi baru',
          obscure: _obscureConfirm,
          error: _confirmError,
          onToggle: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
        ),
        const SizedBox(height: 8),

        // Info aturan password
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Text(
              'Min. 8 karakter, mengandung huruf dan angka.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Tombol submit ──
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Perbarui Kata Sandi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required String? error,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Icon(Icons.lock_rounded, size: 22, color: Color(0xFF9CA3AF)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              obscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 22,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 48),
        errorText: error,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
