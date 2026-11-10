import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_services.dart';
import 'widgets/captcha_dialog.dart';
import 'widgets/captcha_verification_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthServices _authServices = AuthServices();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false; // State sukses — tampilkan info panel
  String? _emailError;
  String? _captchaToken;
  bool _isCaptchaLoading = false;

  Future<void> _openCaptchaModal() async {
    setState(() => _isCaptchaLoading = true);
    final token = await CaptchaDialog.show(context);
    if (!mounted) return;
    setState(() {
      _isCaptchaLoading = false;
      if (token != null && token.isNotEmpty) {
        _captchaToken = token;
      }
    });
  }

  static const _primary = Color(0xFF20603D);
  static const _bg = Color(0xFFF8FFFA);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty) {
      setState(() => _emailError = 'Email wajib diisi.');
      return false;
    }
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Format email tidak valid.');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validateEmail()) return;

    if (_captchaToken == null) {
      _showErrorSnackBar("Verifikasi reCAPTCHA wajib dicentang.");
      await _openCaptchaModal();
      if (_captchaToken == null) return;
    }

    setState(() => _isLoading = true);

    final currentCaptcha = _captchaToken;
    final result = await _authServices.forgotPassword(
      _emailController.text.trim(),
      captchaToken: currentCaptcha,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      // Reset captcha token setelah dipakai (one-time use)
      _captchaToken = null;
    });

    if (result['success'] == true) {
      setState(() => _submitted = true);
    } else if (result['fieldErrors'] != null) {
      final errors = result['fieldErrors'] as Map<String, dynamic>;
      setState(() {
        _emailError = (errors['email'] as List?)?.first as String?;
      });
    } else {
      _showErrorSnackBar(result['message'] ?? 'Terjadi kesalahan pada server.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Dekorasi lingkaran background
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
                  _submitted ? _buildSuccessState() : _buildForm(),
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
        // Ikon & judul
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_rounded, size: 28, color: _primary),
        ),
        const SizedBox(height: 20),
        Text(
          'Lupa Kata Sandi?',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan email terdaftar. Kami kirim tautan reset ke inbox Anda.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Label & input email
        Text(
          'Alamat Email',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: 'name@example.com',
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF9CA3AF),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.email_rounded,
                size: 22,
                color: Color(0xFF9CA3AF),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            errorText: _emailError,
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
        CaptchaVerificationButton(
          isVerified: _captchaToken != null,
          isLoading: _isCaptchaLoading,
          onTap: _openCaptchaModal,
        ),
        const SizedBox(height: 28),

        // Tombol kirim
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
                    'Kirim Tautan Reset',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Link kembali login
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Kembali ke Login',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Ikon sukses
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: _primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Email Terkirim!',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kami telah mengirimkan instruksi reset kata sandi ke email Anda. '
          'Silakan periksa kotak masuk atau folder spam.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF6B7280),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE047)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF854D0E),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tautan berlaku selama 1 jam. Jangan bagikan tautan tersebut ke siapapun.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF854D0E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Kembali ke Login',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Kirim ulang
        GestureDetector(
          onTap: () => setState(() {
            _submitted = false;
            _emailController.clear();
          }),
          child: Text(
            'Belum menerima? Kirim ulang',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
